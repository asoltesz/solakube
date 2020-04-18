#!/usr/bin/env bash

#
# Destroys the K8s cluster and the Hetzner VMs
#
# All parameters are forwarded to the sk-tf.sh script and thus to Terraform
#
# WARNING: This also destroys the Hetzner Floating IP and the "private network"
#

${SK_SCRIPT_HOME}/sk-tf.sh destroy "$@"

if [[ $? == 0 ]]
then
    # Empty the KubeCtl config
    echo "# Cluster destroyed" > ~/.kubectl/config_${SK_CLUSTER}.yaml
fi
