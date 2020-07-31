#!/usr/bin/env bash

# ==============================================================================
#
# Install JFrog Container Registry on your cluster
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of jCR
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

# JCR version: 7.6.2
HELM_CHART_VERSION=2.5.0

# Stop immediately if any of the deployments fail
trap errorHandler ERR

checkAppName "jcr"

echoHeader "Deploying JFrog Container Registry (${JCR_APP_NAME})"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkStorageClass "jcr"

checkFQN "jcr" "${JCR_APP_NAME}"

checkCertificate "jcr"

# Defaulting to 3 GB PVC size, if not set
cexport JCR_PVC_SIZE "3Gi"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "jcr"

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml

# ------------------------------------------------------------
echoSection "Creating the Postgres database for JCR"

processTemplate create-pg-database.sql

executePostgresAdminScript ${TMP_DIR}/create-pg-database.sql ${POSTGRES_NAMESPACE} ${POSTGRES_SERVICE_HOST}

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${JCR_APP_NAME}

# ------------------------------------------------------------
echoSection "Creating PVC"

applyTemplate pvc.yaml


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm repo add center https://repo.chartcenter.io

helm install ${JCR_APP_NAME} center/jfrog/artifactory-jcr \
    --namespace=${JCR_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values=${TMP_DIR}/chart-values.yaml


# ------------------------------------------------------------

# Stepping back to the deployment folder

cd "${DEPLOYMENT_DIR}"

if [[ "${JCR_CERT_NEEDED}" == "Y" ]]
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
echoSection "JFrog Container Registry has been installed on your cluster"

DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile ${JCR_APP_NAME})"

if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
then
    . ${DEPLOY_SCRIPTS_DIR}/backup-config.sh
else
    echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
fi
