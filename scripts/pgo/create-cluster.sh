#!/usr/bin/env bash

# ==============================================================================
#
# Creates or restores a new, PGO-managed Postgres cluster.
#
# 1 - Name of the cluster for SolaKube variables.
#     Defaults to PGO_CURRENT_CLUSTER, then to "default"
# 2 - Restore from S3 backups
#     - "Y" - yes, restoring from backups
#     - everything else - no
# 3 - timeout to wait in seconds (defaults to 600 (10 minutes))
# ==============================================================================

CLUSTER=${1:-"${PGO_CURRENT_CLUSTER}"}
RESTORE_FROM_S3=${2:-"N"}
TIMEOUT="${3:-600}"

cexport CLUSTER "default"

# Stop immediately if any of the deployments fail
trap errorHandler ERR

# If a non-default cluster is selected, variables need to be imported
if [[ ${CLUSTER} != "default" ]]
then
    importPgoClusterVariables "${CLUSTER}"
fi

# Configuring cluster defaults if not everything is specified
setPgoClusterDefaults "${CLUSTER}"

echoSection "Creating: CrunchyData PG cluster: ${CLUSTER} (${PGO_CLUSTER_NAME})"


# Selecting storage classes in case they are not configured
checkPgoStorageClasses


if [[ ${RESTORE_FROM_S3} == "Y" ]]
then
    if [[ -z ${PGO_CLUSTER_S3_BUCKET} ]]
    then
        echo "FATAL: The S3 bucket is not specified. Cannot restore from S3."
        exit 1
    fi

    echo "WARNING: Restoring cluster data from the last S3 state (backup + WAL entries)"
    echo "Make sure that no active PG cluster is using the backup storage"
    echo "configured for this cluster."
    read -p "Press any key to resume ..."
fi



# If S3 backups are needed for pgBackRest
if [[ ${PGO_CLUSTER_S3_BUCKET} ]]
then
    echo "S3 backup storage location provided"

    cexport PGO_CLUSTER_BACKUP_LOCATIONS "local,s3"

    # Force-overriding in case of restore
    if [[ ${RESTORE_FROM_S3} == "Y" ]]
    then
        export PGO_CLUSTER_BACKUP_LOCATIONS="s3"
    fi

    # Calculating the S3 access parameters if they are not defined
    if [[ ! "${PGO_CLUSTER_S3_ENDPOINT}" ]]
    then
        # Fetching the B2 or default S3 settings
        defineS3AccessParams "PGO_CLUSTER_S3"
    fi

    if [[ ! "${PGO_CLUSTER_S3_ENDPOINT}" ]]
    then
        echo "ERROR: It was not possible to find S3 access defaults for PGO Backrest"
        return 1
    fi
else
    # S3 access params were not provided

    cexport PGO_CLUSTER_BACKUP_LOCATIONS "local"
fi

S3_CA_FILE=~/.solakube/${SK_CLUSTER}/s3-cert-chain.pem

if [[ ${S3_CA_FILE} ]]
then
    echo "Deploying S3 CA cert chain"

    deleteKubeObject "secret" "s3-cert-chain" "pgo"

    kubectl create secret generic s3-cert-chain \
     --from-file="aws-s3-ca.crt=${S3_CA_FILE}" \
     --namespace="pgo"
fi

