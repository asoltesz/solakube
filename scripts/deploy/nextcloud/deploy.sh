#!/usr/bin/env bash

# ==============================================================================
#
# Install nEXTCLOUD on your cluster
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of nEXTCLOUD
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

# NextCloud version: 17.0.0
HELM_CHART_VERSION=1.9.3

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying the NextCloud Groupware Server "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "nextcloud"

checkStorageClass "nextcloud"

checkFQN "nextcloud"

checkCertificate "nextcloud"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "nextcloud"

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml

processTemplate create-pg-database.sql

# ------------------------------------------------------------
echoSection "Creating the Postgres database for NextCloud"

executePostgresAdminScript ${TMP_DIR}/create-pg-database.sql ${POSTGRES_NAMESPACE} ${POSTGRES_SERVICE_HOST}

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${NEXTCLOUD_APP_NAME}

# ------------------------------------------------------------
echoSection "Creating PVC"

applyTemplate pvc.yaml


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm install stable/nextcloud \
    --name ${NEXTCLOUD_APP_NAME} \
    --namespace ${NEXTCLOUD_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml

# ------------------------------------------------------------

if [[ "${NEXTCLOUD_CERT_NEEDED}" == "Y" ]]
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
echoSection "NextCloud has been installed on your cluster"

