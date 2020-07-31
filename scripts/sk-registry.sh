#!/usr/bin/env bash

# ==============================================================================
# Execute a Docker Registry command
# ==============================================================================


COMMAND=$1

if [[ ! "${COMMAND}" ]]
then
    echo "ERROR: Registry command not specified (e.g.: 'garbage-collect'). Aborting."
    exit 1
fi

shift

# Loading the deployment support shared library
. ${SK_SCRIPT_HOME}/deploy/deploy-shared.sh

# Velero script storage folder
export REGISTRY_SCRIPTS_DIR=${SK_SCRIPT_HOME}/registry

export REGISTRY_DEPLOYMENT_DIR=${SK_DEPLOYMENT_HOME}/registry

cd "${REGISTRY_DEPLOYMENT_DIR}"

# Executing the command
. ${REGISTRY_SCRIPTS_DIR}/${COMMAND}.sh $@

