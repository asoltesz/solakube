#!/usr/bin/env bash

#
# Deploy a component with a SolaKube deployer
#
# 1 - The component to deploy (e.g: "rook-ceph")
#

DEPLOY_COMPONENT=$1

if [[ ! "${DEPLOY_COMPONENT}" ]]
then
    echo "ERROR: Deployment component not specified. Aborting."
    exit 1
fi

OPERATION=$2

if [[ ! "${OPERATION}" ]]
then
    OPERATION="deploy"
fi


# Loading the deployment support shared library
. ${SK_SCRIPT_HOME}/deploy/deploy-shared.sh

# Deploy script storage folder
export DEPLOY_SCRIPTS_DIR=${SK_SCRIPT_HOME}/deploy/${DEPLOY_COMPONENT}

# Deployment descriptor storage folder
export DEPLOYMENT_DIR=${SK_DEPLOYMENT_HOME}/${DEPLOY_COMPONENT}

# Stepping into the deployment descriptor folder of the component for
# simple KubeCtl executions
if [[ -d "${DEPLOYMENT_DIR}" ]]
then
    cd "${DEPLOYMENT_DIR}"
fi

# Executing the deployer
. ${DEPLOY_SCRIPTS_DIR}/${OPERATION}.sh

