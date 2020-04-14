#!/usr/bin/env bash

function checkResultExit() {

    if [[ $? != 0 ]]
    then
        echo "${1} failed"
        exit 1
    fi
}

function echoHeader() {

    echo
    echo "==================================================================="
    echo ${1}
    echo "==================================================================="
    echo

}

function echoSection() {

    echo
    echo "-------------------------------------------------------------------"
    echo ${1}
    echo "-------------------------------------------------------------------"
    echo

}

#
# Generic execution error handler. Can be set with 'trap errorHandler ERR'.
#
# Use it with "trap errorHandler ERR"
#
# Only use it with non-reusable scripts when you do not do any manual error
# handling.
#
# Do no use it in scripts which may be executed as part of a longer process
# (unless all scripts use this errorHandler)
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




checkRancherAccessParams() {

    if [[ ! ${RANCHER_API_TOKEN} ]]
    then
        echo "ERROR: RANCHER_API_TOKEN env var is not defined."

        echo "Please, define it with the token generated in Rancher in the form of 'token-iu6fg:lhvhildfkgjdlfkgjdfdfágládfdfgpxp5vb'."

        return 1
    fi

    if [[ ! ${RANCHER_CLUSTER_ID} ]]
    then
        echo "ERROR: RANCHER_CLUSTER_ID env var is not defined."

        echo "Please, define it with the cluster id of the Terraform output in the form of 'c-hmmwr'. Originally, it was printed by apply-cluster.sh."

        return 1
    fi

    if [[ ! ${RANCHER_HOST} ]]
    then
        echo "ERROR: RANCHER_HOST env var is not defined."

        echo "Please, define it with the FQN of your Rancher install in the form of 'rancher.example.com'. (Host must be accessible via https)"

        return 1
    fi

    return 0
}