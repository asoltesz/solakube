#!/usr/bin/env bash

#
# Normalizes a single config variable
#
# 1 - variable name
# 2 - prefix
#
function normalizeVariable {

    local varName=$1
    local prefix=$2

    local var="${prefix}_${varName}"

    # echo "Normalizing: $var (${!var})"

    export ${varName}=${!var}
    # echo "Exported: $varName (${!varName})"
}


#
# Normalizes disaster recovery config/profile variables
#
# E.g.: NEXTCLOUD_PROFILE1_BACKUP_REPO_TYPE >> BACKUP_REPO_TYPE
#
# Or, for the 'default' profile:
# E.g.: NEXTCLOUD_BACKUP_REPO_TYPE >> BACKUP_REPO_TYPE
#
# 1 - Name of the application ('nextcloud')
# 2 - Name of the profile ('profile1')
#
function normalizeConfigVariables {

    local application=$1
    local profile=$2

    local prefix="${application^^}"
    if [[ "${profile}" != "default" ]]
    then
        prefix="${prefix}_${profile}^^"
    fi

    export BACKUP_PROFILE_NAME="${profile}"

    normalizeVariable "BACKUP_LOCATION_NAME" ${prefix}

    normalizeVariable "BACKUP_SCHEDULE_DAILY" ${prefix}
    normalizeVariable "BACKUP_SCHEDULE_MONTHLY" ${prefix}
    normalizeVariable "BACKUP_SCHEDULE_YEARLY" ${prefix}

    normalizeVariable "BACKUP_RETENTION_DAILY" ${prefix}
    normalizeVariable "BACKUP_RETENTION_MONTHLY" ${prefix}
    normalizeVariable "BACKUP_RETENTION_YEARLY" ${prefix}

    normalizeVariable "BACKUP_NAMESPACE" ${prefix}
}


#
# Applies generic defaults for an application and backup profile for the
# following variables:
#
# - BACKUP_NAMESPACE
# - BACKUP_LOCATION_NAME
# - BACKUP_SCHEDULE_*
# - BACKUP_RETENTION_*
#
# These are applicable for both filesystem and volumesnapshot backups.
#
# 1 - Name of the application ('nextcloud')
# 2 - Name of the profile ('profile1')
#
function applyDefaults() {

    local application=${1}
    local profile=${2}

    cexport BACKUP_NAMESPACE "${application}"


    # The backup repository name to be used
    cexport BACKUP_LOCATION_NAME "default"

    # Backup retention & scheduling settings

    cexport BACKUP_RETENTION_DAILY 30
    cexport BACKUP_RETENTION_MONTHLY 6
    cexport BACKUP_RETENTION_YEARLY 0

    # Every day, 01:00 in the morning
    cexport BACKUP_SCHEDULE_DAILY "0 1 * * *"
    # First day of the month, 03:00 in the morning
    cexport BACKUP_SCHEDULE_MONTHLY "0 3 1 * *"
    # First day of the year, 05:00 in the morning
    cexport BACKUP_SCHEDULE_YEARLY "0 5 1 1 *"

}



#
# Validates mandatory variables for an application and backup profile
#
# 1 - Name of the application ('nextcloud')
# 2 - Name of the profile ('profile1')
#
function validateVariables() {

    local application=${1}
    local profile=${2}

}

#
# Checks if the Velero backup location named by the application backup profile
# exists.
#
# It expects the following normalized backup variables to be present:
# - BACKUP_LOCATION_NAME
# - BACKUP_BUCKET_NAME
# - BACKUP_BUCKET_PREFIX
# - BACKUP_S3_ENDPOINT
# - BACKUP_S3_REGION
#
function checkBackupLocationExists() {

    # Check if the backup location is the default
    if [[ ! ${BACKUP_LOCATION_NAME} ]] || [[ ${BACKUP_LOCATION_NAME} == "default" ]]
    then
        return
    fi

    # If it is not the default, check if the backup location exists
    local description="$(\
        kubectl describe backupstoragelocation \
        ${BACKUP_LOCATION_NAME} -n velero  2> /dev/null)"

    if [[ ! "${description}" ]]
    then
        echo "ERROR: Can't find backup location '${BACKUP_LOCATION_NAME}' in the velero namespace"
        return 1
    fi
}


#
# Executes a backup immediately.
#
# PVCs will NOT be snapshotted but processed by Restic in order to be offsite.
#
# The backup location must be created before this is called.
#
# Expects all of the BACKUP_* normalized variables to be present
#
executeApplicationBackup() {

    export BACKUP_TIMEDATE=$(date +%Y%m%d-%H%M)

    velero backup create ${BACKUP_NAME}-${BACKUP_TIMEDATE} \
        --include-namespaces=${BACKUP_NAMESPACE} \
        --storage-location=${BACKUP_LOCATION_NAME} \
        --snapshot-volumes=false \
        --wait
}


#
# Schedules a backup for later execution.
#
# PVCs will NOT be snapshotted but processed by Restic in order to be offsite.
#
# The backup location must be created before this is called.
#
# Creates a separate schedule for daily, monthly, yearly backups with separate
# retention
#
# Expects all of the BACKUP_* normalized variables to be present
#
scheduleApplicationBackup() {

    if [[ ${BACKUP_RETENTION_DAILY} != 0 ]]
    then
        velero schedule create ${BACKUP_NAME}-daily \
            --include-namespaces=${BACKUP_NAMESPACE} \
            --storage-location=${BACKUP_LOCATION_NAME} \
            --snapshot-volumes=false \
            --ttl=$(( 24 * ${BACKUP_RETENTION_DAILY} ))h0m0s \
            --schedule="${BACKUP_SCHEDULE_DAILY}"

    fi

    if [[ ${BACKUP_RETENTION_MONTHLY} != 0 ]]
    then
        velero schedule create ${BACKUP_NAME}-monthly \
            --include-namespaces=${BACKUP_NAMESPACE} \
            --storage-location=${BACKUP_LOCATION_NAME} \
            --snapshot-volumes=false \
            --ttl="$(( 24 * 31 * ${BACKUP_RETENTION_MONTHLY} ))"h0m0s \
            --schedule="${BACKUP_SCHEDULE_MONTHLY}"
    fi

    if [[ ${BACKUP_RETENTION_YEARLY} != 0 ]]
    then
        velero schedule create ${BACKUP_NAME}-yearly \
            --include-namespaces=${BACKUP_NAMESPACE} \
            --storage-location=${BACKUP_LOCATION_NAME} \
            --snapshot-volumes=false \
            --ttl="$(( 24 * 365 ${BACKUP_RETENTION_YEARLY} ))"h0m0s \
            --schedule="${BACKUP_SCHEDULE_YEARLY}"
    fi

}

#
# Set the access mode on a Velero BackupStorageLocation
#
# 1 - name of the backup location
# 2 - the access mode (ReadOnly, ReadWrite)
#
setLocationAccessMode() {

    local backupLocationName=$1
    local accessMode=$2

    kubectl patch backupstoragelocation ${backupLocationName} \
        --namespace velero \
        --type merge \
        --patch "{\"spec\":{\"accessMode\":\"${accessMode}\"}}"
}