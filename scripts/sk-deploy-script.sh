#!/usr/bin/env bash

#
# Execute a secondary deploy-script in a component (not necessarily the deploy.sh)
#
# 1 - The component to deploy (e.g: "rook-ceph")
# 2 - The name of the deploy script with extension (e.g: "backup-config.sh")
# ... - parameters intended to the deployer script
#

DEPLOY_COMPONENT=$1

if [[ ! "${DEPLOY_COMPONENT}" ]]
then
    echo "ERROR: Deployment component not specified. Aborting."
    exit 1
fi

shift

export DEPLOY_SCRIPT_NAME=$1

if [[ ! "${DEPLOY_SCRIPT_NAME}" ]]
then
    echo "ERROR: Deployment script not specified. Aborting."
    exit 1
fi

shift


# Executing deploy.sh which will execute the script
#
. ${SK_SCRIPT_HOME}/sk-deploy.sh ${DEPLOY_COMPONENT} $@

