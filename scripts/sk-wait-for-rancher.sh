#!/usr/bin/env bash

#-------------------------------------------------------------------------------
#
# Waits until the Rancher API becomes available for the cluster which means
# the all RKE provisioning/update operations have finished.
#
#-------------------------------------------------------------------------------


checkNodesWithTimeout() {

    # Maximum timeout for the cluster provisioning: 30 minutes
    local timeout=1500

    local startTime=$(date +%s)
    local limit=$(( ${startTime} + ${timeout} ))

    local issued="N"

    while (( $(date +%s) < ${limit} ))
    do
        # Attempting to list the nodes
        # error messages dropped, they are expected here
        kubectl get nodes 2> /dev/null

        if [[ $? == 0 ]]
        then
            echo "The nodes in the cluster: "
            kubectl get nodes
            return 0
        fi

        # "Check unsuccessful. Maybe cluster is still provisioning. Waiting"
        local currTime=$(date +%s)
        echo "waiting ... (at $(($currTime - $startTime))s )"
        sleep 30s
    done

    return 1
}

# ------------------------------------------------------------
# Stop immediately if any of the operations fail

echoHeader "Waiting for Rancher to finish with the provisioning/updating of the cluster"

echoSection "Validating parameters"

checkRancherAccessParams
if [[ $? != 0 ]]
then
    exit 1
fi

# ------------------------------------------------------------

echoSection "Testing kubectl with a node query"

checkNodesWithTimeout
if [[ $? != 0 ]]
then
    exit 1
fi