# Removing the protocol from the S3 endpoint
if [[ "${PGO_CLUSTER_S3_ENDPOINT}" == https://* ]]
then
    export PGO_CLUSTER_S3_ENDPOINT="${PGO_CLUSTER_S3_ENDPOINT:8}"
fi

STANDBY_CLAUSE=""
if [[ ${RESTORE_FROM_S3} == "Y" ]]
then
    STANDBY_CLAUSE="--standby"
fi

REPO_PATH_CLAUSE=""
if [[ ${RESTORE_FROM_S3} == "Y" ]]
then
    cexport PGO_CLUSTER_S3_REPO_PATH "/backrestrepo/${PGO_CLUSTER_NAME}-backrest-shared-repo"
    REPO_PATH_CLAUSE="--pgbackrest-repo-path=${PGO_CLUSTER_S3_REPO_PATH}"
fi




COMMAND=$(cat <<-END
  create cluster ${PGO_CLUSTER_NAME} \
    ${STANDBY_CLAUSE} \
    --replica-count=${PGO_CLUSTER_REPLICA_COUNT} \
    --database=${PGO_CLUSTER_NAME} \
    --username=${PGO_CLUSTER_APP_USERNAME} \
    --password=${PGO_CLUSTER_APP_PASSWORD} \
    --password-replication=${PGO_CLUSTER_ADMIN_PASSWORD} \
    --password-superuser=${PGO_CLUSTER_ADMIN_PASSWORD} \
    --memory=${PGO_CLUSTER_MEMORY} \
    --memory-limit=${PGO_CLUSTER_MEMORY_LIMIT} \
    --cpu=${PGO_CLUSTER_CPU} \
    --cpu-limit=${PGO_CLUSTER_CPU_LIMIT} \
    --pgbackrest-storage-type=${PGO_CLUSTER_BACKUP_LOCATIONS} \
    --pgbackrest-s3-key=${PGO_CLUSTER_S3_ACCESS_KEY} \
    --pgbackrest-s3-key-secret=${PGO_CLUSTER_S3_SECRET_KEY} \
    --pgbackrest-s3-bucket=${PGO_CLUSTER_S3_BUCKET} \
    --pgbackrest-s3-endpoint=${PGO_CLUSTER_S3_ENDPOINT} \
    --pgbackrest-s3-region=${PGO_CLUSTER_S3_REGION} \
    --pgbackrest-s3-ca-secret=s3-cert-chain \
    ${REPO_PATH_CLAUSE} \
    --storage-config=${PGO_CLUSTER_PRIMARY_STORAGE_CLASS} \
    --pvc-size=${PGO_CLUSTER_PRIMARY_STORAGE_SIZE} \
    --replica-storage-config=${PGO_CLUSTER_REPLICA_STORAGE_CLASS} \
    --pgbackrest-storage-config=${PGO_CLUSTER_BACKREST_STORAGE_CLASS} \
    --pgbackrest-pvc-size=${PGO_CLUSTER_BACKREST_STORAGE_SIZE} \
    --wal-storage-config=${PGO_CLUSTER_WAL_STORAGE_CLASS} \
    --wal-storage-size=${PGO_CLUSTER_WAL_STORAGE_SIZE} \
    ${PGO_CLUSTER_CREATE_EXTRA_OPTIONS} \
    --namespace=pgo
END
)

# Executing with the PGO CLI
${SK_SCRIPT_HOME}/sk pgo exec "${COMMAND}"


WORKFLOW_ID=$(getWorkflowId "${PGO_CLUSTER_NAME}-createcluster")
if [[ ! ${WORKFLOW_ID} ]]
then
    echo "Couldn't find the workflow ID for cluster create pgTask"
    exit 1
else
    echo "PGO Workflow ID: ${WORKFLOW_ID}"
fi

waitForWorkflow ${WORKFLOW_ID} "task completed" ${TIMEOUT}
success=$?

if [[ ! ${success} ]]
then
    echo
    echo "ERROR: The cluster create/restore operation has NOT finished for ${TIMEOUT} seconds"
    echo "Check the workflow manually."
    echo
fi

# ------------------------------------------------------------
echoSection "Created: CrunchyData PG cluster ${PGO_CLUSTER_NAME}"


if [[ ${RESTORE_FROM_S3} == "Y" ]]
then
    # Without this it is possible to attempt promoting to primary too early
    # which makes the instance stuck in standby permanently
    echo "Waiting for the standby state to stabilize after restore"
    sleep 60s

    echo
    echo
    echo "--------"
    echo "WARNING: Cluster creation by restoring from backups:"
    echo "--------"
    echo "After the cluster has been successfully restored"
    echo "you will need to manually promote it from standby state to normal"
    echo "with the PGO client CLI:"
    echo
    echo "pgo update cluster ${PGO_CLUSTER_NAME} --promote-standby"
    echo
    echo "You can also execute this with SolaKube's embedded PGO client:"
    echo
    echo "sk pgo exec update cluster ${PGO_CLUSTER_NAME} --promote-standby"
    echo "---------"

else
    # Normal cluster creation, not a restore
    echo "Deploying backup schedules (if defined)"

    if [[ -n "${PGO_CLUSTER_BACKUP_FULL_SCHEDULE}" ]]
    then
        echo "Deploying the full-backup schedule"

        ${SK_SCRIPT_HOME}/sk pgo schedule-full-backups
    else
        echo "NOT Deploying the full-backup schedule (not defined)"
    fi

    if [[ -n "${PGO_CLUSTER_BACKUP_INCR_SCHEDULE}" ]]
    then
        echo "Deploying the incremental-backup schedule"

        ${SK_SCRIPT_HOME}/sk pgo schedule-incr-backups
    else
        echo "NOT Deploying the incremental-backup schedule (not defined)"
    fi
fi


return ${success}