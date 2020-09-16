#!/usr/bin/env bash

# ==============================================================================
#
# Deletes JFrog Container Registry from the cluster
#
# WARNING: Deletes the database as well
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing JFrog Container Registry (${JCR_APP_NAME}) from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "jcr"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "jcr"

# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${JCR_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${JCR_APP_NAME}

# ------------------------------------------------------------
echoSection "Dropping the Postgres database of JCR"

dropPgApplicationDatabase ${JCR_APP_NAME}

# ------------------------------------------------------------
echoSection "JFrog Container Registry has been removed from your cluster"
