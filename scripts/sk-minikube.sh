#!/usr/bin/env bash

#
# Command for the local cluster created with kind
#
# 1 - The component to deploy (e.g: "rook-ceph")
#

COMMAND=$1

if [[ ! "${COMMAND}" ]]
then
    echo "ERROR: minikube command not specified. Aborting."
    exit 1
fi

shift

export SCRIPTS_SUB_DIR=${SK_SCRIPT_HOME}/minikube


# Executing the deployer
. ${SCRIPTS_SUB_DIR}/${COMMAND}.sh $@

