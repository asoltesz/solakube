#!/usr/bin/env bash


#
# Waits until the workflow is ended or the timeout is passed
#
# 1 - Workflow ID
# 2 - Workflow message for the completion of the processing
# 3 - Timeout in seconds (defaults to 120 seconds)
#
function waitForWorkflow() {

    local flowId=$1
    local completionMessage=$2
    local timeout=${3:-120}

    local checkInterval=5

    local startTime=$(date +%s)
    local limit=$(( ${startTime} + ${timeout} ))

    echo "Waiting for PGO workflow completion"

    local now=$(date +%s)

    while (( ${now} < ${limit} ))
    do
        local result=$(${SK_SCRIPT_HOME}/sk pgo client show workflow ${flowId} | grep "${completionMessage}")

        if [[ "${result}" ]]
        then
            echo "Completion message found in workflow"
            return 0
        fi

        echo "waiting ${checkInterval}s ..."
        sleep ${checkInterval}s
        now=$(date +%s)
    done

    echo "Timeout passed (${timeout}). Stopping checking attempts. Check failed."
    return 1

}


#
# Returns the workflow id for a pgTask name
#
# 1 - pgTask name (e.g.: "default-createcluster")
#
function getWorkflowId() {

    local taskName=$1

    echo "$(
        kubectl get pgtask \
          --no-headers \
          -o=custom-columns=ID:.spec.parameters.workflowid \
          --field-selector=metadata.name=${taskName} \
          --namespace=pgo
     )"
}


#
# Waits until pgtask is completed or the timeout is passed
#
# 1 - pgtask name
# 2 - Timeout in seconds (defaults to 120 seconds)
#
function waitForPgTask() {

    local taskName=$1
    local timeout=${2:-120}

    local completionMessage="job completed"

    local checkInterval=5

    local startTime=$(date +%s)
    local limit=$(( ${startTime} + ${timeout} ))

    echo "Waiting for completion of pgTask '${taskName}'"

    local now=$(date +%s)

    while (( ${now} < ${limit} ))
    do
        local result=$(\
            kubectl get pgtask \
              --no-headers \
              -o=custom-columns=ID:.spec.status \
              --field-selector=metadata.name=${taskName} \
              --namespace=pgo)

         echo "status: ${result}"

        if [[ "${result}" == "${completionMessage}" ]]
        then
            echo "Completion message found in pgtask"
            return 0
        fi

        echo "waiting ${checkInterval}s ..."
        sleep ${checkInterval}s
        now=$(date +%s)
    done

    echo "Timeout passed (${timeout}). Stopping checking attempts. Check failed."
    return 1

}

#
# Checks the storage class preferences and selects the best storage class
# for the DB pods and other pod types
#
checkPgoStorageClasses() {

    # Storage class preferences for the database pods
    # These should be on the fastest storage possible

    DB_PREF_CLASSES="openebs-hostpath,rook-ceph-block,hcloud-volume,standard"

    checkStorageClass "pgo_cluster_primary" ${DB_PREF_CLASSES}
    checkStorageClass "pgo_cluster_replica" ${DB_PREF_CLASSES}

    # Storage class preferences for the non-database pods
    # These should be on HA storage whenever possible

    OTHER_PREF_CLASSES="rook-ceph-block,hcloud-volume,standard"

    checkStorageClass "pgo_cluster_backrest" ${OTHER_PREF_CLASSES}
    checkStorageClass "pgo_cluster_backup" ${OTHER_PREF_CLASSES}
    checkStorageClass "pgo_cluster_wal" ${OTHER_PREF_CLASSES}

    echo "--------"
    echo "Selected storage classes:"

    echo "  Primary: ${PGO_CLUSTER_PRIMARY_STORAGE_CLASS}"
    echo "  Replica: ${PGO_CLUSTER_REPLICA_STORAGE_CLASS}"
    echo "  Backrest: ${PGO_CLUSTER_BACKREST_STORAGE_CLASS}"
    echo "  WAL: ${PGO_CLUSTER_WAL_STORAGE_CLASS}"
    echo "--------"
}


