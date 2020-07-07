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

    normalizeVariable "BACKUP_REPO_NAME" ${prefix}
    normalizeVariable "BACKUP_REPO_BUCKET_NAME" ${prefix}
    normalizeVariable "BACKUP_S3_ENDPOINT" ${prefix}
    normalizeVariable "BACKUP_S3_ACCESS_KEY" ${prefix}
    normalizeVariable "BACKUP_S3_SECRET_KEY" ${prefix}
    normalizeVariable "BACKUP_REPO_PREFIX" ${prefix}

    normalizeVariable "BACKUP_SCHEDULE" ${prefix}
    normalizeVariable "BACKUP_DEPLOYMENT_NAME" ${prefix}
    normalizeVariable "BACKUP_DATA_FOLDER_PATH" ${prefix}
    normalizeVariable "BACKUP_DATA_VOLUME_NAME" ${prefix}
    normalizeVariable "BACKUP_SECURITY_CONTEXT" ${prefix}
    normalizeVariable "BACKUP_RETENTION_POLICY" ${prefix}
    normalizeVariable "BACKUP_NAMESPACE" ${prefix}

    normalizeVariable "BACKUP_SNAPSHOT_CLASS" ${prefix}
    normalizeVariable "BACKUP_PVC_NAME" ${prefix}
    normalizeVariable "BACKUP_PVC_ACCESS_MODES" ${prefix}
    normalizeVariable "BACKUP_PVC_STORAGE_CLASS" ${prefix}
}


#
# Applies generic defaults for an application and backup profile for the
# following variables:
#
# - BACKUP_NAMESPACE
# - BACKUP_REPO_TYPE (b2, s3...etc)
# - BACKUP_REPO_NAME
# - BACKUP_REPO_BUCKET_NAME
# - BACKUP_REPO_PREFIX
# - BACKUP_SCHEDULE
# - BACKUP_RETENTION_POLICY
#
# These are applicable for both filesystem and volumesnapshot backups.
#
# 1 - Name of the application ('nextcloud')
# 2 - Name of the profile ('profile1')
#
function applyGenericDefaults() {

    local application=${1}
    local profile=${2}

    cexport BACKUP_NAMESPACE "${application}"

    # Currently, only the S3 type is supported
    export BACKUP_REPO_TYPE="s3"

    # The backup repository name to be used
    cexport BACKUP_REPO_NAME "${BACKUP_PROFILE_NAME}"

    # The name of the secret
    cexport BACKUP_REPO_SECRET_NAME "stash-repo-${BACKUP_REPO_NAME}"

    # The S3 access parameters (if overridden for Stash backups specifically)
    cexport BACKUP_S3_ENDPOINT "${STASH_S3_ENDPOINT}"
    cexport BACKUP_S3_ACCESS_KEY "${STASH_S3_ACCESS_KEY}"
    cexport BACKUP_S3_SECRET_KEY "${STASH_S3_SECRET_KEY}"
    cexport BACKUP_S3_REGION "${STASH_S3_REGION}"

    # The S3 access parameters (if only the generic ones are set)
    cexport BACKUP_S3_ENDPOINT "${S3_ENDPOINT}"
    cexport BACKUP_S3_ACCESS_KEY "${S3_ACCESS_KEY}"
    cexport BACKUP_S3_SECRET_KEY "${S3_SECRET_KEY}"
    cexport BACKUP_S3_REGION "${S3_REGION}"


    # The backup repository bucket to be used
    if [[ ! ${BACKUP_REPO_BUCKET_NAME} ]]
    then
        if [[ ! ${STASH_REPO_DEFAULT_BUCKET_NAME} ]]
        then
            echo "ERROR: BACKUP_REPO_BUCKET_NAME is not specified and default cannot be found"
            exit 1
        fi
        BACKUP_REPO_BUCKET_NAME="${STASH_REPO_DEFAULT_BUCKET_NAME}"

        DEFAULT_BACKUP_REPO_BUCKET_NAME="Y"

    else
        unset DEFAULT_BACKUP_REPO_BUCKET_NAME
    fi

    # The backup repository folder (prefix) to be used
    if [[ ! ${BACKUP_REPO_PREFIX} ]]
    then
        if [[ ${DEFAULT_BACKUP_REPO_BUCKET_NAME} ]]
        then
            BACKUP_REPO_PREFIX="/${application}-${BACKUP_PROFILE_NAME}"
        else
            BACKUP_REPO_PREFIX="/"
        fi
    fi

    #
    # The backup retention policy
    #
    # Default:
    # - Keep the last one within the day for the last 7 days
    # - Keep the last one within the week for the last 4 weeks
    # - Keep the last one within the month for the last 6 months
    # - Drop everything else
    #
    cexport BACKUP_RETENTION_POLICY "$(cat << EOM
    {
        name: "default",
        keepDaily: 7,
        keepWeekly: 4,
        keepMonthly: 6,
        prune: true
    }
EOM
    )"

    # Every night at 23:00
    cexport BACKUP_SCHEDULE "0 23 * * *"

}


