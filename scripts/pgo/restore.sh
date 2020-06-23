#!/usr/bin/env bash

# ==============================================================================
#
# Restores a backup from the S3 or local repository (optionally, point-in time).
#
# 1 - Backup storage type ("local" or "s3", defaults to "s3")
# 2 - Point In Time target (e.g.: "2020-06-07 19:20:00.000000-02")
#     Optional. If empty, the latest state will be restored
# 3 - Timeout to wait in seconds (deafults to 600 (10 minutes))
# ==============================================================================

# Stop immediately if any of the deployments fail
trap errorHandler ERR


BACKUP_STORAGE_TYPE=${1}
cexport BACKUP_STORAGE_TYPE "s3"

PITR_TARGET="${2}"

if [[ ${PITR_TARGET} ]]
then
    PITR_CLAUSE="--pitr-target=\"${PITR_TARGET}\""
    OPTS_CLAUSE="--backup-opts=--type=time"
fi

TIMEOUT="${3:-600}"

cexport CLUSTER_NAME "${PGO_CLUSTER_NAME}"
cexport CLUSTER_NAME "hippo"

echoSection "Starting: Restore for the '${CLUSTER_NAME}' PG cluster"

# Postgres pods get minimum 256 MB RAM and 200 milli CPU
# Minio only supports URI-style bucket paths (as opposed to subdomain-style)
CMD="       restore ${PGO_CLUSTER_NAME}"
CMD="${CMD}    --pgbackrest-storage-type="${BACKUP_STORAGE_TYPE}""
CMD="${CMD}    ${PITR_CLAUSE}"
CMD="${CMD}    ${OPTS_CLAUSE}"

# Executing the command via the PGO client
${SK_SCRIPT_HOME}/sk pgo client "${CMD}"

WORKFLOW_ID=$(getWorkflowId "${CLUSTER_NAME}-pgbackrestrestore")
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
echoSection "Finished: Restore for the '${CLUSTER_NAME}' PG cluster"

exit ${success}