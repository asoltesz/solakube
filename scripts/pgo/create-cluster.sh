#!/usr/bin/env bash

# ==============================================================================
#
# Installs the CrunchyData Postgres Operator and then deploys the pre-configured
# Postgres Database cluster see PGO_CLUSTER_xxx variables.
#
# 1 - Restore from S3 backups
#     - "Y" - yes, restoring from backups
#     - everything else - no
# 2 - timeout to wait in seconds (deafults to 600 (10 minutes))
# ==============================================================================

RESTORE_FROM_S3=${1}
TIMEOUT="${2:-600}"

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoSection "Creating: CrunchyData PG cluster (hippo)"

# Selecting storage classes in case they are not configured
checkPgoStorageClasses


if [[ ${RESTORE_FROM_S3} == "Y" ]]
then
    echo "WARNING: Restoring cluster data from the last S3 state (backup + WAL entries)"
    echo "Make sure that no active PG cluster is using the backup storage"
    echo "configured for this cluster."
    read -p "Press any key to resume ..."
fi

cexport CLUSTER_NAME "${PGO_CLUSTER_NAME}"
cexport CLUSTER_NAME "hippo"

cexport PGO_CLUSTER_MEMORY "256Mi"
cexport PGO_CLUSTER_CPU "300m"
cexport PGO_CLUSTER_REPLICA_COUNT "0"

cexport PGO_ADMIN_PASSWORD "${SK_ADMIN_PASSWORD}"
cexport POSTGRES_ADMIN_USERNAME "${PGO_CLUSTER_NAME}"
cexport POSTGRES_ADMIN_PASSWORD "${PGO_ADMIN_PASSWORD}"


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


STANDBY_CLAUSE=""
if [[ ${RESTORE_FROM_S3} == "Y" ]]
then
    STANDBY_CLAUSE="--standby"
fi

REPO_PATH_CLAUSE=""
if [[ ${RESTORE_FROM_S3} == "Y" ]]
then
    cexport PGO_CLUSTER_S3_REPO_PATH "/backrestrepo/${CLUSTER_NAME}-backrest-shared-repo"
    REPO_PATH_CLAUSE="--pgbackrest-repo-path=${PGO_CLUSTER_S3_REPO_PATH}"
fi

COMMAND=$(cat <<-END
  create cluster ${CLUSTER_NAME} \
    ${STANDBY_CLAUSE} \
    --replica-count=${PGO_CLUSTER_REPLICA_COUNT} \
    --username=${POSTGRES_ADMIN_USERNAME} \
    --password=${POSTGRES_ADMIN_PASSWORD} \
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
${SK_SCRIPT_HOME}/sk pgo client "${COMMAND}"


WORKFLOW_ID=$(getWorkflowId "${CLUSTER_NAME}-createcluster")
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


if [[ ${RESTORE_FROM_S3} == "Y" ]]
then
    echo
    echo
    echo "--------"
    echo "WARNING: Cluster creating by restoring from backups:"
    echo "--------"
    echo "After the cluster has been successfully restored"
    echo "you will need to manually promote it from standy state to normal"
    echo "with the PGO client CLI:"
    echo
    echo "pgo update cluster ${CLUSTER_NAME} --promote-standby"
    echo
    echo "---------"
fi



# ------------------------------------------------------------
echoSection "Created: CrunchyData PG cluster (hippo)"

exit ${success}