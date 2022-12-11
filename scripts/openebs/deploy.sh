#!/usr/bin/env bash

# ==============================================================================
#
# Install OpenEBS on your cluster
#
# Installs the appropriate Ingress and cert-manager Certificate descriptor
# for HTTPS access of OpenEBS
#
# WARNING: Assumes that a cert-manager ClusterIssuer named "letsencrypt-http01"
# is already deployed on the cluster (it will define the Certificate to be
# requested from)
#
# ==============================================================================

# Internal parameters

HELM_CHART_VERSION="2.3.0"
OPENEBS_VERSION="2.3.0"

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying the OpenEBS storage provisioner "
echo "Version: ${OPENEBS_VERSION}"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "openebs"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "openebs"

# ------------------------------------------------------------
#echoSection "Preparing Helm chart values"
#processTemplate chart-values.yaml


# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${OPENEBS_APP_NAME}


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

processTemplate chart-values.yaml

helm repo add openebs https://openebs.github.io/charts
helm repo update

echo "Executing Helm chart install/upgrade"

helm upgrade ${OPENEBS_APP_NAME} openebs/openebs \
    --install \
    --namespace ${OPENEBS_APP_NAME} \
    --version=${HELM_CHART_VERSION} \
    --values ${TMP_DIR}/chart-values.yaml

# ------------------------------------------------------------

# Test why open-iscsi doesn't work on Ubuntu 20.04 before adding this
#if [[ ${SK_CLUSTER_TYPE} == "minikube" ]]
#then
#    echo "Dropping NDM because it cannot be used on Minikube"
#    kubectl delete deployment ${OPENEBS_APP_NAME}-ndm \
#        --namespace ${OPENEBS_APP_NAME} \
#fi

# OpenEBS provisioner must be ready when volumes are requested so the
# startup must be waited upon
waitAllPodsActive ${OPENEBS_APP_NAME}

# ------------------------------------------------------------
echoSection "OpenEBS has been installed on your cluster"

