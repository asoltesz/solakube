#!/usr/bin/env bash

# ==============================================================================
# Deploys the Velero backup configuration for OpenLDAP on your cluster
# ==============================================================================


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying backup config for OpenLDAP"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "registry"

# ------------------------------------------------------------
echoSection "Deploying backup configuration"

. ${SK_SCRIPT_HOME}/sk-velero.sh ${OPENLDAP_APP_NAME} backup default schedule

# ------------------------------------------------------------
echoHeader "Deployed backup config for OpenLDAP"
