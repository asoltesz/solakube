#!/usr/bin/env bash

# ==============================================================================
#
# Verifies the Rook/Ceph installation in your cluster
#
# ==============================================================================

# Internal parameters

HELM_CHART_VERSION=1.1.7

# ------------------------------------------------------------
source ../shared.sh

# Stop immediately if any of the deployments fail
trap errorHandler ERR


# ------------------------------------------------------------
echoSection "Validating parameters"

#paramValidation "XXX-PARAM_NAME" \
#   "Please define XXX with the value of EXPLANATION. e.g.: EXAMPLE"

echo "This script is a WIP, please use its commands manually, one by one"
if [[ 1 == 1 ]]
then
    exit 1
fi

# ------------------------------------------------------------
echoSection "Installing the Rook Toolbox Deployment"

kubectl create -f toolbox.yaml \
        --namespace rook-ceph

# ------------------------------------------------------------
echoSection "Waiting until the Toolbox starts up"

kubectl get pod -l "app=rook-ceph-tools" \
        --namespace rook-ceph

# ------------------------------------------------------------
echoSection "Verifying the installation and storage cluster"

# TODO Implement verification with commands

# Log into the first Ceph
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash

# Run "ceph status" manually and check:
#
# - Health must be 'HEALTH_OK'
# - All mons should be in quorum
# - A mgr should be active
# - At least one OSD should be active
#

# ------------------------------------------------------------
echoSection "Removing the toolbox"

kubectl delete deployment rook-ceph-tools \
        --namespace rook-ceph

# ------------------------------------------------------------
echoSection "Rook/Ceph has been verified on your cluster"

