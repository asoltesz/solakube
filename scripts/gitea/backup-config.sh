#!/usr/bin/env bash

# ==============================================================================
# Deploys the Velero backup configuration for Gitea on your cluster
# ==============================================================================


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying backup config for Gitea"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "gitea"

# ------------------------------------------------------------
echoSection "Deploying backup configuration"

. ${SK_SCRIPT_HOME}/sk-velero.sh ${GITEA_APP_NAME} backup default schedule

# ------------------------------------------------------------
echoHeader "Deployed backup config for Gitea "

