#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Cluster type and other variables that need to be defined before
# variables.sh executions
# ------------------------------------------------------------------------------


# A normal, multi-node K8S cluster operating on Hetzner Cloud
# and managed via Rancher
cexport SK_CLUSTER_TYPE "hetzner"

# A local developer/tester Minikube cluster (single node)
#SK_CLUSTER_TYPE="minikube"

# Multi-node test cluster created with Vagrant-based virtual machines
# on a physical host we have access to. Deployed via RKE
# SK_CLUSTER_TYPE="vagrant"


if [[ ${SK_CLUSTER_TYPE} == "minikube" ]]
then
    cexport CLUSTER_FQN "${SK_CLUSTER}.mk"
fi
