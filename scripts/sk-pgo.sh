#!/usr/bin/env bash

#
# Command for the PGO operator
#
# 1 - The SK command (must be a script for it)
#

COMMAND=$1

if [[ ! "${COMMAND}" ]]
then
    echo "ERROR: PGO command not specified. Aborting."
    exit 1
fi

shift

export SCRIPTS_SUB_DIR=${SK_SCRIPT_HOME}/pgo

. ${SK_SCRIPT_HOME}/deploy/deploy-shared.sh

. ${SCRIPTS_SUB_DIR}/pgo-shared.sh

# Executing the script
. ${SCRIPTS_SUB_DIR}/${COMMAND}.sh

