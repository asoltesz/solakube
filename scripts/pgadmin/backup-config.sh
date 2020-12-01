#!/usr/bin/env bash

# ==============================================================================
#
# Deploys the Velero backup configuration for pgAdmin on your cluster
# ==============================================================================


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying backup config for pgAdmin "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "pgadmin"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "pgadmin"


# ------------------------------------------------------------
echoSection "Patching the deployment for Velero/Restic annotations"

sleep 5

waitAllPodsActive ${PGADMIN_APP_NAME}

echo

kubectl patch deployment ${PGADMIN_APP_NAME} \
  --patch "$(cat velero-deployment-patch.yaml)" \
  -n ${PGADMIN_APP_NAME}

echo
sleep 5

waitAllPodsActive ${PGADMIN_APP_NAME}

# ------------------------------------------------------------
echoSection "Deploying backup configuration"

. ${SK_SCRIPT_HOME}/sk-velero.sh backup schedule ${PGADMIN_APP_NAME} default

# ------------------------------------------------------------
echoHeader "Deployed backup config for pgAdmin "

