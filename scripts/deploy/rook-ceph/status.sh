#!/usr/bin/env bash

# ==============================================================================
#
# Prints status information about your Rook/Ceph storage cluster
#
# ==============================================================================

# ------------------------------------------------------------
# Stop immediately if any of the commands fail
trap errorHandler ERR

#
# Getting a status about the Ceph cluster
#
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') ceph status

echo
echo "-------------------------------------"
echo "Check these on the status output:"
echo
echo " - Health must be 'HEALTH_OK'"
echo " - All monitors (mons) should be in quorum (in the services section)"
echo " - A mgr should be active"
echo " - At least one OSD should be active (normally at least as many as the nodes)"
echo "-------------------------------------"




