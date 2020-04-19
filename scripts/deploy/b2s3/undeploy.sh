#!/usr/bin/env bash

# ==============================================================================
#
# Deletes teh BackBlaze B2 support from the cluster
#
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing B2S3 from your cluster"

# ------------------------------------------------------------
checkAppName "b2s3"

# ------------------------------------------------------------
echoSection "Removing via Helm"

helm del --purge ${B2S3_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${B2S3_APP_NAME}

# ------------------------------------------------------------
echoSection "BackBlaze B2 support has been removed from your cluster"
