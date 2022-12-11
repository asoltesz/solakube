#!/usr/bin/env bash

# ==============================================================================
#
# Install CODE Document Server on your cluster
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of cODE
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters
export HELM_CHART_VERSION="1.0.8"

cexport CODE_VERSION "6.4.10.3"

APP_TITLE="Collabora CODE Document Server"

# Stop immediately if any of the deployments fail
trap errorHandler ERR

checkAppName "code"

echoHeader "Deploying the ${APP_TITLE} (${CODE_APP_NAME})"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkStorageClass "code"

checkFQN "code" "${CODE_APP_NAME}"

checkCertificate "code"

# The version of the Collabora Online Office Server (docker image)
cexport CODE_VERSION "6.4.0.14"

cexport CODE_DICTIONARIES "en hu"

cexport CODE_ADMIN_USERNAME "admin"
cexport CODE_ADMIN_PASSWORD "${SK_ADMIN_PASSWORD}"

cexport CODE_DOMAIN "nextcloud.${CLUSTER_FQN}"

cexport CODE_SERVER "${CODE_APP_NAME}.${CLUSTER_FQN}"

# Composing the extra parameters
cexport CODE_EXTRA_PARAMS "--o:ssl.enable=false --o:ssl.termination=true"


# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "code"

# ------------------------------------------------------------
echoSection "Preparing deployment descriptors"


# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace "${CODE_APP_NAME}"



# ------------------------------------------------------------
echoSection "Installing application with deployment templates"

applyTemplate deployment.yaml
applyTemplate service.yaml


# ------------------------------------------------------------

if [[ "${CODE_CERT_NEEDED}" == "Y" ]]
then
    echoSection "Installing a dedicated TLS certificate-request"

    applyTemplate certificate.yaml
else
    # A cluster-level, wildcard cert needs to be replicated into the namespace
    if [[ "${CLUSTER_CERT_SECRET_NAME}" ]]
    then
        deleteKubeObject "secret" "cluster-fqn-tls" "${CODE_APP_NAME}"
        applyTemplate cluster-fqn-tls-secret.yaml
    fi
fi

# ------------------------------------------------------------
echoSection "Installing the Ingress (with TLS by cert-manager)"

applyTemplate ingress.yaml