#
# Normalizes cluster config variables by removig the cluster name from
# them.
#
# E.g.: PGO_WORDPRESS_CLUSTER_ADMIN_PASSWORD >> PGO_CLUSTER_ADMIN_PASSWORD
#
# This should never be called for the "default" cluster since the variables
# for that never need normalizing/shortening.
#
# 1 - Name of the cluster (e.g.: 'nextcloud')
#
function importPgoClusterVariables {

    local cluster=$1

    local prefix="${cluster^^}"

    normalizeVariable "PGO_CLUSTER_NAME" ${prefix}
    normalizeVariable "PGO_CLUSTER_REPLICA_COUNT" ${prefix}
    normalizeVariable "PGO_CLUSTER_APP_USERNAME" ${prefix}
    normalizeVariable "PGO_CLUSTER_APP_PASSWORD" ${prefix}
    normalizeVariable "PGO_CLUSTER_ADMIN_PASSWORD" ${prefix}
    normalizeVariable "PGO_CLUSTER_MEMORY" ${prefix}
    normalizeVariable "PGO_CLUSTER_MEMORY_LIMIT" ${prefix}
    normalizeVariable "PGO_CLUSTER_CPU" ${prefix}
    normalizeVariable "PGO_CLUSTER_CPU_LIMIT" ${prefix}
    normalizeVariable "PGO_CLUSTER_BACKUP_LOCATIONS" ${prefix}
    normalizeVariable "PGO_CLUSTER_S3_ACCESS_KEY" ${prefix}
    normalizeVariable "PGO_CLUSTER_S3_SECRET_KEY" ${prefix}
    normalizeVariable "PGO_CLUSTER_S3_BUCKET" ${prefix}
    normalizeVariable "PGO_CLUSTER_S3_ENDPOINT" ${prefix}
    normalizeVariable "PGO_CLUSTER_S3_REGION" ${prefix}
    normalizeVariable "PGO_CLUSTER_PRIMARY_STORAGE_CLASS" ${prefix}
    normalizeVariable "PGO_CLUSTER_PRIMARY_STORAGE_SIZE" ${prefix}
    normalizeVariable "PGO_CLUSTER_REPLICA_STORAGE_CLASS" ${prefix}
    normalizeVariable "PGO_CLUSTER_BACKREST_STORAGE_CLASS" ${prefix}
    normalizeVariable "PGO_CLUSTER_BACKREST_STORAGE_SIZE" ${prefix}
    normalizeVariable "PGO_CLUSTER_WAL_STORAGE_CLASS" ${prefix}
    normalizeVariable "PGO_CLUSTER_WAL_STORAGE_SIZE" ${prefix}
    normalizeVariable "PGO_CLUSTER_CREATE_EXTRA_OPTIONS" ${prefix}
}

#
# Setting minimal cluster defaults if not set
#
# 1 - The name of the cluster in SolaKube (if possible to provide)
#
function setPgoClusterDefaults {

    local cluster=$1

    cexport "PGO_CLUSTER_NAME" "${cluster}"

    cexport "PGO_CLUSTER_NAME" "${PGO_CURRENT_CLUSTER}"
    cexport "PGO_CLUSTER_NAME" "default"

    cexport PGO_CLUSTER_MEMORY "256Mi"
    # No memory limit will be set

    cexport PGO_CLUSTER_CPU "300m"
    # No CPU limit will be set

    # A single primary, no replicas
    cexport PGO_CLUSTER_REPLICA_COUNT "0"

    cexport PGO_ADMIN_PASSWORD "${SK_ADMIN_PASSWORD}"

    cexport PGO_CLUSTER_APP_USERNAME "${PGO_CLUSTER_NAME}"
    cexport PGO_CLUSTER_APP_PASSWORD "${PGO_ADMIN_PASSWORD}"

    cexport PGO_CLUSTER_ADMIN_PASSWORD "${PGO_ADMIN_PASSWORD}"
}

#
# Eports the access variables for a PGO-managed cluster in a way, the main
# SolaKube postgres API expects it.
#
# - POSTGRES_<cluster>_SERVICE_HOST
# - POSTGRES_<cluster>_NAMESPACE
# - POSTGRES_<cluster>_ADMIN_USERNAME
# - POSTGRES_<cluster>__ADMIN_PASSWORD
#
# This can be used by other SolaKube services (e.g.: deployers) to get hold of
# information about how to access a cluster with admin privileges.
#
# 1 - Name of the cluster in SolaKube (defaults to "default")
#
function exportPgoClusterAccessVars {

    local cluster=${1:-"default"}

    # If a non-default cluster is
    if [[ ${cluster} != "default" ]]
    then
        importPgoClusterVariables "${cluster}"
    fi

    setPgoClusterDefaults "${cluster}"

    echo "Exporting common Postgres access vars for PGO cluster '${cluster}'"

    export POSTGRES_SERVICE_HOST="${PGO_CLUSTER_NAME}.pgo"
    export POSTGRES_NAMESPACE="pgo"

    export POSTGRES_ADMIN_USERNAME="postgres"
    export POSTGRES_ADMIN_PASSWORD="${PGO_CLUSTER_ADMIN_PASSWORD}"

}

#
# Whether a PGO cluster already exists
#
#
# 1 - The cluster name within PGO
#
function pgoClusterExists() {

    local pgoCluster=$1

    echo "Checking the Primary Database pod in the pgo namespace for ${pgoCluster}"

    # Querying the PGO client CLI pod
    local podName=$(kubectl get pods \
                      --selector="deployment-name=${pgoCluster}" \
                      --output=jsonpath={.items..metadata.name} \
                      --namespace "pgo" \
                      --no-headers
                    )

    if [[ "${podName}" ]]
    then
        # PGO-operated DB cluster exists
        return
    fi

    false
}



#
# Checks if a SolaKube named cluster exists in PGO
#
# If it doesn't exist, it tries to create it
#
# 1 - The SolaKube name of the DB cluster
#
function ensurePgoCluster() {

    local cluster=$1

    local varName="PGO_CLUSTER_NAME"

    if [[ ${cluster} != "default" ]]
    then
        varName="${cluster^^}_${varName}"
    fi

    pgoCluster=${!varName}
    pgoCluster=${pgoCluster:-"${cluster}"}

    if pgoClusterExists "${pgoCluster}"
    then
        return
    fi

    # PGO-operated DB cluster doesn't exist, we need to create it

    export PGO_CURRENT_CLUSTER="${cluster}"

    . ${SK_SCRIPT_HOME}/pgo/create-cluster.sh "${cluster}"

    if [[ $? != 0 ]]
    then
        echo "ERROR: PGO Postgres database creation failed."
        return 1
    fi
}
