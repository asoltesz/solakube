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
# 1 - pgTask name (e.g.: "hippo-createcluster")
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