#
# Applies filesystem/Restic specific defaults for an application and
# backup profile for the following variables:
#
# - BACKUP_DEPLOYMENT_NAME
# - BACKUP_SECURITY_CONTEXT
#
# These are only applicable for filesystem/restic backups.
#
# 1 - Name of the application ('nextcloud')
# 2 - Name of the profile ('profile1')
#
function applyFsDefaults() {

    local application=${1}
    local profile=${2}

    # The name of the DeploymentConfig in which the volume is
    # attached that we want to backup
    cexport BACKUP_DEPLOYMENT_NAME "${application}"

    #
    # The backup security context
    #
    # We assume that the target container process runs as root
    # so the backup container must be root also
    #
    cexport BACKUP_SECURITY_CONTEXT "$(cat << EOM
    {
        runAsUser: 0,
        runAsGroup: 0
    }
EOM
    )"
}



#
# Applies volume snapshot specific defaults for an application and
# backup profile.
#
# These are only applicable for volume snapshot backups.
#
# 1 - Name of the application ('nextcloud')
# 2 - Name of the profile ('profile1')
#
function applySnapDefaults() {

    local application=${1}
    local profile=${2}

    # The name of the default snapshot class to take volume snapshots with
    cexport BACKUP_SNAPSHOT_CLASS "${STASH_SNAPSHOT_CLASS}"

    #
    # The default snapshot class to be used when taking a snapshot of a persistent
    # volume. Since Hetzner Cloud Volumes don't support snapshotting, only Rook/Ceph
    # remains as a supported snapshotter
    #
    cexport BACKUP_SNAPSHOT_CLASS "csi-rbdplugin-snapclass"

    # The default PV access mode
    cexport BACKUP_PVC_ACCESS_MODES "ReadWriteOnce"

    # The default storage class

    # Trying to get it from the variable used for deployment
    # This also includes the DEFAULT_STORAGE_CLASS
    checkStorageClass "${application}"
    local envVarName="${application^^}_STORAGE_CLASS"
    cexport BACKUP_PVC_STORAGE_CLASS "${!envVarName}"

}




#
# Validates mandatory filesystem/Restic specific variables for an application and
# backup profile
#
# 1 - Name of the application ('nextcloud')
# 2 - Name of the profile ('profile1')
#
function validateFsVariables() {

    local application=${1}
    local profile=${2}

    # The name of the volume on which the filesystem data (to be backed up) is
    if [[ ! ${BACKUP_DATA_VOLUME_NAME} ]]
    then
        echo "ERROR: BACKUP_DATA_VOLUME_NAME is not specified"
        exit 1
    fi

    # The path of the folder with the data to be backed up
    if [[ ! ${BACKUP_DATA_FOLDER_PATH} ]]
    then
        echo "ERROR: BACKUP_DATA_FOLDER_PATH is not specified"
        exit 1
    fi


}


#
# Validates mandatory volume snapshtot specific variables for an application and
# backup profile
#
# 1 - Name of the application ('nextcloud')
# 2 - Name of the profile ('profile1')
#
function validateSnapVariables() {

    local application=${1}
    local profile=${2}

    # The name of the PVC to snapshot
    if [[ ! ${BACKUP_PVC_NAME} ]]
    then
        echo "ERROR: BACKUP_PVC_NAME is not specified"
        exit 1
    fi

}