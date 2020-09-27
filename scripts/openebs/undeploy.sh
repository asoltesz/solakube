#!/usr/bin/env bash

# ==============================================================================
#
# Deletes OpenEBS from the cluster
#
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing the OpenEBS storage provisioner from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "openebs"

# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${OPENEBS_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${OPENEBS_APP_NAME}

# ------------------------------------------------------------
echoSection "OpenEBS has been removed from your cluster"

