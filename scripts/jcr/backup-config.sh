#!/usr/bin/env bash

# ==============================================================================
# Deploys the Velero backup configuration for JFrog Container Registry on your cluster
# ==============================================================================


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying backup config for JFrog Container Registry"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "jcr"

# ------------------------------------------------------------
echoSection "Deploying backup configuration"

. ${SK_SCRIPT_HOME}/sk-velero.sh backup schedule ${JCR_APP_NAME} default

# ------------------------------------------------------------
echoHeader "Deployed backup config for JFrog Container Registry"

