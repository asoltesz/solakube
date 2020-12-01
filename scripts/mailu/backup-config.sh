#!/usr/bin/env bash

# ==============================================================================
#
# Deploys the Velero backup configuration for Mailu on your cluster
#
# ==============================================================================


# Stop immediately if any of the deployments fail
trap errorHandler ERR

checkAppName "mailu"

echoHeader "Deploying backup config for Mailu "


# ------------------------------------------------------------
echoSection "Deploying backup configuration"

. ${SK_SCRIPT_HOME}/sk-velero.sh backup schedule ${MAILU_APP_NAME} default

# ------------------------------------------------------------
echoHeader "Deployed backup config for Mailu "

