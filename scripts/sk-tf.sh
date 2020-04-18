#!/bin/bash

#
# Executes Terraform with the context of a certain cluster
#

if [[ "${SK_CLUSTER}" ]]
then
    CLUSTER="${SK_CLUSTER}"
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
      --cluster)
        CLUSTER="$2"
        shift # past argument
        shift # past value
      ;;
      *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
      ;;
    esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

[[ -z "$CLUSTER" ]] && { echo "Please specify the name of the cluster with '--cluster'" ; exit 1; }

# Entering the Terraform home folder for the cluster
cd ${SK_SCRIPT_HOME}/../terraform/clusters/${CLUSTER}
if [[ $? != 0 ]]
then
    echo "Couldn't enter the Terraform folder of the cluster".
    exit 1
fi

# Loading secrets for the cluster from ~/.solakube
SECRET_FILE=~/.solakube/${CLUSTER}/variables.sh
source ${SECRET_FILE}
if [[ $? != 0 ]]
then
    echo "Couldn't load secrets for the cluster from ${SECRET_FILE}"
    exit 1
fi

TF_COMMAND=${1}

terraform "$@"
if [[ $? != 0 ]]
then
    echo "Terraform execution has FAILED"
    exit 1
fi

if [[ "${TF_COMMAND}" != "output" ]]
then
    echo "Terraform execution was SUCCESSFUL"
fi
