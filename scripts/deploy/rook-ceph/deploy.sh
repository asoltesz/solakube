#!/usr/bin/env bash

# ==============================================================================
# Installs a Rook/Ceph storage cluster into the K8s cluster
#
# For this to succeed, the sda2 partition must be available for storage
# purposes on participating machines.
#
# See docs/rook-ceph.md for details
# ==============================================================================

# Internal parameters

ROOK_VERSION=1.2

# ------------------------------------------------------------
# Stop immediately if any of the deployment commands fail
trap errorHandler ERR

echoHeader "Deploying a Rook/Ceph storage cluster on your k8s cluster"

echoSection "Validating parameters"

#paramValidation "XXX-PARAM_NAME" \
#   "Please define XXX with the value of EXPLANATION. e.g.: EXAMPLE"


# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "rook-ceph"

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace rook-ceph

# ------------------------------------------------------------
echoSection "Creating the Rook storage operator"

kubectl apply -f common.yaml \
    --namespace=rook-ceph

kubectl apply -f operator.yaml \
    --namespace=rook-ceph

kubectl apply -f toolbox.yaml \
    --namespace=rook-ceph

# ------------------------------------------------------------
echoSection "Creating the Rook/Ceph storage cluster"

cexport ROOK_CLUSTER_TYPE "default"

if [[ ${SK_CLUSTER_TYPE} != "hetzner" ]]
then
    # K8s Cluster type is not the default Hetzner

    # On minikube and vagrant, only the testing cluster is supported
    # (storage is in a folder, not on a device)
    cexport ROOK_CLUSTER_TYPE "testing"
fi

CLUSTER_FILE="cluster-${ROOK_CLUSTER_TYPE}.yaml"

echo "Cluster file defining the Ceph storage cluster: ${CLUSTER_FILE}"

processTemplate "${CLUSTER_FILE}"

kubectl apply -f ${TMP_DIR}/${CLUSTER_FILE} \
    --namespace=rook-ceph

# ------------------------------------------------------------
echoSection "Creating the 'rook-ceph-block' storage class"

kubectl create -f storageclass.yaml \
    --namespace=rook-ceph


# ------------------------------------------------------------
echoSection "Creating the snapshotclass"

echo "Waiting for Snapshot API to activate"
sleep 120

kubectl apply -f snapshotclass.yaml \
    --namespace=rook-ceph

# ------------------------------------------------------------
echoSection "Rook/Ceph ${ROOK_VERSION} deployment descriptors have been installed to your cluster"
echoSection "The storage cluster should initialize imminently (please track its successful conclusion before deploying any PV-dependent components)"

