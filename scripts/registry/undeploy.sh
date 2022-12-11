#!/usr/bin/env bash

# ==============================================================================
#
# Deletes the Docker Registry from the cluster
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing Docker Registry (${DOCKER_REGISTRY_APP_NAME}) from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "registry"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "registry"

# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${REGISTRY_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${REGISTRY_APP_NAME}


# ------------------------------------------------------------
echoSection "Docker Registry has been removed from your cluster"
