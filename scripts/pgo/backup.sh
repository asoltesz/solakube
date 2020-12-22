#!/usr/bin/env bash

# ==============================================================================
#
# Takes a backup from the pre-configured cluster with pgBackrest.
#
# Works on the currently selected cluster (PGO_CURRENT_CLUSTER).
#
# Parameters:
#
# 1 - The name of the PGO cluster (e.g.: "default")
#
# 2 - Backup storage type ("local" or "s3" or "local,s3",
#     defaults to "PGO_CLUSTER_BACKUP_LOCATIONS" and then to "s3"
#
# 3 - Backup type ("full" or "incr" or "diff", defaults to "incr")
#
# 4 - timeout to track in seconds (deafults to 600 (10 minutes))
#     after the timeout SK stops tracking the backup progress
#
# The backup command will NOT include retention settings so no older backups
# will be removed (as opposed to scheduled backups).
#
# The first backup in the repo is always "full" regardless of the parameter.
#
# This is intended for manual use.
# ==============================================================================

# Stop immediately if any of the deployments fail
trap errorHandler ERR

DB_CLUSTER=${1:-"default"}

BACKUP_STORAGE_TYPE=${2}

BACKUP_TYPE=${3}
cexport BACKUP_TYPE "incr"

TIMEOUT="${4:-600}"

if [[ -z $(echo ":s3:local:local,s3:" | grep ":${BACKUP_STORAGE_TYPE}:") ]]
then
    echo "FATAL: Unsupported backup storage type: ${BACKUP_STORAGE_TYPE}"
    exit 1
fi


# If a non-default cluster is selected, variables need to be imported
if [[ ${DB_CLUSTER} != "default" ]]
then
    importPgoClusterVariables "${DB_CLUSTER}"
fi

# Configuring cluster defaults if not everything is specified
setPgoClusterDefaults "${DB_CLUSTER}"

cexport BACKUP_STORAGE_TYPE "${PGO_CLUSTER_BACKUP_LOCATIONS}"
cexport BACKUP_STORAGE_TYPE "s3"

cexport CLUSTER_NAME "${PGO_CLUSTER_NAME}"

echoSection "Starting: Backup for the '${CLUSTER_NAME}' PG cluster"
echo "Backup locations: ${BACKUP_STORAGE_TYPE}"
echo "Backup type: ${BACKUP_TYPE}"

COMMAND=$(cat <<-EOF
  backup ${CLUSTER_NAME} \
  --pgbackrest-storage-type=${BACKUP_STORAGE_TYPE} \
  --backup-opts="--type=${BACKUP_TYPE}"
EOF
)

# Executing the command
${SK_SCRIPT_HOME}/sk pgo exec "${COMMAND}"


waitForPgTask "backrest-backup-${CLUSTER_NAME}" ${TIMEOUT}
success=$?


if [[ ! ${success} ]]
then
    echo
    echo "ERROR: The restore operation has NOT finished for ${TIMEOUT} seconds"
    echo "Check the workflow manually."
    echo
fi

# ------------------------------------------------------------
echoSection "Finished: Backup for the '${CLUSTER_NAME}' PG cluster"

exit ${success}
