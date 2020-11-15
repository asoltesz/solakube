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

cexport CODE_VERSION="6.4.0.14"

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

cexport CODE_ADMIN_PASSWORD "${SK_ADMIN_PASSWORD}"

cexport CODE_DOMAIN "${CLUSTER_FQN}"
# Escaping the domain as required by CODE docs (\\.)
export CODE_DOMAIN="${CODE_DOMAIN//"."/"\\\\."}"

cexport CODE_SERVER "${CODE_APP_NAME}.${CLUSTER_FQN}"
# Escaping the server as required by CODE docs (\\.)
export CODE_SERVER="${CODE_SERVER//"."/"\\\\."}"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "code"

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${CODE_APP_NAME}


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm install code center/stable/collabora-code \
    --namespace=${CODE_APP_NAME} \
    --values ${TMP_DIR}/chart-values.yaml \
    --version=${HELM_CHART_VERSION} \

# ------------------------------------------------------------

if [[ "${CODE_CERT_NEEDED}" == "Y" ]]
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
