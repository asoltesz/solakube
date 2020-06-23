#!/usr/bin/env bash

# ==============================================================================
#
# Schedules automated, FULL pgBackrest backups for the cluster.
#
# ==============================================================================

# Stop immediately if any of the deployments fail
trap errorHandler ERR

BACKUP_STORAGE_TYPE="${PGO_CLUSTER_BACKUP_SCHEDULED_LOCATIONS}"
cexport BACKUP_STORAGE_TYPE "${PGO_CLUSTER_BACKUP_LOCATIONS}"
cexport BACKUP_STORAGE_TYPE "s3"

cexport CLUSTER_NAME "${PGO_CLUSTER_NAME}"
cexport CLUSTER_NAME "hippo"

INCR_SCHEDULE="${PGO_CLUSTER_BACKUP_INCR_SCHEDULE}"

if [[ ! "${INCR_SCHEDULE}" ]]
then
    echo "ERROR: Cron schedule is not provided for incremental backups (PGO_CLUSTER_BACKUP_INCR_SCHEDULE)"
    exit 1
fi

echoSection "Scheduling Incremental backups for the '${CLUSTER_NAME}' PG cluster"

# Defaulting for every Monday


COMMAND=$(cat <<-END
  create schedule ${CLUSTER_NAME} \
  --schedule="${INCR_SCHEDULE}" \
  --schedule-type=pgbackrest \
  --pgbackrest-backup-type=incr
END
)

# Executing the command
${SK_SCRIPT_HOME}/sk pgo client "${COMMAND}"


# ------------------------------------------------------------
echoSection "Finished scheduling Incremental backups for the '${CLUSTER_NAME}' PG cluster"

exit ${success}
