#!/usr/bin/env bash

# ==============================================================================
#
# Installs Rook/Ceph into the cluster
#
# ==============================================================================

# Internal parameters

ROOK_VERSION=1.1

# ------------------------------------------------------------
source ../shared.sh

# Stop immediately if any of the deployments fail
trap errorHandler ERR


# ------------------------------------------------------------
echoSection "Validating parameters"

#paramValidation "XXX-PARAM_NAME" \
#   "Please define XXX with the value of EXPLANATION. e.g.: EXAMPLE"


# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "rook"

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace rook-ceph

# ------------------------------------------------------------
echoSection "Creating the Rook storage operator"

kubectl apply -f k8s/common.yaml \
    --namespace=rook-ceph

kubectl apply -f k8s/operator.yaml \
    --namespace=rook-ceph

# ------------------------------------------------------------
echoSection "Creating the Rook/Ceph storage cluster"

kubectl create -f k8s/cluster-test.yaml \
    --namespace=rook-ceph

# ------------------------------------------------------------
echoSection "Creating the 'rook-ceph-block' storage class"

kubectl create -f k8s/storageclass.yaml \
    --namespace=rook-ceph


# ------------------------------------------------------------
echoSection "Rook/Ceph ${ROOK_VERSION} has been installed on your cluster"

