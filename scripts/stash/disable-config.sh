#!/usr/bin/env bash

# ==============================================================================
# Disables an application filesystem backup cronjob for a backup configuration.
#
# This effectively disables the scheduled backups for this backup profile.
#
# 1 - Name of the backup profile (optional, defaults to 'DEFAULT')
# ==============================================================================

# Internal parameters

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Disabling the ${PROFILE} Stash filesystem backup configuration for ${APPLICATION}"

# ------------------------------------------------------------
echoSection "Patching backup config"

kubectl patch backupconfiguration ${PROFILE} \
    -n ${APPLICATION} \
    --type="merge" \
    --patch='{"spec": {"paused": true}}'

echoHeader "Disabled the ${PROFILE} Stash filesystem backup configuration for ${APPLICATION}"

