#!/usr/bin/env bash

# ==============================================================================
#
# Deletes a Kubernetes namespace
#
# WARNING: This will not ask for confirmation but immedately start deleting the
# namespace.
#
# ==============================================================================

# Internal parameters

# Stop immediately if any of the deployments fail
trap errorHandler ERR

NAMESPACE=$1

echoHeader "Deleting namespace: ${NAMESPACE} "

kubectl delete namespace ${NAMESPACE}
