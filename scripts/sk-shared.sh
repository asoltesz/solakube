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


#
# Conditional export of a value: only if not already defined
#
function cexport()
{

    if [[ -z "${!1}" ]]
    then
        export ${1}="${2}";
    fi
}

#
# Normalizes a path (e.g.: /home/./a/.. => /home
#
function resolveDir
{
    echo "`eval "cd ${1};pwd;cd - > /dev/null"`"
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

#
# Calculates the S3 parameters for a certain application/purpose from
# the default and Backblaze B2 parameters.
#
# Defines the S3 access parameters in environment variables prefixed with
# the purpose.
#
# Defined variables:
# - <purpose>_ENDPOINT
# - <purpose>_ACCESS_KEY
# - <purpose>_SECRET_KEY
#
# The bucket is typically defined separately anyways.
#
# 1 - The purpose of the s3 access. Always upper case.
#     E.g.: "PGO_S3"
#     This will be the prefix for defining the new variables
#
# 1 - The source of the s3 access. Always upper case.
#     E.g.: "B2"
#     This may contain multiple sources separated with commas, sorted according
#     to preference (first, that has _ENDPOINT defined wins)
#
defineS3AccessParams() {

    local purpose=$1
    local sources=$2

    if [[ ! ${purpose} ]]
    then
        echo "ERROR: Purpose is not specified for S3 access variable definition"
        return 1
    fi

    if [[ ! ${sources} ]]
    then
        # The shared default S3 settings
        sources="S3,B2S3"
    fi

    for source in ${sources//,/ }; do


        local var
        var="${source}_ENDPOINT"

        if [[ -z "${!var}" ]]
        then
            continue
        fi

        echo "Exporting ${source} S3 parameters for ${purpose}"

        cexport ${purpose}_ENDPOINT "${!var}"

        var="${source}_ACCESS_KEY"
        cexport ${purpose}_ACCESS_KEY "${!var}"

        var="${source}_SECRET_KEY"
        cexport ${purpose}_SECRET_KEY "${!var}"

        var="${source}_REGION"
        cexport ${purpose}_REGION "${!var}"

    done

}

#
# Resolves the SolaKube resource file or folder based on the SK_ROOTS
# variable (a script, deployment file...etc).
#
# Checks SK_ROOTS in order a checks if the specified path exists relative to
# one of the roots. Echos the first full path that was valid.
#
# Returns false (non-0 return code) if it cannot resolve the file/folder at all.
#
# 1 - The path of the resource file relative to one of the root folders
#     listed in SK_ROOTS
#
function resolvePathOnRoots() {

    local relPath=$1

    local root

    for root in ${SK_ROOTS//:/ }
    do
        local fullPath="${root}/${relPath}"

        if [[ -f "${fullPath}" ]] || [[ -d "${fullPath}" ]]
        then
            echo "${fullPath}"
            return
        fi
    done

    false
}



#
# Normalizes a single config variable by creating a new, shorter variable name
# by taking off the prefix and - optionally - adding back a new, shorter prefix.
#
# For example. We have a variable named as NEXTCLOUD_BACKUP_SCHEDULE_DAILY but
# we would like to have a shorter version named BACKUP_SCHEDULE_DAILY.
# By setting the "NEXTCLOUD" prefix, the value of the old/long variable will be
# set into the shorter named variable.
#
# 1 - short variable name (e.g.: BACKUP_SCHEDULE_DAILY)
# 2 - prefix (e.g.: NEXTCLOUD)
# 3 - new prefix prepended to the short variable ame (optional)
#
function normalizeVariable() {

    local varName=${1//-/_}
    local prefix=${2//-/_}
    local newPrefix=$3

    local var="${prefix}_${varName}"

    # echo "Normalizing: $var (${!var})"

    [[ ! -z ${newPrefix} ]] && varName="${newPrefix}_${varName}"

    export ${varName}="${!var}"
    # echo "Exported: $varName (${!varName})"
}

#
# Finds the Ansible root folder in the SK_ROOTS.
#
function findAnsibleProjectDir() {

    export ANSIBLE_PROJ_DIR="$(resolvePathOnRoots "ansible")"

    if [[ -z "${ANSIBLE_PROJ_DIR}" ]] || [[ ! -d "${ANSIBLE_PROJ_DIR}" ]]
    then
        echo "FATAL: Couldn't find the Ansible root folder ('ansible') in the project root folders"
        exit 1
    fi

}

#
# Copies a set of SMTP parameters with a certain prefix to an other set
# starting with a different prefix.
#
# 1 - Prefix of the source variables (defaults to "smtp")
# 2 - Prefix of the target variables (defaults to the name of the application)
#
function normalizeSmtpParams() {

    local sourcePrefix=${1^^}
    local targetPrefix=${2^^}

    normalizeVariable "SMTP_ENABLED"  "${sourcePrefix}" "${targetPrefix}"
    normalizeVariable "SMTP_HOST"     "${sourcePrefix}" "${targetPrefix}"
    normalizeVariable "SMTP_PORT"     "${sourcePrefix}" "${targetPrefix}"
    normalizeVariable "SMTP_USERNAME" "${sourcePrefix}" "${targetPrefix}"
    normalizeVariable "SMTP_PASSWORD" "${sourcePrefix}" "${targetPrefix}"
    normalizeVariable "SMTP_PROPS"    "${sourcePrefix}" "${targetPrefix}"
}

#
# Imports the SMTP parameters for an application if the application doesn't have
# the SMTP parameters directly configured.
#
# It checks the application SMTP server selector which identifies the source
# of the parameters.
#
# For example, for the application/deployer Limes (appName="limes"):
#
# If the LIMES_SMTP_HOST variable is already configured, no SMTP setting will
# be imported because we assume that the application has manually configured
# SMTP settings.
#
# If the LIMES_SMTP variable is not set at all, then the global SMTP_xxx variables
# will be imported into the LIMES_SMTP_xxx variables.
#
# If the LIMES_SMTP variable is set to something (say, "postfix-relay"), then the
# SMTP_RELAY_SMTP_xxx variables will be imported into the LIMES_SMTP_xxx variables.
#
# 1 - The name of the application
# 2 - Prefix of the target variables
#     Optional, defaults to the name of the application + _SMTP_
#     Will only be used if variables actually need to be imported.
#
function importApplicationSmtpParams() {

    local appName="${1^^}"
    appName="${appName//-/_}"

    local targetPrefix=${2:-"${appName}_"}

    local varName="${appName}_SMTP_HOST"

    if [[ -n "${!varName}" ]]
    then
        # The application has directly configured SMTP variables
        return 0
    fi

    # Importing from the "SMTP_" variables by default
    local sourcePrefix=""

    local varName="${appName}_SMTP_CONFIG"
    if [[ -n "${!varName}" ]]
    then
        # The application wants specific SMTP access variables
        sourcePrefix="${!varName}"
    fi

    normalizeSmtpParams "${sourcePrefix}" "${targetPrefix}"
}
