#!/usr/bin/env bash

# ==============================================================================
#
# Install Stash on your cluster
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of sTASH
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

STASH_VERSION="0.9.0-rc.6"

HELM_CHART_VERSION="0.9.0-rc.6"

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying the Stash Backup/Restore Operator"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "stash"

checkStorageClass "stash"

checkFQN "stash"

checkCertificate "stash"

# Ensuring the S3 parameters

# Calculating the S3 access parameters if they are not defined
if [[ ! "${STASH_S3_ENDPOINT}" ]]
then
    # Fetching the B2 or default S3 settings
    defineS3AccessParams "STASH_S3"
fi

if [[ ! "${STASH_S3_ENDPOINT}" ]]
then
    echo "ERROR: It was not possible to find S3 access params/defaults for Stash"
    return 1
fi



# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "stash"

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${STASH_APP_NAME}


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm repo add appscode https://charts.appscode.com/stable/
helm repo update

helm install appscode/stash \
    --name ${STASH_APP_NAME} \
    --namespace ${STASH_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml

# ------------------------------------------------------------
echoSection "Stash has been installed on your cluster"

