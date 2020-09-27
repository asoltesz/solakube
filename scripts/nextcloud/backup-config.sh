#!/usr/bin/env bash

# ==============================================================================
#
# Deploys the Velero backup configuration for nextcloud on your cluster
# ==============================================================================


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying backup config for nextcloud "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "nextcloud"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "nextcloud"


# ------------------------------------------------------------
echoSection "Patching the deployment for Velero/Restic annotations"

sleep 5

waitAllPodsActive ${NEXTCLOUD_APP_NAME}

echo

kubectl patch deployment ${NEXTCLOUD_APP_NAME} \
  --patch "$(cat velero-deployment-patch.yaml)" \
  -n ${NEXTCLOUD_APP_NAME}

echo
sleep 5

waitAllPodsActive ${NEXTCLOUD_APP_NAME}

# ------------------------------------------------------------
echoSection "Deploying backup configuration"

. ${SK_SCRIPT_HOME}/sk-velero.sh ${NEXTCLOUD_APP_NAME} backup default schedule

# ------------------------------------------------------------
echoHeader "Deployed backup config for nextcloud "

