#!/usr/bin/env bash

# ==============================================================================
#
# Restores a filesystem backup from the backup repository
#
# 1 - The backup selector options for Velero
#     If not specified, the last backup of the daily schedule of the
#     profile will be targeted
#
# Expects the following variables set in the shell:
# - APPLICATION - The name of the application
# - PROFILE - The backup profile name of the application
#             Optional, defaults to empty (default profile)
# ==============================================================================

# Internal parameters

# Stop immediately if any of the deployments fail
trap errorHandler ERR

BACKUP_SELECTOR=$1

echoHeader "Velero: Restoring with the '${PROFILE}' profile for ${APPLICATION}"

# ------------------------------------------------------------
echoSection "Validating parameters"

if [[ ! ${BACKUP_SELECTOR} ]]
then
    echo "No backup is specified for the '${PROFILE}' profile of the '${APPLICATION}' application"
    echo "The last backup of the daily schedule will be targeted for restore"

    BACKUP_SELECTOR="--from-schedule ${APPLICATION}-${PROFILE:-default}-daily"
fi

# loading application-specific backup config variables into generic ones
normalizeConfigVariables "${APPLICATION}" "${PROFILE}"

# Setting defaults for generic backup variables if they are not defined
applyDefaults "${APPLICATION}" "${PROFILE}"


# Ensuring that no new backups can write into the location while
# the restore is under way
setLocationAccessMode ${BACKUP_LOCATION_NAME} "ReadOnly"

# ------------------------------------------------------------
echoSection "Executing backup"

RESTORE_NAME="${APPLICATION}-${PROFILE:-default}-$(date +%Y%m%d-%H%M)"

velero restore create ${RESTORE_NAME} \
  ${BACKUP_SELECTOR} \
  --wait

# Restoring access mode to the storage location
setLocationAccessMode ${BACKUP_LOCATION_NAME} "ReadWrite"

# ------------------------------------------------------------
