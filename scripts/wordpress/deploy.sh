#!/usr/bin/env bash

# ==============================================================================
#
# Install wORDPRESS on your cluster
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of wORDPRESS
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

WORDPRESS_VERSION="5.4.1"

HELM_CHART_VERSION="9.2.2"

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying the Wordpress CMS"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "wordpress"

checkStorageClass "wordpress"

checkFQN "wordpress"

checkCertificate "wordpress"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "wordpress"

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${WORDPRESS_APP_NAME}

# ------------------------------------------------------------
echoSection "Creating PVC"

applyTemplate pvc.yaml


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm repo add bitnami https://charts.bitnami.com/bitnami

helm install ${WORDPRESS_APP_NAME} bitnami/wordpress \
    --namespace ${WORDPRESS_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml

# ------------------------------------------------------------

if [[ "${WORDPRESS_CERT_NEEDED}" == "Y" ]]
then
    echoSection "Installing a dedicated TLS certificate-request"

    applyTemplate certificate.yaml
else
    # A cluster-level, wildcard cert needs to be replicated into the namespace
    if [[ "${CLUSTER_CERT_SECRET_NAME}" ]]
    then
        deleteKubeObject "secret" "cluster-fqn-tls" "${WORDPRESS_APP_NAME}"
        applyTemplate cluster-fqn-tls-secret.yaml
    fi
fi

# ------------------------------------------------------------
echoSection "Installing the Ingress (with TLS by cert-manager)"

applyTemplate ingress.yaml



# ------------------------------------------------------------
echoSection "Wordpress has been installed on your cluster"

