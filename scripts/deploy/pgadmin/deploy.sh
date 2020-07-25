#!/usr/bin/env bash

# ==============================================================================
#
# Install pgAdmin on your cluster
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of pgAdmin
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

HELM_CHART_VERSION=1.0.4

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying the pgAdmin DB administration tool "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "pgadmin"

checkStorageClass "pgadmin"

checkFQN "pgadmin"

checkCertificate "pgadmin"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "pgadmin"

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml


# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${PGADMIN_APP_NAME}

# ------------------------------------------------------------
echoSection "Creating PVC"

applyTemplate pvc.yaml


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm install ${PGADMIN_APP_NAME} stable/pgadmin \
    --namespace ${PGADMIN_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml

# ------------------------------------------------------------

if [[ "${PGADMIN_CERT_NEEDED}" == "Y" ]]
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
echoSection "PgAdmin has been installed on your cluster"


DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile ${PGADMIN_APP_NAME})"

if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
then
    . ${DEPLOY_SCRIPTS_DIR}/backup-config.sh
else
    echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
fi

