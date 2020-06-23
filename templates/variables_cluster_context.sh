#!/usr/bin/env bash

#
# Select the type of cluster you are working with
#


# A normal, multi-node K8S cluster operating on Hetzner Cloud
# and managed via Rancher
SK_CLUSTER_TYPE="hetzner"

# A local developer/tester Minikube cluster (single node)
#SK_CLUSTER_TYPE="minikube"

# Multi-node test cluster created with Vagrant-based virtual machines
# on a physical host we have access to. Deployed via RKE
# SK_CLUSTER_TYPE="vagrant"
