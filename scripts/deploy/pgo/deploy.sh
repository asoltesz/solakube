#!/usr/bin/env bash

# ==============================================================================
#
# Installs the CrunchyData Postgres Operator and then deploys a preconfigured
# Postgres Database cluster.
#
# 1 - Operation type of the deployment. Possible values:
#     - install (default) - install pgo to the cluster
#     - update - update existing install to a newer version
#     - uninstall - remove pgo from the cluster
#
# ==============================================================================

# Source the PGO shared library
. ${SK_SCRIPT_HOME}/pgo/pgo-shared.sh

# Stop immediately if any of the deployments fail
trap errorHandler ERR

# Internal parameters

export PGO_VERSION="4.3.2"

OPERATION=$1
if [[ ! ${OPERATION} ]]
then
    OPERATION="install"
fi

echo "Operation to be executed: ${OPERATION}"

# ------------------------------------------------------------


echoHeader "${OPERATION}ing CrunchyData Postgres Operator on your cluster"

echo "PGO version: ${PGO_VERSION}"

# ------------------------------------------------------------
echoSection "Validating parameters"

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

createTempDir "pgo" "Y"


# ------------------------------------------------------------
echoSection "Ansible inventory.ini"

# processTemplate inventory.ini

# ------------------------------------------------------------
#echoSection "Creating namespace"
#defineNamespace ${PGO_APP_NAME}


# ------------------------------------------------------------
echoSection "Preparing the inventory file"

if [[ ${PGO_CLUSTER_S3_BUCKET} ]]
then
    # S3 backups are needed for pgBackRest

    processTemplate "backrest-s3.ini"

    export PGO_BACKREST_S3_SECTION="$(cat ${TMP_DIR}/backrest-s3.ini)"
fi

processTemplate "inventory.ini"


# ------------------------------------------------------------
echoSection "Downloading and extracting the PGO Ansible role"

if [[ ! -d "${TMP_DIR}/pgo" ]]
then
    git clone https://github.com/CrunchyData/postgres-operator ${TMP_DIR}/pgo
else
    echo "Ansible role already present in /tmp"
fi

cd ${TMP_DIR}/pgo
git reset --hard
git fetch
git checkout "v${PGO_VERSION}"

# ------------------------------------------------------------
echoSection "Replacing the inventory.ini file with our own"

cd ${TMP_DIR}/pgo/installers/ansible

# Removing the default/sample inventory coming with the Git sources
rm -Rf inventory

# Copying the assembled inventory
cp ${TMP_DIR}/inventory.ini ./inventory


# ------------------------------------------------------------
echoSection "Installing the operator with Ansible"

ansible-playbook -i inventory --tags=${OPERATION} main.yml

# Patching the PGO client environment so that all PGO commands execute
# in this namespace
kubectl set env deployment/pgo-client \
    PGO_NAMESPACE=pgo \
    --namespace="pgo"

# ------------------------------------------------------------
echoSection "Waiting for the PGO installation to stabilize"
sleep 10

waitAllPodsActive pgo 600 5


# ------------------------------------------------------------

# Deploying the DB cluster if not specifically disallowed

if [[ "${OPERATION}" == "install" ]] && [[ "${PGO_CREATE_CLUSTER:-Y}" == "Y" ]]
then
    echoSection "Creating the Postgres DB cluster"

    ${SK_SCRIPT_HOME}/sk pgo create-cluster "default"

fi



# ------------------------------------------------------------
echoSection "CrunchyData Postgres Operator has been ${OPERATION}ed on your cluster"

