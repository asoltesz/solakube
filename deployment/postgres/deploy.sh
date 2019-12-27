#!/usr/bin/env bash

# ==============================================================================
#
# Install PostgreSQL on your cluster (Bitnami variant)
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of postgres
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

HELM_CHART_VERSION=8.1.2
POSTGRES_VERSION=11.6.0

# ------------------------------------------------------------
source ../shared.sh

# Stop immediately if any of the deployments fail
trap errorHandler ERR


# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "postgres"

checkStorageClass "postgres"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "postgres"

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml


# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${POSTGRES_APP_NAME}

# ------------------------------------------------------------
echoSection "Creating PVC"

applyTemplate pvc.yaml


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm install stable/postgresql \
    --name ${POSTGRES_APP_NAME} \
    --namespace ${POSTGRES_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml \
    --set postgresqlPassword=${POSTGRES_ADMIN_PASSWORD}

# ------------------------------------------------------------


# ------------------------------------------------------------
echoSection "Postgres ${POSTGRES_VERSION} has been installed on your cluster"

