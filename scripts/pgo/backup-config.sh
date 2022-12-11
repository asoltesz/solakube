#!/usr/bin/env bash

# ==============================================================================
# Deploys the Velero backup configuration for PGO on your cluster
# ==============================================================================


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying backup config for Pgo "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "pgo"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "pgo"

# ------------------------------------------------------------
echoSection "Deploying backup configuration"

. ${SK_SCRIPT_HOME}/sk-velero.sh backup schedule ${PGO_APP_NAME} default

# ------------------------------------------------------------
echoHeader "Deployed backup config for PGO"

