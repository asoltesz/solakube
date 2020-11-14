#!/usr/bin/env bash

# ==============================================================================
#
# Install Mailu email services on your cluster
#
# ==============================================================================

# Internal parameters

# Mailu version: master (1.8-DEVELOP)
HELM_CHART_VERSION=0.0.7

export MAILU_VERSION="master"

# Stop immediately if any of the deployments fail
trap errorHandler ERR

checkAppName "mailu"

echoHeader "Deploying the Mailu Email Services (${MAILU_APP_NAME})"

# ------------------------------------------------------------
echoSection "Validating parameters"

if [[ -z "${MAILU_ADMIN_PASSWORD}" ]]
then
    echo "ERROR: Mailu admin password not set: MAILU_ADMIN_PASSWORD"
     exit 1
fi




checkStorageClass "mailu"

checkFQN "mailu" "${MAILU_APP_NAME}"

checkCertificate "mailu"

# If the mail domain is not defined, we define the cluster itself
cexport MAILU_DOMAIN "${CLUSTER_FQN}"

# If the mail domain hostnames are not defined, we define it using the app name and the Cluster FQN
cexport MAILU_HOSTNAMES "[ '${MAILU_FQN}' ]"


# Defaulting to 10 GB PVC size, if not set
# If only used for mail forwarding (no IMAP storage, no ClamAV...etc),
# a small, 3-5 GB PVC may be suitable
cexport MAILU_PVC_SIZE "3Gi"

cexport MAILU_DOVECOT_ENABLED   "false"
cexport MAILU_CLAMAV_ENABLED    "false"
cexport MAILU_ROUNDCUBE_ENABLED "false"
cexport MAILU_WEBDAV_ENABLED    "false"

# By default, we will use SolaKube/Cert-Manager -managed certs
cexport MAILU_TLS_FLAVOR "cert"

IFS='@' read -ra MAILU_ADMIN_EMAIL_PARTS <<< "${MAILU_ADMIN_EMAIL}"
export MAILU_ADMIN_EMAIL_USERNAME="${MAILU_ADMIN_EMAIL_PARTS[0]}"
export MAILU_ADMIN_EMAIL_DOMAIN="${MAILU_ADMIN_EMAIL_PARTS[1]}"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "mailu"

# ------------------------------------------------------------
echoSection "Creating the Postgres database for Mailu"

createPgApplicationDatabase ${MAILU_APP_NAME} ${MAILU_DB_PASSWORD}

if [[ ${MAILU_ROUNDCUBE_ENABLED} == "true" ]]
then
    createPgApplicationDatabase "${MAILU_APP_NAME}_roundcube" ${MAILU_DB_PASSWORD}
fi

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${MAILU_APP_NAME}


# ------------------------------------------------------------
echoSection "Creating PVC"

applyTemplate pvc.yaml

# ------------------------------------------------------------
echoSection "Obtaining the Helm chart"

# Currently, we have to use a manually patched version of the Helm chart
# in order to be able to place the Velero backup annotation at Helm deploy time
# and have Postgres as the database
#
# We can revert back to the official chart when all of the PR are merged
#

if [[ -z ${MAILU_CHART_REPO_LOCAL_PATH} ]]
then
    if [[ ! -d "${TMP_DIR}/helm-chart" ]]
    then
        git clone https://github.com/asoltesz/mailu-helm-charts.git ${TMP_DIR}/helm-chart
    else
        echo "Helm chart already present in /tmp"
    fi

    cd ${TMP_DIR}/helm-chart
    git reset --hard
    git fetch
    git checkout "0.0.7-podAnnotation-and-postgres"

    MAILU_CHART_REPO_LOCAL_PATH=${TMP_DIR}/helm-chart
fi

# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm install ${MAILU_APP_NAME} ${MAILU_CHART_REPO_LOCAL_PATH}/mailu \
    --namespace ${MAILU_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml


# ------------------------------------------------------------
# Dropping the built-in Mailu ingress (cannot be cleanly disabled)
#
kubectl delete ingress/${MAILU_APP_NAME}-ingress \
    --namespace ${MAILU_APP_NAME}




# ------------------------------------------------------------
# Requesting the certificates

if [[ "${MAILU_CERT_NEEDED}" == "Y" ]]
then
    echoSection "Installing a dedicated TLS certificate-request"

    applyTemplate certificate.yaml
    # TLS secret (copy) for other, non-HTTPS parts of Mailu
    applyTemplate certificate-tls-copy.yaml
else
    # A cluster-level, wildcard cert needs to be replicated into the namespace
    if [[ "${CLUSTER_CERT_SECRET_NAME}" ]]
    then
        # TLS Secret for the ingress
        applyTemplate cluster-fqn-tls-secret.yaml
        # TLS secret for other, non-HTTPS parts of Mailu
        applyTemplate cluster-fqn-tls-secret-2.yaml
    fi
fi


# ------------------------------------------------------------
echoSection "Installing the custom Ingress (with TLS by cert-manager)"

applyTemplate ingress.yaml


# ------------------------------------------------------------
echoSection "Mailu has been installed on your cluster"

DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile ${MAILU_APP_NAME})"

if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
then
    . ${DEPLOY_SCRIPTS_DIR}/backup-config.sh
else
    echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
fi



# ------------------------------------------------------------
if [[ "${MAILU_DEPLOY_EXTERNAL_DNS}" == "true" ]]
then
    echoSection "Installing External-DNS for Mailu"

    EXTERNAL_DNS_HELM_CHART_VERSION="3.4.9"
    # EXTERNAL_DNS_VERSION="0.7.4"

    processTemplate chart-values-extdns.yaml

    helm repo add bitnami https://charts.bitnami.com/bitnami

    helm install ${MAILU_APP_NAME}-external-dns bitnami/external-dns \
        --namespace ${MAILU_APP_NAME} \
        --version=${EXTERNAL_DNS_HELM_CHART_VERSION} \
        --values ${TMP_DIR}/chart-values-extdns.yaml

    echoSection "Deploying MEDOK"

    applyTemplate medok-rbac.yaml
    applyTemplate medok-deployment.yaml


fi


# ------------------------------------------------------------

# Restarting the Mailu front pod after the certificate has been issued

if [[ "${MAILU_CERT_NEEDED}" == "Y" ]]
then
    echoSection "Checking the successful issue of the dedicated TLS certificate-request"

    checkCertificateIssued ${MAILU_APP_NAME}-tls ${MAILU_APP_NAME}
fi

# Allowing some time for Replicator to make the clones of the TLS certs
sleep 15s

# Restarting the "Front" pod deployment to allow it to pick up the newly
# requested/cloned certificates

kubectl rollout restart deployment/${MAILU_APP_NAME}-front \
    --namespace ${MAILU_APP_NAME}