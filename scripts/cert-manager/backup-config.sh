#!/usr/bin/env bash

# ==============================================================================
# Deploys the Velero backup configuration for cert-manager on your cluster
# ==============================================================================


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying backup config for cert-manager "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "cert-manager"

# Applying defaults
cexport CERT_MANAGER_BACKUP_RESOURCES_EXCLUDED="orders.acme.cert-manager.io,challenges.acme.cert-manager.io"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "cert-manager"

# ------------------------------------------------------------
echoSection "Deploying backup configuration"

. ${SK_SCRIPT_HOME}/sk-velero.sh backup schedule "cert-manager" default

# ------------------------------------------------------------
echoHeader "Deployed backup config for cert-manager"

