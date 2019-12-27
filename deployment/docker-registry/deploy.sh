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

# ------------------------------------------------------------
source ../shared.sh

# Stop immediately if any of the deployments fail
trap errorHandler ERR


# ------------------------------------------------------------
echoSection "Validating parameters"

paramValidation "REGISTRY_ADMIN_PASSWORD" \
   "the password of the 'admin' user of the registry"

checkAppName "registry"

checkStorageClass "registry"

checkFQN "registry"

checkCertificate "registry"


# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "registry"

# ------------------------------------------------------------
echoSection "Preparing chart values"

processTemplate chart-values.yaml


docker run --rm -ti xmartlabs/htpasswd admin ${REGISTRY_ADMIN_PASSWORD} > ${TMP_DIR}/htpasswd

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace docker-registry

# ------------------------------------------------------------
echoSection "Installing Docker-Registry (without ingress)"

helm install stable/docker-registry \
    --name docker-registry \
    --namespace docker-registry \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml \
    --set secrets.htpasswd="$(cat ${TMP_DIR}/htpasswd)"

# ------------------------------------------------------------

if [[ "${REGISTRY_CERT_NEEDED}" == "Y" ]]
then

    echoSection "Installing the cert-manager certificate for Docker-Registry"

    applyTemplate certificate.yaml
fi

# ------------------------------------------------------------
echoSection "Installing the Ingress for Docker-Registry (with TLS by cert-manager)"


applyTemplate ingress.yaml


# ------------------------------------------------------------
echoSection "Docker-registry has been installed on your cluster"


