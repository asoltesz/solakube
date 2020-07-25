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


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying PostgreSQL (postgres) on your cluster"

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

helm install ${POSTGRES_APP_NAME} stable/postgresql \
    --namespace ${POSTGRES_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml \
    --set postgresqlPassword=${POSTGRES_ADMIN_PASSWORD}

# ------------------------------------------------------------

# We need to wait for pgInit before an application could start use PG
echo "Waiting for the Postgres installation to finish"
sleep 45

# ------------------------------------------------------------
echoSection "Postgres ${POSTGRES_VERSION} has been installed on your cluster"

