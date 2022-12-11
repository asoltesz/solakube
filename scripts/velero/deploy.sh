#!/usr/bin/env bash

# ==============================================================================
#
# Install Velero on your cluster
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of Velero
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# 1 - Installation mode
#     - install: (Default)
#           Normal installation.
#           Velero and the infrastructure backup schedules will be installed
#     - recovery:
#           Only Velero will be installed
#     - upgrade:
#           Velero will be upgraded with Helm
# ==============================================================================

OPERATION=${1:-"install"}

# Stop immediately if any of the deployments fail
trap errorHandler ERR

# Internal parameters

export VELERO_VERSION="1.4.3"
export VELERO_AWS_PLUGIN_VERSION="1.1.0"
HELM_CHART_VERSION="2.12.17"

echoHeader "Deploying the Velero Backup/Restore Operator"
echo "Version: ${VELERO_VERSION}"
echo "Deployment operation mode: ${OPERATION}"

# ------------------------------------------------------------
echoSection "Validating parameters"

if [[ -z $(echo ",install,upgrade,recovery," | grep ",${OPERATION},") ]]
then
    echo "FATAL: Unsupported script operation mode: ${OPERATION}"
    exit 1
fi

cexport VELERO_SNAPSHOTS_ENABLED "false"

checkAppName "velero"

checkStorageClass "velero"

checkFQN "velero"

checkCertificate "velero"

# Ensuring the S3 parameters

# Calculating the S3 access parameters if they are not defined
if [[ ! "${VELERO_S3_ENDPOINT}" ]]
then
    # Fetching the B2 or default S3 settings
    defineS3AccessParams "VELERO_S3"
fi

if [[ ! "${VELERO_S3_ENDPOINT}" ]]
then
    echo "ERROR: It was not possible to find S3 access params/defaults for Velero"
    return 1
fi

if [[ ! "${VELERO_S3_BUCKET_NAME}" ]]
then
    echo "ERROR: Please, provide S3 bucket name in VELERO_S3_BUCKET_NAME"
    return 1
fi


# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "velero"

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${VELERO_APP_NAME}


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

echo "Adding/Updating Helm chart repo"

helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts

echo "Deploying Velero to the cluster with Helm"

helm upgrade ${VELERO_APP_NAME} vmware-tanzu/velero \
    --install \
    --namespace ${VELERO_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml

# Velero must be ready when deploying backup schedules from apps
waitAllPodsActive ${VELERO_APP_NAME}

# ------------------------------------------------------------

if [[ ${OPERATION} == "install" ]]
then
    DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile ${VELERO_APP_NAME})"

    if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
    then
        echoSection "Scheduling the infrastructure backup profiles"

        . ${DEPLOY_SCRIPTS_DIR}/velero-shared.sh

        . ${DEPLOY_SCRIPTS_DIR}/backup.sh schedule "velero" "schedules"
        . ${DEPLOY_SCRIPTS_DIR}/backup.sh schedule "velero" "cluster"
    else
        echo "Built-in infra backup profiles are not deployed: ${DEPLOY_BCK_PROFILE}"
    fi
fi

# ------------------------------------------------------------
echoSection "Velero has been installed on your cluster"

