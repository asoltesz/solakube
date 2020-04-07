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

kubectl create -f k8s/toolbox.yaml \
        --namespace rook-ceph

# ------------------------------------------------------------
echoSection "Waiting until the Toolbox starts up"

sleep 5s

# ------------------------------------------------------------
echoSection "Verifying the installation and storage cluster"

#
# Getting a status about the Ceph cluster
#
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') ceph status

# -------------------------------------
# Check these on the status output:
#
# - Health must be 'HEALTH_OK'
# - All monitors (mons) should be in quorum (in the services section)
# - A mgr should be active
# - At least one OSD should be active (normally at least as many as the nodes)
# -------------------------------------

#
# Logging into the toolbox container shell to execute manual commands
#
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash



# ------------------------------------------------------------
echoSection "Removing the toolbox"

kubectl delete deployment rook-ceph-tools \
        --namespace rook-ceph

# ------------------------------------------------------------
echoSection "Rook/Ceph has been verified on your cluster"

