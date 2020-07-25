#!/usr/bin/env bash

# ==============================================================================
#
# Execute a Velero backup configuration for an application or deploy a
# scheduled backup profile.
#
# Assumes that the application has its own namespace (as it should).
#
# Parameters:
# 1 - Command to execute ("execute" or "schedule")
#     - "execute" - A backup is executed immediately
#     - "schedule" - A periodic backup is scheduled for the future
#
# Expects the following variables set in the shell:
# - APPLICATION
#   The name of the application
#
# - PROFILE
#   The backup profile name of the application.
#   Optional, defaults to empty (default profile)
#
# - <APPLICATION>_BACKUP_*
#   The parameters that will form the backup profile
#
# ==============================================================================

# Internal parameters

# Stop immediately if any of the deployments fail
trap errorHandler ERR

OPERATION=${1:-"execute"}

if [[ ${OPERATION} != "execute" ]] && [[ ${OPERATION} != "schedule" ]]
then
    echo "ERROR: Illegal Velero backup operation: ${OPERATION}"
    exit 1
fi

echoHeader "Velero backup ${OPERATION} for ${APPLICATION}"

# ------------------------------------------------------------
echoSection "Validating parameters"


# loading application-specific backup config variables into generic ones
normalizeConfigVariables "${APPLICATION}" "${PROFILE}"

# Setting defaults for generic backup variables if they are not defined
applyDefaults "${APPLICATION}" "${PROFILE}"

# Validates mandatory filesystem/restic specific backup variables
validateVariables "${APPLICATION}" "${PROFILE}"


# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "${APPLICATION}"

# ------------------------------------------------------------
echoSection "Checking/creating namespace"

defineNamespace "${APPLICATION}"


# ------------------------------------------------------------
echoSection "Checking/creating the S3 backup location if necessary"

LOCATION_NAME="${APPLICATION}"
if [[ ${PROFILE} ]]
then
    LOCATION_NAME="${APPLICATION}-${PROFILE}"
fi

checkBackupLocationExists "${LOCATION_NAME}"

# ------------------------------------------------------------

BACKUP_NAME=${LOCATION_NAME}


if [[ ${OPERATION} == "execute" ]]
then
    echoSection "Executing a backup "

    executeApplicationBackup

    END_MESSAGE="Velero backup ${BACKUP_NAME} has been executed"
fi

# ------------------------------------------------------------

if [[ ${OPERATION} == "schedule" ]]
then
    echoSection "Deploying the backup schedules"

    scheduleApplicationBackup

    END_MESSAGE="Velero backup ${BACKUP_NAME} has been scheduled"
fi

# ------------------------------------------------------------
echoSection "${END_MESSAGE}"

