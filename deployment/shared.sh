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
# Adds a namespace to the cluster if it doesn't exist.
#
# Defines the DEPLOY_NAMESPACE variable in the shell.
#
# $1 - Name of the namespace
#
defineNamespace() {

    local namespace=$1

    # Checking the namespace, dropping error messages
    local description="$(kubectl describe namespace ${namespace} 2> /dev/null)"

    if [[ "${description}" ]]
    then
        echo "Namespace already present"
        export DEPLOY_NAMESPACE=${namespace}
        return
    fi

    echo "Creating new namespace"

    kubectl create namespace ${namespace}

    export DEPLOY_NAMESPACE=${namespace}
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

#
# Checks the application name defining/overriding ENV variable.
#
# If not defined, it defines it with the provided application name
#
# 1 - The unix name of the application (e.g.: pgadmin). It will be made
#     uppercase when the env variable name is calculated
#
#
checkAppName() {

    local appName=${1}
    local appNameUC="${1^^}"
    local envVarName="${appNameUC}_APP_NAME"

    if [[ ! "${!envVarName}" ]]
    then
        echo "App name override was not defined (${envVarName}): using '${appName}' "
        export ${envVarName}="${appName}"
    else
        echo "Using pre-defined app name: '"${!envVarName}"' "
    fi
}



#
# Checks the storage class variable of the application.
#
# If not defined, it defines it with "default"
#
# 1 - The unix name of the application (e.g.: pgadmin). It will be made
#     uppercase when the env variable name is calculated
#
#
checkStorageClass() {

    local envVarName="${1^^}_STORAGE_CLASS"

    if [[ ! "${!envVarName}" ]]
    then
        echo "Storage class was not specifically defined for the application (${envVarName}) "

        if [[ ! "${DEFAULT_STORAGE_CLASS}" ]]
        then
            echo "DEFAULT_STORAGE_CLASS var is not defined. Defaulting to 'hcloud-volumes'"
            export ${envVarName}="hcloud-volumes"
        else
            echo "Switching to defined default storage class: '${DEFAULT_STORAGE_CLASS}'"
            export ${envVarName}="${DEFAULT_STORAGE_CLASS}"
        fi

    else
        echo "Using pre-defined storage class: '"${!envVarName}"' "
    fi
}

#
# Checks the if the FQN is set for the service/application with the environment
# variable ${APP_NAME}_FQN environment variable.
#
# If not defined, but the CLUSTER_FQN is defined, it will derive it from the
# cluster FQN.
#
# If not defined and cannot be derived either, it fails with an error.
#
#
checkFQN() {

    local serviceName=${1}
    local serviceNameUC=${serviceName^^}

    local envVarName="${serviceNameUC}_FQN"

    if [[ ! "${!envVarName}" ]]
    then
        echo "The FQN was not specifically defined for the service (${envVarName})"

        if [[ ! "${CLUSTER_FQN}" ]]
        then
            echo "ERROR: CLUSTER_FQN not defined, cannot derive service FQN."
            return 1
        else
            export ${envVarName}="${serviceName}.${CLUSTER_FQN}"
        fi

    else
        echo "Using pre-defined app FQN"
    fi

    local appFQN="${!envVarName}"
    echo "App FQN to be used: '"${appFQN}"' "

}


#
# Checks if a pre-defined TLS cert secret name is already set.
#
# If not, it checks if the cluster-level wildcard cert covers the FQN and sets the
# ${APP_NAME}_CLUSTER_CERT variable to "Y" if so.
#
# 1 - The unix name of the application (e.g.: pgadmin). It will be made
#     uppercase when the env variable name is calculated
#
#
checkCertificate() {

    local serviceName=${1}
    local serviceNameUC=${serviceName^^}

    local envVarName="${serviceNameUC}_FQN"
    local serviceFQN="${!envVarName}"

    if [[ ! "${serviceFQN}" ]]
    then
        echo "ERROR: CLUSTER_FQN not defined, cannot derive service FQN."
        return 1
    fi

    local envVarCertNeededName="${serviceNameUC}_CERT_NEEDED"

    local envVarCertName="${serviceNameUC}_TLS_SECRET_NAME"
    local appCertName="${!envVarCertName}"

    if [[ "${appCertName}" ]]
    then
        echo "Service has a pre-defined TLS certificate name ($appCertName)"
        # New certificate is not required
        export ${envVarCertNeededName}="N"
        return 0
    fi

    if  [[ "${serviceFQN}" == *${CLUSTER_FQN} ]] && [[ "${LETS_ENCRYPT_DEPLOY_WC_CERT}" == "Y" ]]
    then
        echo "Cluster wildcard cert covers the service FQN. Using cluster cert secret: ${CLUSTER_CERT_SECRET_NAME}"
        export ${envVarCertNeededName}="N"
        export ${envVarCertName}="${CLUSTER_CERT_SECRET_NAME}"
    else
        export ${envVarCertNeededName}="Y"
        export ${envVarCertName}="${serviceName}-tls"
        echo "The service FQN requires a separate certificate. Secret: ${serviceName}-tls"
    fi
}



#
# Checks if a TLS certificate is issued in order
#
# 1 - name of the Certificate resource
# 2 - namespace
# 3 - timeout in seconds. Optional, defaults to 300s.
#
checkCertificateIssued() {

    local certificateName=$1
    local namespace=$2
    local timeout=$3

    if [[ ! ${timeout} ]]
    then
        timeout=300
    fi

    local currTime=$(date +%s)
    local limit=$(( ${currTime} + ${timeout} ))

    local issued="N"

    while (( $(date +%s) < ${limit} ))
    do
        echo "Checking certificate '${certificateName}' in namespace '${namespace}'"

        local result=$(kubectl describe certificate ${certificateName} --namespace=cert-manager | grep "Certificate issued successfully" || :)

        if [[ ${result} ]]
        then
            echo "Certificate has been issued"
            issued="Y"
            break
        fi

        echo "Not yet issued. Waiting a bit before the next query attempt..."
        sleep 10s
    done

    if [[ ! "${issued}" == "Y" ]]
    then
        echo "Timeout passed (${timeout}). Stopping checking attempts."
        return 1
    fi
}


#
# Switches to a namespace within the cluster
#
# 1 - the name of the namespace
#
switchNs() {

    local ns=$1

    kubectl config set-context --current --namespace=${ns}
}

#
# Creates a temp folder for the application deployment
#
# 1 - The name of the application to be deployed
#
createTempDir() {

    local appName=$1

    TMP_DIR=/tmp/solakube/${appName}

    rm -Rf ${TMP_DIR}

    mkdir -p ${TMP_DIR}
}

#
# Replaces all environment variables in a template file.
#
# 1 - The path to the template file
#
# The TMP_DIR variable must be set for this to work. The replaced file will
# be created in this folder
#
processTemplate() {

    local templateFilePath=$1
    local templateFileName=$(basename ${templateFilePath})

    if [[ ! "${TMP_DIR}" ]]
    then
        echo "ERROR: TMP_DIR env variable not defined."
        exit 1
    fi

    envsubst < ${templateFilePath} > ${TMP_DIR}/${templateFileName}
}

#
# Replaces a template and applies it into the DEPLOY_NAMESPACE with kubectl
#
# If the DEPLOY_NAMESPACE is set to NOT_SPECIFIED, no namespace specifier will
# be set to kubectl.
#
# 1 - The path to the template file
#
applyTemplate() {

    local templateFilePath=$1
    local templateFileName=$(basename ${templateFilePath})

    if [[ ! "${DEPLOY_NAMESPACE}" ]]
    then
        echo "ERROR: DEPLOY_NAMESPACE is not set. Minimally, set to NOT_SPECIFIED."
        return 1
    fi

    local namespaceClause="--namespace ${DEPLOY_NAMESPACE}"

    if [[ "${DEPLOY_NAMESPACE}" == "NOT_SPECIFIED" ]]
    then
        namespaceClause=""
    fi

    processTemplate ${templateFilePath}

    kubectl apply \
        -f ${TMP_DIR}/${templateFileName} \
        ${namespaceClause}
}

