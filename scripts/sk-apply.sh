#!/usr/bin/env bash

#
# Creates or modifies the K8s cluster
#
# All parameters are forwarded to the sk-tf.sh script and thus to Terraform
#


. ${SK_SCRIPT_HOME}/sk-tf.sh apply "$@"
checkResultExit "Terraform apply"

# The ID of the newly created cluster in your Rancher installation
RANCHER_CLUSTER_ID="$(${SK_SCRIPT_HOME}/sk-tf.sh output "rancher_cluster_id")"

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

