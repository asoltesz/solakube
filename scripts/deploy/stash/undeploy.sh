#!/usr/bin/env bash

# ==============================================================================
#
# Deletes Stash from the cluster
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing Stash from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "stash"


# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${STASH_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${STASH_APP_NAME}


# ------------------------------------------------------------
echoSection "Stash has been removed from your cluster"

