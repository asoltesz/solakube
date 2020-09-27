#!/usr/bin/env bash

# ==============================================================================
#
# Installs the OpenLDAP on the cluster.
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

HELM_CHART_VERSION="1.2.4"
OPENLDAP_VERSION="2.4.48"

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Installing OpenLDAP on your cluster"


# ------------------------------------------------------------
echoSection "Validating parameters"

cexport OPENLDAP_PVC_SIZE "1Gi"

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

helm install ${OPENLDAP_APP_NAME} stable/openldap \
    --namespace=${OPENLDAP_APP_NAME} \
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

echo "Waiting for the installation to stabilize"
waitAllPodsActive openldap 600 5

# ------------------------------------------------------------
echoSection "OpenLDAP has been installed on your cluster"


DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile ${OPENLDAP_APP_NAME})"

if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
then
    . ${DEPLOY_SCRIPTS_DIR}/backup-config.sh
else
    echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
fi
