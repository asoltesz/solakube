#!/usr/bin/env bash

# ==============================================================================
#
# Installs Rook/Ceph into the cluster
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


# ------------------------------------------------------------
echoSection "Preparing temp folder"

TMP_DIR=/tmp/helm/rook
rm -Rf ${TMP_DIR}
mkdir -p ${TMP_DIR}

# ------------------------------------------------------------
echoSection "Adding the Rook Helm chart repo"

helm repo add rook-release https://charts.rook.io/release

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

envsubst < chart-values.yaml > ${TMP_DIR}/chart-values.yaml

envsubst < storage-cluster.yaml > ${TMP_DIR}/storage-cluster.yaml

# ------------------------------------------------------------
echoSection "Creating namespace"

addNamespace rook-ceph

# ------------------------------------------------------------
echoSection "Installing with Helm chart"

helm install rook-release/rook-ceph \
    --namespace rook-ceph \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml


# ------------------------------------------------------------
echoSection "Creating the storage cluster"

kubectl create -f ${TMP_DIR}/storage-cluster.yaml

# ------------------------------------------------------------
echoSection "Creating the 'rook-ceph-block' storage class"

kubectl create -f storage-class.yaml


# ------------------------------------------------------------
echoSection "Rook/Ceph has been installed on your cluster"

