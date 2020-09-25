#!/usr/bin/env bash

#
# Checks if the base Docker Registry (deployed by the the "registry" deployer)
# is present on the cluster and if so, it exports the PRIVATE_REGISTRY_
# variables according to them.
#
function checkBaseDockerRegistry() {

    # Checking if the registry namespace exists within the cluster
    if ! namespaceExists "registry"
    then
        return
    fi

    # loading the ClusterIP from the service
    local ip="$(kubectl get -o template service/registry-docker-registry \
                    --template {{.spec.clusterIP}} \
                    --namespace registry
    )"

    if [[ -n ${ip} ]]
    then
        export PRIVATE_REGISTRY_FQN="${ip}:5000"
        export PRIVATE_REGISTRY_USERNAME="admin"

        # NOTE: querying the actual password would be better
        # but not clear how, so this is a simplified solution

        cexport PRIVATE_REGISTRY_PASSWORD "${REGISTRY_ADMIN_PASSWORD}"
        cexport PRIVATE_REGISTRY_PASSWORD "${SK_ADMIN_PASSWORD}"

        return
    fi
}

#
# Check if there is any internal registries deployed.
#
# If one is found, its access parametered exported
#
function checkInternalRegistries() {

    # Docker registry deployed via the "registry" SolaKube deployer
    checkBaseDockerRegistry
}



#
# Exports the private registry variables for a certain application.
#
# It doesnt throw an error even if there is no private registry configured
#
# 1 - appname
#
function exportPrivateRegistryAccessForApp() {

    local appName=$1

    # Checking if there is an app-specific private registry configured

    local varName="${appName}_PRIVATE_REGISTRY_FQN"
    local registry="${!varName}"

    if [[ -n ${registry} ]]
    then
        # The app has a specific registry defined for it

        export PRIVATE_REGISTRY_FQN="${registry}"

        varName="${appName}_PRIVATE_REGISTRY_USERNAME"
        export PRIVATE_REGISTRY_USERNAME="${!varName}"

        varName="${appName}_PRIVATE_REGISTRY_PASSWORD"
        export PRIVATE_REGISTRY_PASSWORD="${!varName}"

        return
    fi

    # Checking if there is a SolaKube-global registry configured
    if [[ -n ${DEFAULT_PRIVATE_REGISTRY_FQN} ]]
    then
        export PRIVATE_REGISTRY_FQN="${DEFAULT_PRIVATE_REGISTRY_FQN}"
        export PRIVATE_REGISTRY_USERNAME="${DEFAULT_PRIVATE_REGISTRY_USERNAME}"
        export PRIVATE_REGISTRY_PASSWORD="${DEFAULT_PRIVATE_REGISTRY_PASSWORD}"

        return
    fi

    # Checking if there is an internal Do
    checkInternalRegistries

    # Private registry is not available
    return
}



#
# Ensures that a private registry secret is created in the namespace for images
# that need to be pulled from a private registry
#
# 1 - Registry secret name
# 2 - Namespace
# 3 - Registry hostname and port
# 4 - Registry username
# 5 - Registry password
#
function createRegistrySecret() {

    registrySecretName=$1
    namespace=$2
    registryHostPort=$3
    registryUsername=$4
    registryPassword=$5

    deleteKubeObject "secret" "${registrySecretName}" "${namespace}"

    kubectl create secret docker-registry ${registrySecretName} \
        --docker-server=${registryHostPort} \
        --docker-username=${registryUsername} \
        --docker-password=${registryPassword} \
        --docker-email="${registryUsername}@private.registry"
}

#
# Creates a private registry secret in the application's namespace if there
# is a private registry configured either directly for the application or
# globally in SolaKube.
#
# The name of the registry secret will be "private-registry"
#
# 1 - appname
#
function ensureRegistryAccessForApp() {

    local appName=$1

    exportPrivateRegistryAccessForApp "${appName}"

    if [[ -n "${PRIVATE_REGISTRY_FQN}" ]]
    then
        createRegistrySecret "private-registry" "${appname}" \
            "${PRIVATE_REGISTRY_FQN}" \
            "${PRIVATE_REGISTRY_USERNAME}" \
            "${PRIVATE_REGISTRY_PASSWORD}" \

    fi
}