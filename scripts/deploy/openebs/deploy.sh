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

HELM_CHART_VERSION=1.11.0

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying the OpenEBS storage provisioner "

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

helm install stable/openebs \
    --name ${OPENEBS_APP_NAME} \
    --namespace ${OPENEBS_APP_NAME} \
    --version=${HELM_CHART_VERSION}
#    --values ${TMP_DIR}/chart-values.yaml

# ------------------------------------------------------------


# ------------------------------------------------------------
echoSection "OpenEBS has been installed on your cluster"

