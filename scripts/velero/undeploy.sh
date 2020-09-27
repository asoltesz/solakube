#!/usr/bin/env bash

# ==============================================================================
#
# Deletes Velero from the cluster
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing Velero from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "velero"


# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${VELERO_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${VELERO_APP_NAME}


# ------------------------------------------------------------
echoSection "Velero has been removed from your cluster"

