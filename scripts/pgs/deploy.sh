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

HELM_CHART_VERSION=10.2.0
POSTGRES_VERSION=11.10.0

# Source the PGS shared library
. ${SK_SCRIPT_HOME}/pgs/pgs-shared.sh

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying PostgreSQL (postgres) on your cluster"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "pgs"

checkStorageClass "pgs"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "pgs"

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml


# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${PGS_APP_NAME}

# ------------------------------------------------------------
echoSection "Creating PVC"

applyTemplate pvc.yaml


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm install ${PGS_APP_NAME} bitnami/postgresql \
    --namespace ${PGS_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml \
    --set postgresqlPassword=${PGS_ADMIN_PASSWORD}

# ------------------------------------------------------------

# We need to wait for pgInit before an application could start use PG
echo "Waiting for the Postgres installation to finish"

# Application deployers MUST find PGS ready when they execute and want to
# create their own application databases
waitAllPodsActive ${PGS_APP_NAME}


# ------------------------------------------------------------
echoSection "Postgres ${POSTGRES_VERSION} has been installed on your cluster"

