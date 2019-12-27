#!/usr/bin/env bash

# ==============================================================================
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of oPENLDAP
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

HELM_CHART_VERSION=1.0.4

# ------------------------------------------------------------
source ../shared.sh

# Stop immediately if any of the deployments fail
trap errorHandler ERR


# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "openldap"

checkStorageClass "openldap"

checkFQN "openldap"

checkCertificate "openldap"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "openldap"


# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${OPENLDAP_APP_NAME}

# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm install stable/openldap \
    --name ${OPENLDAP_APP_NAME} \
    --namespace ${OPENLDAP_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml

# ------------------------------------------------------------
if [[ "${OPENLDAP_CERT_NEEDED}" == "Y" ]]
then
    echoSection "Installing the TLS certificate request"

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
echoSection "OPENLDAP has been installed on your cluster"

