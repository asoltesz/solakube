#!/usr/bin/env bash

# ==============================================================================
#
# Schedules automated, FULL pgBackrest backups for the currently selected
# cluster (PGO_CURRENT_CLUSTER).
#
# ==============================================================================

# Stop immediately if any of the deployments fail
trap errorHandler ERR

# If a non-default cluster is selected, variables need to be imported
if [[ ${PGO_CURRENT_CLUSTER:-"default"} != "default" ]]
then
    importPgoClusterVariables "${PGO_CURRENT_CLUSTER}"
fi

# Configuring cluster defaults if not everything is specified
setPgoClusterDefaults


BACKUP_STORAGE_TYPE="${PGO_CLUSTER_BACKUP_SCHEDULED_LOCATIONS}"
cexport BACKUP_STORAGE_TYPE "${PGO_CLUSTER_BACKUP_LOCATIONS}"
cexport BACKUP_STORAGE_TYPE "s3"

cexport CLUSTER_NAME "${PGO_CLUSTER_NAME}"

FULL_SCHEDULE="${PGO_CLUSTER_BACKUP_FULL_SCHEDULE}"

# Defaulting for the first day of the month if not specified
cexport FULL_SCHEDULE "0 0 1 * *"

# Defaulting to 6 full backups if not specified
cexport PGO_CLUSTER_BACKUP_FULL_RETENTION 6

echoSection "Scheduling Full backups for the '${PGO_CLUSTER_NAME}' PG cluster"

COMMAND=$(cat <<-END
  create schedule ${PGO_CLUSTER_NAME} \
  --schedule="${FULL_SCHEDULE}" \
  --schedule-type=pgbackrest \
  --pgbackrest-backup-type=full \
  --schedule-opts="--repo1-retention-full=${PGO_CLUSTER_BACKUP_FULL_RETENTION}"
END
)
#  --schedule-opts="--db-retention-full=${PGO_CLUSTER_BACKUP_FULL_RETENTION} "


# Executing the command
${SK_SCRIPT_HOME}/sk pgo client "${COMMAND}"


# ------------------------------------------------------------
echoSection "Finished scheduling Full backups for the '${PGO_CLUSTER_NAME}' PG cluster"

exit ${success}
