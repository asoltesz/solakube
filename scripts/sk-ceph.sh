#!/usr/bin/env bash

# ==============================================================================
#
# Operations around the Rook/Ceph installation in your cluster
#
# 1 - the command to be executed
# ==============================================================================

COMMAND=$1


if [[ $COMMAND = "status" ]]
then
    kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') ceph status
fi

