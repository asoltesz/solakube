#!/usr/bin/env bash

# ==============================================================================
#
# Installs the CrunchyData Postgres Operator and then deploys a preconfigured
# Postgres Database cluster.
#
# 1 - Operation type of the deployment. Possible values:
#     - install (default)
#         Install PGO to the K8s cluster.
#         Backup schedules are automatically installed if possible.
#     - update
#         update existing install to a newer PGO version
#     - recovery
#         used when re-installing in recovery mode.
#         Backup schedules should NOT be installed
#
# ==============================================================================

# Source the PGO shared library
. ${SK_SCRIPT_HOME}/pgo/pgo-shared.sh

# Stop immediately if any of the deployments fail
trap errorHandler ERR

# Internal parameters

export PGO_VERSION="4.5.1"

OPERATION=${1:-"install"}

echo "Operation to be executed: ${OPERATION}"

# ------------------------------------------------------------


echoHeader "${OPERATION}ing CrunchyData Postgres Operator on your cluster"

echo "PGO version: ${PGO_VERSION}"

# ------------------------------------------------------------
echoSection "Validating parameters"

if [[ -z $(echo ",install,update,recovery," | grep ",${OPERATION},") ]]
then
    echo "FATAL: Unsupported script operation mode: ${OPERATION}"
    exit 1
fi

paramValidation SK_CLUSTER "The name of your cluster (e.g.: 'andromeda')"

checkAppName "pgo"

checkPgoStorageClasses


# If S3 backups are needed for pgBackRest
if [[ ${PGO_CLUSTER_S3_BUCKET} ]]
then
    # Calculating the S3 access parameters if they are not defined
    if [[ ! "${PGO_CLUSTER_S3_ENDPOINT}" ]]
    then
        # Fetching the B2 or default S3 settings
        defineS3AccessParams "PGO_CLUSTER_S3"
    fi

    if [[ ! "${PGO_CLUSTER_S3_ENDPOINT}" ]]
    then
        echo "ERROR: It was not possible to find S3 access defaults for PGO Backrest"
        return 1
    fi
fi



# checkFQN "pgo"

# checkCertificate "pgo"


# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "pgo"



# ------------------------------------------------------------
#echoSection "Creating namespace"
defineNamespace "pgo"


# ------------------------------------------------------------

if [[ "${OPERATION}" == "install" ]] || [[ "${OPERATION}" == "recovery" ]]
then
    echoSection "Preparing the Operator Configuration file"

    processTemplate "config.yaml"

    deleteKubeObject "configmap" "pgo-deployer-cm" "pgo"

    kubectl create configmap pgo-deployer-cm \
      --from-file="values.yaml=${TMP_DIR}/config.yaml" \
      --namespace="pgo"
fi

applyTemplate "postgres-operator.yml"

# ------------------------------------------------------------
echoSection "Installing the operator with Kubectl"

# Avoid error when there is no pod in the namespace at all
sleep 30
waitSinglePodActive pgo pgo-client

# Patching the PGO client environment so that all PGO commands execute
# in this namespace
kubectl set env deployment/pgo-client \
    PGO_NAMESPACE=pgo \
    --namespace="pgo"

# ------------------------------------------------------------
echoSection "Waiting for the PGO client installation to stabilize"

# Waitin for the patch to take effect
sleep 5
waitSinglePodActive pgo pgo-client

# Waiting for the non-patched pgo-client pod to be removed
sleep 15

# ------------------------------------------------------------

# Deploying the DB cluster if not specifically disallowed

if [[ "${OPERATION}" == "install" ]] && [[ "${PGO_CREATE_DEFAULT_CLUSTER:-Y}" == "Y" ]]
then
    echoSection "Creating the 'default' Postgres DB cluster"

    ${SK_SCRIPT_HOME}/sk pgo create-cluster "default"

fi

# ------------------------------------------------------------
# echoSection "Deploying backup schedule"

if [[ "${OPERATION}" == "install" ]]
then
    echoSection "Deploying backup schedule"

    DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile ${PGO_APP_NAME})"

    if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
    then
        . ${DEPLOY_SCRIPTS_DIR}/backup-config.sh
    else
        echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
    fi
fi

# ------------------------------------------------------------
echoSection "CrunchyData Postgres Operator has been ${OPERATION}ed on your cluster"

