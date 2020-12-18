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

export NEXTCLOUD_VERSION="20.0.1"
HELM_CHART_VERSION=1.9.3

# Stop immediately if any of the deployments fail
trap errorHandler ERR

checkAppName "nextcloud"

echoHeader "Deploying the NextCloud Groupware Server (${NEXTCLOUD_APP_NAME})"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkStorageClass "nextcloud"

checkFQN "nextcloud" "${NEXTCLOUD_APP_NAME}"

checkCertificate "nextcloud"

# Defaulting to 10 GB PVC size, if not set
cexport NEXTCLOUD_PVC_SIZE "10Gi"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "nextcloud"

# ------------------------------------------------------------
echoSection "Creating the Postgres database for NextCloud"

createPgApplicationDatabase ${NEXTCLOUD_APP_NAME} ${NEXTCLOUD_DB_PASSWORD}

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${NEXTCLOUD_APP_NAME}

# ------------------------------------------------------------
echoSection "Creating PVC"

applyTemplate pvc.yaml


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm install ${NEXTCLOUD_APP_NAME} stable/nextcloud \
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
echoSection "Patching Nextcloud server config to allow client authorizatin"

echo "Waiting for all objects to register with the API"
sleep 5

echo "Waiting for all pods to become Ready"
waitAllPodsActive ${NEXTCLOUD_APP_NAME} 600 5

echo
echo "Patching the NextCloud config for HTTPS"
echo

# Without this, Nextcloud clients cannot authenticate for synchronization

echo "sed -i \"s/);/\\\\'overwriteprotocol\\\\' => \\\\'https\\\\', );/g\" config/config.php" > /tmp/cmd.sh
chmod +x /tmp/cmd.sh
copyFileToPod "app.kubernetes.io/name=nextcloud" "${NEXTCLOUD_APP_NAME}" /tmp/cmd.sh /tmp/cmd.sh

# Executing the uploaded command script
execInPod "app.kubernetes.io/name=nextcloud" "${NEXTCLOUD_APP_NAME}" "bash /tmp/cmd.sh"

echo "Patching done"
echo "Waiting for 60s for NextCloud to reload configuration"
sleep 60
echo "Now, you should be able to connect to Nextcloud with the official clients as well."

# ------------------------------------------------------------
echoSection "Deploying backup schedule"

DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile ${NEXTCLOUD_APP_NAME})"

if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
then
    . ${DEPLOY_SCRIPTS_DIR}/backup-config.sh
else
    echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
fi

# ------------------------------------------------------------
echoSection "NextCloud has been installed on your cluster"
