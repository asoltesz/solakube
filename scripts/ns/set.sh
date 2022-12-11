#!/usr/bin/env bash

# ==============================================================================
#
# Sets/selects a Kubernetes namespace as the default namespace for future
# kubectl commands.
#
# ==============================================================================

# Internal parameters

# Stop immediately if any of the deployments fail
trap errorHandler ERR

NAMESPACE=$1

echoHeader "Setting current namespace: ${NAMESPACE} "

kubectl config set-context --current --namespace="${NAMESPACE}"
