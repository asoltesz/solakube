#!/usr/bin/env bash

# ==============================================================================
#
# Restores a backup from the S3 or local repository (optionally, point-in time).
#
# Works on the currently selected cluster (PGO_CURRENT_CLUSTER).
#
# 1 - The name of the PGO cluster (e.g.: "default")
#
# 2 - Backup storage type ("local" or "s3", defaults to "s3")
#
# 3 - Point In Time target (e.g.: "2020-06-07 19:20:00.000000-02")
#     Optional. If empty, the latest state will be restored
#
# 4 - Timeout to wait in seconds (deafults to 600 (10 minutes))
# ==============================================================================

# Stop immediately if any of the deployments fail
trap errorHandler ERR

DB_CLUSTER=${1:-"default"}

BACKUP_STORAGE_TYPE=${2:-"s3"}

PITR_TARGET="${3}"

TIMEOUT="${4:-600}"

# If a non-default cluster is selected, variables need to be imported
if [[ ${DB_CLUSTER} != "default" ]]
then
    importPgoClusterVariables "${DB_CLUSTER}"
fi

# Configuring cluster defaults if not everything is specified
setPgoClusterDefaults "${DB_CLUSTER}"

if [[ ${PITR_TARGET} ]]
then
    PITR_CLAUSE="--pitr-target=\"${PITR_TARGET}\""
    OPTS_CLAUSE="--backup-opts=--type=time"
fi

cexport CLUSTER_NAME "${PGO_CLUSTER_NAME}"

echoSection "Starting: Restore for the '${PGO_CLUSTER_NAME}' PG cluster"
echo "Backup locations: ${BACKUP_STORAGE_TYPE}"
echo "PITR clause (if any): ${BACKUP_TYPE}"


# Postgres pods get minimum 256 MB RAM and 200 milli CPU
# Minio only supports URI-style bucket paths (as opposed to subdomain-style)
CMD="       restore ${PGO_CLUSTER_NAME}"
CMD="${CMD}    --pgbackrest-storage-type="${BACKUP_STORAGE_TYPE}""
CMD="${CMD}    ${PITR_CLAUSE}"
CMD="${CMD}    ${OPTS_CLAUSE}"

# Executing the command via the PGO client
${SK_SCRIPT_HOME}/sk pgo exec "${CMD}"

WORKFLOW_ID=$(getWorkflowId "${PGO_CLUSTER_NAME}-pgbackrestrestore")
if [[ ! ${WORKFLOW_ID} ]]
then
    echo "Couldn't find the workflow ID for cluster create pgTask"
    exit 1
else
    echo "PGO Workflow ID: ${WORKFLOW_ID}"
fi

waitForWorkflow ${WORKFLOW_ID} "restored Primary created" ${TIMEOUT}
success=$?

if [[ ! ${success} ]]
then
    echo
    echo "ERROR: The restore operation has NOT finished for ${TIMEOUT} seconds"
    echo "Check the workflow manually."
    echo
fi


# ------------------------------------------------------------
echoSection "Finished: Restore for the '${PGO_CLUSTER_NAME}' PG cluster"

exit ${success}