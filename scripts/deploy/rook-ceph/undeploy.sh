#!/usr/bin/env bash

# ==============================================================================
#
# Uninstalls the Rook/Ceph installation from your cluster
#
# ==============================================================================


# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Uninstalling Rook/Ceph from your cluster"

# ------------------------------------------------------------
echoSection "Deleting namespace"

kubectl delete namespace rook-ceph

echoSection "Deleting storage class"

kubectl delete storageclass rook-ceph-block

# ------------------------------------------------------------
echoSection "Rook/Ceph objects have been deleted on your cluster"

echo
echo "WARNING: you still need to remove the /var/lib/rook folder from each node"
echo