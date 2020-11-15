#!/usr/bin/env bash

# ==============================================================================
#
# Deletes Code from the cluster
#
# WARNING: Deletes the database as well
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

APP_TITLE="Collabora CODE Document Server"

echoHeader "Removing ${APP_TITLE} (${CODE_APP_NAME}) from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "code"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "code"

# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${CODE_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${CODE_APP_NAME}

# ------------------------------------------------------------
echoSection "${APP_TITLE} has been removed from your cluster"
