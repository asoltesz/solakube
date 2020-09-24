#!/usr/bin/env bash

#
# Returns the private registry for a certain application
#
getPrivateRegistryForApp() {

    local appName=$1

    # Checking if there is an app-specific private registry configured

    local varName="${appName}_PRIVATE_REGISTRY"
    local registry="${!varName}"

    if [[ -n ${registry} ]]
    then
        echo "${registry}"
        return
    fi

    # Checking if there is a global registry configured
    registry="${SK_PRIVATE_REGISTRY}"

    if [[ -n ${registry} ]]
    then
        echo "${registry}"
        return
    fi

    # Checking if the registry namespace exists within the cluster
    if namespaceExists "registry"
    then
        # loading the ClusterIP from the service
        echo "$(kubectl get -o template service/registry-docker-registry \
                        --template {{.spec.clusterIP}} \
                        --namespace registry
        ):5000"
        return
    fi

    # Private registry is not available
    return 1
}