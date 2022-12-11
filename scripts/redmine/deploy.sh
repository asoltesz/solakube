#!/usr/bin/env bash

# ==============================================================================
#
# Install Redmine on your cluster
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of rEDMINE
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

# Redmine version: 4.1.1
HELM_CHART_VERSION=14.2.1

# Stop immediately if any of the deployments fail
trap errorHandler ERR

checkAppName "redmine"

echoHeader "Deploying Redmine Issue/Project Management (${REDMINE_APP_NAME})"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkStorageClass "redmine"

checkFQN "redmine" "${REDMINE_APP_NAME}"

checkCertificate "redmine"

# Defaulting to 3 GB PVC size, if not set
cexport REDMINE_PVC_SIZE "3Gi"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "redmine"

# ------------------------------------------------------------
echoSection "Creating the Postgres database for Redmine"

createPgApplicationDatabase ${REDMINE_APP_NAME} ${REDMINE_DB_PASSWORD}

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${REDMINE_APP_NAME}

# ------------------------------------------------------------
echoSection "Creating PVC"

applyTemplate pvc.yaml


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm repo add bitnami https://charts.bitnami.com/bitnami

helm upgrade ${REDMINE_APP_NAME} bitnami/redmine \
    --install \
    --namespace=${REDMINE_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values=${TMP_DIR}/chart-values.yaml \

waitAllPodsActive ${REDMINE_APP_NAME}

# ------------------------------------------------------------

# Stepping back to the deployment folder

cd "${DEPLOYMENT_DIR}"

ensureCertificate "${REDMINE_APP_NAME}"

# ------------------------------------------------------------
echoSection "Installing the Ingress (with TLS by cert-manager)"

applyTemplate ingress.yaml


# ------------------------------------------------------------
echoSection "Redmine has been installed on your cluster"

DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile ${REDMINE_APP_NAME})"

if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
then
    . ${DEPLOY_SCRIPTS_DIR}/backup-config.sh
else
    echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
fi
