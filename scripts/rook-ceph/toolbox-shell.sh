#!/usr/bin/env bash

# ==============================================================================
#
# Verifies the Rook/Ceph installation in your cluster
#
# ==============================================================================

#
# Logging into the toolbox container shell to execute manual commands
#
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash





