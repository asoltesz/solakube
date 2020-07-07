#!/usr/bin/env bash

# ==============================================================================
# Execute a Stash disaster recovery command in relation to a SolaKube
# application.
#
# 1 - The application to work with (e.g: "nextcloud")
# 2 - The disaster recovery command/operation (e.g.: "enable-backup")
# 3 - The profile to be used (e.g.: "default")
# ==============================================================================

APPLICATION=$1

if [[ ! "${APPLICATION}" ]]
then
    echo "ERROR: Application/component not specified (e.g.: 'nextcloud'). Aborting."
    exit 1
fi

shift

OPERATION=$1

if [[ ! "${OPERATION}" ]]
then
    echo "ERROR: Stash command not specified (e.g.: 'enable-fs-job'). Aborting."
    exit 1
fi

shift

PROFILE=$1

if [[ ! "${PROFILE}" ]]
then
    PROFILE="default"
else
    shift
fi


# Loading the deployment support shared library
. ${SK_SCRIPT_HOME}/deploy/deploy-shared.sh

# Loading the stash support shared library
. ${SK_SCRIPT_HOME}/stash/stash-shared.sh

# Stash script storage folder
export STASH_SCRIPTS_DIR=${SK_SCRIPT_HOME}/stash
export STASH_DEPLOYMENT_DIR=${SK_SCRIPT_HOME}/../deployment/stash/app

cd "${STASH_DEPLOYMENT_DIR}"

# Executing the command
. ${STASH_SCRIPTS_DIR}/${OPERATION}.sh $@

