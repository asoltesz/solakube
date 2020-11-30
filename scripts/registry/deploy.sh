#!/usr/bin/env bash

# ==============================================================================
# Installs a Docker Registry into the cluster (with Helm).
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

HELM_CHART_VERSION=1.8.3


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Installing Docker Registry on your cluster"

# ------------------------------------------------------------
echoSection "Validating parameters"

paramValidation "REGISTRY_ADMIN_PASSWORD" \
   "the password of the 'admin' user of the registry"

cexport REGISTRY_STORAGE_CLASS "${DEFAULT_STORAGE_CLASS}"

checkAppName "registry"

checkStorageClass "registry"

checkFQN "registry"

checkCertificate "registry"

# The registry is typically larger because all images on the cluster
# should be stored in it
cexport REGISTRY_PVC_SIZE "10Gi"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "registry"

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace registry

# ------------------------------------------------------------
echoSection "Deploying reg-tool"

applyTemplate reg-tool.yaml

# ------------------------------------------------------------
echoSection "Preparing chart values"

processTemplate chart-values.yaml

docker run --rm -ti xmartlabs/htpasswd admin ${REGISTRY_ADMIN_PASSWORD} > ${TMP_DIR}/htpasswd

# ------------------------------------------------------------
echoSection "Installing Docker-Registry (without ingress)"

helm upgrade ${REGISTRY_APP_NAME} stable/docker-registry \
    --install \
    --namespace ${REGISTRY_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml \
    --set secrets.htpasswd="$(cat ${TMP_DIR}/htpasswd)"

# ------------------------------------------------------------

if [[ "${REGISTRY_CERT_NEEDED}" == "Y" ]]
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
echoSection "Installing the Ingress for Docker-Registry (with TLS by cert-manager)"


applyTemplate ingress.yaml

# ------------------------------------------------------------
echoSection "Docker-registry has been installed on your cluster"


DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile ${REGISTRY_APP_NAME})"

if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
then
    . ${DEPLOY_SCRIPTS_DIR}/backup-config.sh
else
    echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
fi
