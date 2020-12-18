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
# 1 - Operation type of the deployment. Possible values:
#     - install (default):
#           install pgadmin
#     - update
#           update pgadmin to a newer version
#           no backup schedules will be installed
# ==============================================================================

# Internal parameters

HELM_CHART_VERSION=1.0.4

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying the pgAdmin DB administration tool "

OPERATION=${1:-"install"}

echo "Operation to be executed: ${OPERATION}"

# ------------------------------------------------------------
echoSection "Validating parameters"

if [[ -z $(echo ",install,update," | grep ",${OPERATION},") ]]
then
    echo "FATAL: Unsupported script operation mode: ${OPERATION}"
    exit 1
fi


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

helm upgrade ${PGADMIN_APP_NAME} stable/pgadmin \
    --install \
    --namespace ${PGADMIN_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml


# ------------------------------------------------------------
echoSection "Patching the deployment for Velero/Restic annotations"
# This is also needed for manual backups (non-scheduled)

sleep 5

waitAllPodsActive ${PGADMIN_APP_NAME}

echo

kubectl patch deployment ${PGADMIN_APP_NAME} \
  --patch "$(cat velero-deployment-patch.yaml)" \
  -n ${PGADMIN_APP_NAME}

echo

# ------------------------------------------------------------

if [[ "${PGADMIN_CERT_NEEDED}" == "Y" ]]
then
    echoSection "Installing a dedicated TLS certificate-request"

    applyTemplate certificate.yaml
else
    # A cluster-level, wildcard cert needs to be replicated into the namespace
    if [[ "${CLUSTER_CERT_SECRET_NAME}" ]]
    then
        deleteKubeObject "secret" "cluster-fqn-tls" "${PGADMIN_APP_NAME}"
        applyTemplate cluster-fqn-tls-secret.yaml
    fi
fi

# ------------------------------------------------------------
echoSection "Installing the Ingress (with TLS by cert-manager)"

applyTemplate ingress.yaml


# ------------------------------------------------------------

if [[ "${OPERATION}" == "install" ]]
then
    echoSection "Deploying backup schedule"

    DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile ${PGADMIN_APP_NAME})"

    if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
    then
        . ${DEPLOY_SCRIPTS_DIR}/backup-config.sh
    else
        echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
    fi
fi


# ------------------------------------------------------------
echoSection "PgAdmin has been installed on your cluster"
