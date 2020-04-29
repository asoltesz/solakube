#!/usr/bin/env bash

#
# Undeploy a component with a SolaKube deployer
#
# 1 - The component to deploy (e.g: "rook-ceph")
#

DEPLOY_COMPONENT=$1

if [[ ! "${DEPLOY_COMPONENT}" ]]
then
    echo "ERROR: Deployment component not specified. Aborting."
    exit 1
fi

shift

OPERATION=$1

if [[ ! "${OPERATION}" ]]
then
    OPERATION="undeploy"
else
    shift
fi

# Loading the deployment support shared library
. ${SK_SCRIPT_HOME}/deploy/deploy-shared.sh

# Deploy script storage folder
export DEPLOY_SCRIPTS_DIR=${SK_SCRIPT_HOME}/deploy/${DEPLOY_COMPONENT}

# Deploy script storage folder
if [[ ! -d "${DEPLOY_SCRIPTS_DIR}" ]]
then
    echo "No deploy script for deployer '${DEPLOY_COMPONENT}'"
    exit 1
fi

# Deployment descriptor storage folder
export DEPLOYMENT_DIR=${SK_DEPLOYMENT_HOME}/${DEPLOY_COMPONENT}

# Stepping into the deployment descriptor folder of the component for
# simple KubeCtl executions
if [[ -d "${DEPLOYMENT_DIR}" ]]
then
    cd "${DEPLOYMENT_DIR}"
fi

# Executing the undeployer
. ${DEPLOY_SCRIPTS_DIR}/${OPERATION}.sh $@



