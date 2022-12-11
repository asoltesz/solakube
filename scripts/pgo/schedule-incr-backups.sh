#!/usr/bin/env bash

# ==============================================================================
#
# Schedules automated, FULL pgBackrest backups for the currently selected
# cluster (PGO_CURRENT_CLUSTER).
#
# ==============================================================================

# Stop immediately if any of the deployments fail
trap errorHandler ERR

CLUSTER=${1:-"${PGO_CURRENT_CLUSTER}"}
CLUSTER=${CLUSTER:-"default"}

echo "Selected cluster: ${CLUSTER}"

# If a non-default cluster is selected, variables need to be imported
if [[ ${CLUSTER} != "default" ]]
then
    importPgoClusterVariables "${CLUSTER}"
fi

# Configuring cluster defaults if not everything is specified
setPgoClusterDefaults "${CLUSTER}"

BACKUP_STORAGE_TYPE="${PGO_CLUSTER_BACKUP_SCHEDULED_LOCATIONS}"
cexport BACKUP_STORAGE_TYPE "${PGO_CLUSTER_BACKUP_LOCATIONS}"
cexport BACKUP_STORAGE_TYPE "s3"

INCR_SCHEDULE="${PGO_CLUSTER_BACKUP_INCR_SCHEDULE}"

if [[ ! "${INCR_SCHEDULE}" ]]
then
    echo "ERROR: Cron schedule is not provided for incremental backups (PGO_CLUSTER_BACKUP_INCR_SCHEDULE)"
    exit 1
fi

echoSection "Scheduling Incremental backups for the '${PGO_CLUSTER_NAME}' PG cluster"

# Defaulting for every Monday


COMMAND=$(cat <<-END
  create schedule ${PGO_CLUSTER_NAME} \
  --schedule='${INCR_SCHEDULE}' \
  --schedule-type=pgbackrest \
  --pgbackrest-backup-type=incr \
  --pgbackrest-storage-type=${BACKUP_STORAGE_TYPE}
END
)

# Executing the command
. ${SK_SCRIPT_HOME}/pgo/exec.sh "${COMMAND}"


# ------------------------------------------------------------
echoSection "Finished scheduling Incremental backups for the '${PGO_CLUSTER_NAME}' PG cluster"

exit ${success}
