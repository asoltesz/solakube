#!/usr/bin/env bash

# ==============================================================================
# Deploys the Velero backup configuration for Jenkins on your cluster
# ==============================================================================


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying backup config for Jenkins "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "jenkins"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "jenkins"

# ------------------------------------------------------------
echoSection "Deploying backup configuration"

. ${SK_SCRIPT_HOME}/sk-velero.sh backup schedule ${JENKINS_APP_NAME} default

# ------------------------------------------------------------
echoHeader "Deployed backup config for Jenkins"

