#!/usr/bin/env bash

# ==============================================================================
#
# Enables an application backup configuration
#
# 1 - Name of the backup profile (optional, defaults to 'default')
#
# ==============================================================================

# Internal parameters

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Enabling the '${PROFILE}' Stash backup configuration for ${APPLICATION}"

# ------------------------------------------------------------
echoSection "Patching backup config"

kubectl patch backupconfiguration ${PROFILE} \
    -n ${APPLICATION} \
    --type="merge" \
    --patch='{"spec": {"paused": false}}'

echoHeader "Enabled the '${PROFILE}' Stash backup configuration for ${APPLICATION}"

