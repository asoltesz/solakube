#!/usr/bin/env bash

# ==============================================================================
#
# Install Gitea on your cluster
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of gITEA
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

# Gitea version: 1.12.2
HELM_CHART_VERSION=0.2.2

# Stop immediately if any of the deployments fail
trap errorHandler ERR

checkAppName "gitea"

echoHeader "Deploying the Gitea Development Server (${GITEA_APP_NAME})"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkStorageClass "gitea"

checkFQN "gitea" "${GITEA_APP_NAME}"

checkCertificate "gitea"

# Defaulting to 3 GB PVC size, if not set
cexport GITEA_PVC_SIZE "3Gi"

cexport GITEA_ADMIN_USERNAME "gitea"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "gitea"

# ------------------------------------------------------------
echoSection "Creating the Postgres database for Gitea"

createPgApplicationDatabase ${GITEA_APP_NAME} ${GITEA_DB_PASSWORD}

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${GITEA_APP_NAME}

# ------------------------------------------------------------
echoSection "Creating PVC"

applyTemplate pvc.yaml

# ------------------------------------------------------------
echoSection "Downloading patched Helm chart"

# Currently, we have to use a manually patched version of the Helm chart
# in order to be able to place the Velero backup annotation at Helm deploy time
#
# We can revert back to the official chart when this PR is merged and
# distributed:
# https://github.com/jfelten/gitea-helm-chart/pull/67
#
# Official chart that was patched:
# helm repo add keyporttech https://keyporttech.github.io/helm-charts
#

if [[ ! -d "${TMP_DIR}/helm-chart" ]]
then
    git clone https://github.com/asoltesz/gitea-helm-chart.git ${TMP_DIR}/helm-chart
else
    echo "Helm chart already present in /tmp"
fi

cd ${TMP_DIR}/helm-chart
git reset --hard
git fetch
git checkout "0.2.2-podAnnotation"

# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm upgrade ${GITEA_APP_NAME} \
    . \
    --install \
    --namespace=${GITEA_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values=${TMP_DIR}/chart-values.yaml \

waitAllPodsActive ${GITEA_APP_NAME}

# ------------------------------------------------------------

# Stepping back to the deployment folder

cd "${DEPLOYMENT_DIR}"

if [[ "${GITEA_CERT_NEEDED}" == "Y" ]]
then
    echoSection "Installing a dedicated TLS certificate-request"

    applyTemplate certificate.yaml
else
    # A cluster-level, wildcard cert needs to be replicated into the namespace
    if [[ "${CLUSTER_CERT_SECRET_NAME}" ]]
    then
        applyTemplate cluster-fqn-tls-secret.yaml
    fi
fi

# ------------------------------------------------------------
echoSection "Installing the Ingress (with TLS by cert-manager)"

applyTemplate ingress.yaml


# ------------------------------------------------------------
echoSection "Creating the 'gitea' Admin user"

echo "start waiting...................................................................................................................."

waitAllPodsActive ${GITEA_APP_NAME}

echo "execInPod...................................................................................................................."

execInPod "app=${GITEA_APP_NAME}-gitea" ${GITEA_APP_NAME} \
  "su-exec git gitea admin create-user --name=${GITEA_ADMIN_USERNAME} --password=${GITEA_ADMIN_PASSWORD} --email=${GITEA_ADMIN_EMAIL} --admin --must-change-password=false"

# ------------------------------------------------------------
echoSection "Gitea has been installed on your cluster"

DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile ${GITEA_APP_NAME})"

if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
then
    . ${DEPLOY_SCRIPTS_DIR}/backup-config.sh
else
    echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
fi
