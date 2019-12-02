#!/usr/bin/env bash

function checkResult() {

    if [[ $? != 0 ]]
    then
        echo "${1} failed"
        exit 1
    fi
}


function echoSection() {

    echo
    echo "-------------------------------------------------------------------"
    echo ${1}
    echo "-------------------------------------------------------------------"
    echo

}

#
# Execution error handler. Can be set with 'trap errorHandler ERR'
#
errorHandler() {

    exitcode=$?

    echo "----------"

    echo "ERROR in execution" 1>&2

    echo The command executing at the time of the error was: "${BASH_COMMAND}"

    echo "Exit code returned by the command: ${exitcode}"

    echo "The command present on line: ${BASH_LINENO[0]}"

    echo "----------"

    exit ${exitcode}
}

#
# Checks if an environment variable is defined. If not, the script stops and the
# appropriate instruction appears.
#
# 1 - Name of the environment variable.
# 2 - Instructions on what value to define it with.
#
paramValidation() {

    local envVarName=${1}
    local instructions=${2}

    if [[ ! ${!envVarName} ]]
    then
        echo "ERROR: ${envVarName} environment variable is not defined."

        echo "Please define it with: ${instructions}"

        exit 1
    fi

}

#
# Adds a namespace to the cluster if it doesn't exist
#
# $1 - Name of the namespace
#
addNamespace() {

    local namespace=$1

    # Checking the namespace, dropping error messages
    local description="$(kubectl describe namespace ${namespace} 2> /dev/null)"

    if [[ "${description}" ]]
    then
        echo "Namespace already present"
        return
    fi

    echo "Creating new namespace"

    kubectl create namespace ${namespace}
}

#
# Adds a namespace to the cluster if it exist
#
# $1 - Name of the namespace
#
deleteNamespace() {

    local namespace=$1

    local description="$(kubectl describe namespace ${namespace})"

    if [[ ! "${description}" ]]
    then
        # namespace doesn't exists
        return
    fi

    kubectl delete namespace ${namespace}
}