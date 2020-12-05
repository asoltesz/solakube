#!/usr/bin/env bash

# ==============================================================================
#
# Restores a filesystem backup from the backup repository
#
# 1 - The application to work with (e.g: "nextcloud")
# 2 - The profile to be used (e.g.: "default")
# 3 - The backup selector options for Velero
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

APPLICATION=$1

if [[ -z "${APPLICATION}" ]]
then
    echo "ERROR: Application/component not specified (e.g.: 'nextcloud'). Aborting."
    exit 1
fi

PROFILE=$2

if [[ -z "${PROFILE}" ]]
then
    echo "Backup profile not specified, using 'default' "
    PROFILE="default"
fi

BACKUP_SELECTOR=$3

echoHeader "Velero: Restoring with the '${PROFILE}' profile for the '${APPLICATION}' application"

# ------------------------------------------------------------
echoSection "Validating parameters"

if [[ -z ${BACKUP_SELECTOR} ]]
then
    echo "No backup is specified for the '${PROFILE}' profile of the '${APPLICATION}' application"
    echo "The last backup will be selected for restore"

    LAST_BACKUP=$(
        kubectl get backup \
            --namespace="velero" \
            --sort-by=.metadata.creationTimestamp \
            --output=jsonpath='{range .items[*]}{.status.completionTimestamp}{"::"}{.metadata.name}{"::"}{.status.phase}{"\n"}' \
           | grep "::Completed" \
           | grep "${APPLICATION}-${PROFILE}" \
           | sort -r \
           | head -n 1 \
           | grep -oP '::(.*?)::'
    )
    LAST_BACKUP="${LAST_BACKUP//:}"

    BACKUP_SELECTOR="--from-backup=${LAST_BACKUP}"
    echo "Last backup: ${LAST_BACKUP}"
else
    echo "Using provided backup selector: ${BACKUP_SELECTOR}"
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
