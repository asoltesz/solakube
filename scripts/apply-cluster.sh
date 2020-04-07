#!/usr/bin/env bash


#
# Creates or modifies the K8s cluster
#

if [[ ! ${SK_CLUSTER} ]]
then
    echo "SK_CLUSTER not specified in the shell. Aborting."
    exit 1
fi

./tf apply

if [[ $? == 0 ]]
then
    # The ID of the newly created cluster in your Rancher installation
    RANCHER_CLUSTER_ID="$(./tf output "rancher_cluster_id")"

    if [[ $? != 0 ]]
    then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!: ${RANCHER_CLUSTER_ID}"
        echo "WARNING: Failed to load the cluster id from the Terraform state"
        exit 1
    fi

    # Exporting the cluster ID for the other scripts to load
    file=~/.solakube/${SK_CLUSTER}/rancher_cluster_id.sh
    echo "export RANCHER_CLUSTER_ID=${RANCHER_CLUSTER_ID}" > ${file}
    chmod +x ${file}
fi
