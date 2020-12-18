#!/usr/bin/env bash

# ==============================================================================
#
# Installs a Minio in Backblaze B2 gateway mode in order to utilize
# B2 as remote storage.
#
# ==============================================================================

# Internal parameters

HELM_CHART_VERSION=5.0.21

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Installing BackBlaze B2 support on your cluster"


# ------------------------------------------------------------
echoSection "Validating parameters"

paramValidation B2_ACCESS_KEY "the access key registered for the cluster in your B2 account"
paramValidation B2_SECRET_KEY "the secret key registered for the cluster in your B2 account"

checkAppName "b2s3"

checkStorageClass "b2s3"

checkFQN "b2s3"

checkCertificate "b2s3"


# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "b2s3"


# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${B2S3_APP_NAME}

# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm install ${B2S3_APP_NAME} stable/minio \
    --namespace ${B2S3_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml

# ------------------------------------------------------------
if [[ "${B2S3_CERT_NEEDED}" == "Y" ]]
then
    echoSection "Installing the TLS certificate request"

    applyTemplate certificate.yaml
else
    # A cluster-level, wildcard cert needs to be replicated into the namespace
    if [[ "${CLUSTER_CERT_SECRET_NAME}" ]]
    then
        deleteKubeObject "secret" "cluster-fqn-tls" "${B2S3_APP_NAME}"
        applyTemplate cluster-fqn-tls-secret.yaml
    fi
fi

# ------------------------------------------------------------
echoSection "Installing the Ingress (with TLS by cert-manager)"

applyTemplate ingress.yaml

echo "Waiting for the installation to stabilize"
waitAllPodsActive b2s3 600 5

# ------------------------------------------------------------
echoSection "BackBlaze B2 support has been installed on your cluster"

