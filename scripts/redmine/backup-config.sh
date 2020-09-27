#!/usr/bin/env bash

# ==============================================================================
# Deploys the Velero backup configuration for Redmine on your cluster
# ==============================================================================


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying backup config for Redmine"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "redmine"

# ------------------------------------------------------------
echoSection "Deploying backup configuration"

. ${SK_SCRIPT_HOME}/sk-velero.sh ${REDMINE_APP_NAME} backup default schedule

# ------------------------------------------------------------
echoHeader "Deployed backup config for Redmine "

