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
CLUSTER_DIR="$(resolvePathOnRoots "terraform/clusters/${CLUSTER}")"
cd "${CLUSTER_DIR}"
if [[ $? != 0 ]]
then
    echo "Couldn't enter the Terraform folder of the cluster".
    exit 1
fi

# Exporting SK variables from each SK_ROOT to Terraform

for root in ${SK_ROOTS//:/ }
do
    if [[ -f "${root}/variables-export-terraform.sh" ]]
    then
        # echo "Exporting variables for Terraform: ${root}"

        . ${root}/variables-export-terraform.sh
    fi
done

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
