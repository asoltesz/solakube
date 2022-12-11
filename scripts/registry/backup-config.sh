#!/usr/bin/env bash

# ==============================================================================
# Deploys the Velero backup configuration for Docker Registry on your cluster
# ==============================================================================


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying backup config for Docker Registry"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "registry"

# ------------------------------------------------------------
echoSection "Deploying backup configuration"

. ${SK_SCRIPT_HOME}/sk-velero.sh backup schedule ${REGISTRY_APP_NAME} default

# ------------------------------------------------------------
echoHeader "Deployed backup config for Docker Registry"
