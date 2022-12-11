#!/usr/bin/env bash

# ==============================================================================
#
# Installs a non-authenticating Postix SMTP relay for your internal services.
#
# ==============================================================================

# Internal parameters

# Stop immediately if any of the deployments fail
trap errorHandler ERR

# ------------------------------------------------------------
echoSection "Validation and parameters"

paramValidation "POSTFIX_RELAY_SMTP_HOST" "your upstream SMTP service host"
paramValidation "POSTFIX_RELAY_SMTP_PORT" "SMTP port on your upstream SMTP service host"
paramValidation "POSTFIX_RELAY_SMTP_USERNAME" "username for your upstream SMTP service host"
paramValidation "POSTFIX_RELAY_SMTP_PASSWORD" "password for your upstream SMTP service host"

# Note: SMTP username and password may be omitted if the rel


# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "postfix-relay"

# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace "postfix-relay"

# ------------------------------------------------------------
echoSection "Installing Postfix-Relay"

applyTemplate k8s.yaml

# ------------------------------------------------------------
echoSection "Deploying Velero backup schedule"

DEPLOY_BCK_PROFILE="$(shouldDeployBackupProfile "postfix-relay")"

if [[ "${DEPLOY_BCK_PROFILE}" == "true" ]]
then
    . ${SK_SCRIPT_HOME}/sk-velero.sh backup schedule "postfix-relay" default
else
    echo "Built-in backup profile is not deployed: ${DEPLOY_BCK_PROFILE}"
fi

# ------------------------------------------------------------
echoSection "Postfix-Relay has been installed on your cluster"

