#!/usr/bin/env bash

#
# Deploy a component with a SolaKube deployer
#
# 1 - The component to deploy (e.g: "rook-ceph")
# ... - parameters intended to the un-deployer script

DEPLOY_COMPONENT=$1

if [[ ! "${DEPLOY_COMPONENT}" ]]
then
    echo "ERROR: Deployment component not specified. Aborting."
    exit 1
fi

shift

# Loading the deployment support shared library
. ${SK_SCRIPT_HOME}/deploy/deploy-shared.sh

# Loading the Postgres shared library since many application deployments
# need to create a database for themselves
. ${SK_SCRIPT_HOME}/postgres/postgres-shared.sh

# Deployments may need private registry access
. ${SK_SCRIPT_HOME}/registry/registry-shared.sh


# Deploy script storage folder
export DEPLOY_SCRIPTS_DIR=$(resolvePathOnRoots "scripts/${DEPLOY_COMPONENT}")
# Deploy script storage folder
if [[ ! -d "${DEPLOY_SCRIPTS_DIR}" ]]
then
    echo "ERROR: No deploy script for deployer '${DEPLOY_COMPONENT}'"
    exit 1
fi

# Deployment descriptor storage folder for this specific deployment
export DEPLOYMENT_DIR=$(resolvePathOnRoots "deployment/${DEPLOY_COMPONENT}")

# Stepping into the deployment descriptor folder of the component for
# simple KubeCtl executions
if [[ -d "${DEPLOYMENT_DIR}" ]]
then
    cd "${DEPLOYMENT_DIR}"
fi

# Executing the deployer
. ${DEPLOY_SCRIPTS_DIR}/deploy.sh $@

