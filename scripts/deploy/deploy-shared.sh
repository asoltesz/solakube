#!/usr/bin/env bash


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
# Checks the existence of a namespace in the cluster.
#
# $1 - Name of the namespace
#
namespaceExists() {

    local namespace=$1

    # Checking the namespace, dropping error messages
    local description="$(kubectl describe namespace ${namespace} 2> /dev/null)"

    if [[ "${description}" ]]
    then
        # Namespace is present in the cluster
        return
    fi

    false
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

    if namespaceExists "${namespace}"
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
# Deletes a namespace from the cluster if it exist
#
# $1 - Name of the namespace
#
deleteNamespace() {

    local namespace=$1

    if ! namespaceExists "${namespace}"
    then
        echo "${namespace} namespace doesn't exists in the cluster."
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
        echo "Defaulting (${envVarName}) to '${appName}' "
        export ${envVarName}="${appName}"
    else
        echo "Using pre-defined app name: '"${!envVarName}"' "
    fi
}



#
# Checks the storage class variable of the application.
#
# The application storage class variable may contain one or more storage classes
# in a comma separated list. The first storage class that is present in the
# cluster will be selected.
#
# If not defined, it defines it with "default"
#
# 1 - The unix name of the application or usage-purpose (e.g.: pgadmin).
#     It will be made uppercase when the env variable name is calculated
#
# 2 - The preferred list of storage classes
#
checkStorageClass() {

    local appName=$1
    local preferredClasses=$2

    local envVarName="${appName^^}_STORAGE_CLASS"

    # Querying the storage classes available in the cluster
    local classesInCluster=$(kubectl get sc)

    # The classes requested by the application storage class variable
    local classList="${!envVarName}"

    if [[ "${classList}" ]]
    then
        echo "${appName}: Using application-configured storage class(es): '"${classList}"' "
    fi

    if [[ ! "${classList}" ]] && [[ ${preferredClasses} ]]
    then
        classList="${preferredClasses}"
        echo "${appName}: Using the preferred class(es): '${classList}'"
    fi

    # Using the global default (if set)
    if [[ ! "${classList}" ]] && [[ ${DEFAULT_STORAGE_CLASS} ]]
    then
        classList="${DEFAULT_STORAGE_CLASS}"
        echo "${appName}: Using the default storage class(es): ${classList}"
    fi

    # Using the built-in default set (all possible classes)
    if [[ ! "${classList}" ]]
    then
        classList="rook-ceph-block,hcloud-volumes,openebs-hostpath,standard"
        echo "${appName}: Defaulting to the complete list of supported classes: ${classList}"
    fi

    # The storage class to be used for the application
    local storageClass

    for class in ${classList//,/ }; do

        local found="$( echo "${classesInCluster}" | grep ${class} )"

        if [[ ${found} ]]
        then
            storageClass=${class}
            break
        fi
    done

    if [[ ! "${storageClass}" ]]
    then
        echo "FATAL: ${appName}: No suitable storage class could be found in the cluster"
        exit 1
    fi

    echo "${appName}: selected storage class: ${storageClass}"
    export ${envVarName}="${storageClass}"
}

#
# Tells if the backup system is available on the cluster or not.
#
# Application deployers can use this to check if the application's default
# backup profile can be deployed at all.
#
function isBackupSystemAvailable() {

    # Checking the Velero namespace in the cluster
    local description="$(kubectl describe namespace "velero" 2> /dev/null)"

    if [[ ! "${description}" ]]
    then
        echo "Velero namespace is not present"
        return
    fi

    # Checking the Velero CLI client
    local version="$(velero version 2> /dev/null)"

    if [[ ! "${version}" ]]
    then
        echo "Velero client CLI is not available"
        return
    fi

    echo "true"
}




#
# Whether we should deploy a backup profile for an application or not.
#
# If the VELERO_APP_BACKUPS_ENABLED is not "Y" (the default), it returns false.
#
# If the backup system is not available, it returns false.
#
# If the <APPLICATION_NAME>_BACKUP_ENABLED is not "Y" (the default), it returns false.
#
# 1 - The name of the application
#
function shouldDeployBackupProfile() {

    local application=$1

    if [[ ${VELERO_APP_BACKUPS_ENABLED:-"Y"} != "Y" ]]
    then
        echo "Velero application backups are disabled globally"
        return
    fi

    local backupSystemAvailable="$(isBackupSystemAvailable)"
    if [[ "${backupSystemAvailable}" != "true" ]]
    then
        echo "Backup system is not available: ${backupSystemAvailable}"
        return
    fi

    local envVarName="${application}_BACKUP_ENABLED"
    local BACKUP_ENABLED=${!envVarName}

    if [[ ${BACKUP_ENABLED:-"Y"} != "Y" ]]
    then
        echo "Default backup is disabled for the application"
        return
    fi

    echo "true"
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
# 1 - servicename (e.g.: nextcloud)
# 2 - instance name (e.g.: nextcloud2). Defaults to the servicename if not
#     specified
#
checkFQN() {

    local serviceName=${1}
    local serviceNameUC=${serviceName^^}

    local instanceName=${2:-"${serviceName}"}

    local envVarName="${serviceNameUC}_FQN"

    if [[ ! "${!envVarName}" ]]
    then
        echo "The FQN was not specifically defined for the service (${envVarName})"

        if [[ ! "${CLUSTER_FQN}" ]]
        then
            echo "ERROR: CLUSTER_FQN not defined, cannot derive service FQN."
            return 1
        else
            export ${envVarName}="${instanceName}.${CLUSTER_FQN}"
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
checkCertificate() {

    local serviceName=${1}
    local serviceNameUC=${serviceName^^}

    local envVarName="${serviceNameUC}_FQN"
    local serviceFQN="${!envVarName}"

    local envVarCertNeededName="${serviceNameUC}_CERT_NEEDED"

    if [[ "${SK_CLUSTER_TYPE}" == "minikube" ]] || [[ "${SK_CLUSTER_TYPE}" == "vagrant" ]]
    then
        echo "Target cluster is a testing instance (${SK_CLUSTER_TYPE}). Cert is not needed."
        # New certificate is not required
        export ${envVarCertNeededName}="N"
        return 0
    fi

    if [[ ! "${serviceFQN}" ]]
    then
        echo "ERROR: FQN not defined for ${serviceName},"
        return 1
    fi

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
        timeout=600
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
# 2 - Keep existing if present (Y/other) defaults to N
#
createTempDir() {

    local appName=$1
    local keepIfPresent=$2

    TMP_DIR=/tmp/solakube/${appName}

    if [[ ${keepIfPresent} != "Y" ]]
    then
        rm -Rf ${TMP_DIR}
    fi

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

    if [[ ! -f "${templateFilePath}" ]]
    then
        echo "ERROR: Template file doesn't exist: ${templateFilePath}"
        echo "Current folder: $(pwd)"
        exit 1
    fi

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

#
# Deletes an application (helm-release) with Helm if it is present
#
# 1 - Name of the release
# 2 - Namespace
#
deleteHelmRelease() {

    local releaseName=$1
    local namespace=${2:-"${releaseName}"}

    echo "Uninstalling ${releaseName} with Helm"

    local releaseInfo=$(helm get all ${releaseName} 2> /dev/null)
    if [[ $? != 0 ]]
    then
        echo "Error when checking the release with Helm"
        return 1
    fi

    if [[ ! "${releaseInfo}" ]]
    then
        echo "Helm release not present, maybe already deleted"
        return 0
    fi

    helm uninstall ${releaseName} --namespace="${namespace}"
    if [[ $? != 0 ]]
    then
        echo "Error when deleting the release with Helm"
        return 1
    fi

    return 0
}

#
# Waits until all pods become Ready (Active) in a namespace
#
# Make sure that all necessary K8s objects are already created and visible
# via the API before calling this.
#
# 1 - namespace
# 2 - maximum timeout in seconds (defaults to 600 seconds / 10 minutes)
# 3 - check interval in seconds (defaults to 5 seconds)
#
waitAllPodsActive() {

    local namespace=$1
    local timeout=${2:-600}
    local checkInterval=${3:-5}

    local startTime=$(date +%s)
    local limit=$(( ${startTime} + ${timeout} ))

    echo "Checking pods in namespace '${namespace}' to become all Ready"

    local now=$(date +%s)

    local jsonPath='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'

    while (( ${now} < ${limit} ))
    do
        # Check which nodes are NOT ready

        local result=$(kubectl get pods -o jsonpath="${jsonPath}" \
                          --namespace=${namespace} | grep "Ready=False")

        if [[ ! "${result}" ]]
        then
            echo "All pods are 'Ready' (time in waiting: $(( ${now} - ${startTime} ))s)"
            return 0
        fi

        echo "waiting ${checkInterval}s ..."
        sleep ${checkInterval}s
        now=$(date +%s)
    done

    echo "Timeout passed (${timeout}). Stopping checking attempts. Check failed."

    local result=$(kubectl get pods -o jsonpath="${jsonPath}" \
                      --namespace=${namespace} | grep "Ready=False")

    echo "Pods that are NOT ready:"
    echo "${result}"

    return 1
}

#
# Waits until all pods start in a namespace.
#
# This does not wait until they are ready, only until they have been created
# and are running.
#
# Make sure that all necessary K8s objects are already created and visible
# via the API before calling this.
#
# 1 - namespace
# 2 - maximum timeout in seconds (defaults to 600 seconds / 10 minutes)
# 3 - check interval in seconds (defaults to 5 seconds)
#
waitAllPodsRunning() {

    local namespace=$1
    local timeout=${2:-600}
    local checkInterval=${3:-5}

    local startTime=$(date +%s)
    local limit=$(( ${startTime} + ${timeout} ))

    echo "Checking pods in namespace '${namespace}' to become all Running"

    local now=$(date +%s)

    while (( ${now} < ${limit} ))
    do
        local result=$(kubectl get pods --field-selector=status.phase!=Running --namespace=${namespace})

        if [[ ! "${result}" ]]
        then
            echo "All pods are 'Running' (time in waiting: $(( ${now} - ${startTime} ))s)"
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
# Waits until a single pod become Active in a namespace
#
# 1 - namespace
# 2 - name of the pod (or part of the name)
# 3 - maximum timeout in seconds (defaults to 600 seconds / 10 minutes)
# 4 - check interval in seconds (defaults to 5 seconds)
#
waitSinglePodActive() {

    local namespace=$1
    local podName=$1
    local timeout=${2:-600}
    local checkInterval=${3:-5}

    local startTime=$(date +%s)
    local limit=$(( ${startTime} + ${timeout} ))

    echo "Checking pods in namespace '${namespace}' to become all Running"

    local now=$(date +%s)

    while (( ${now} < ${limit} ))
    do
        local result=$(kubectl get pods --field-selector=metadata.name=${podName},status.phase=Running --namespace=${namespace})

        if [[ "${result}" != "No resources found." ]]
        then
            echo "Pods ${podName} is in 'Running' state (time in waiting: $(( ${now} - ${startTime} ))s"
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
# Returns the ClusterIP of a service in a namespace
#
# 1 - service name
# 2 - namespace
#
getClusterIP() {

    local serviceName=$1
    local namespace=$2

    kubectl get service \
        -o custom-columns=":spec.clusterIP" \
        --no-headers=true \
        --namespace=${namespace} \
        --field-selector metadata.name=${serviceName}

    if [[ $? != 0 ]]
    then
        return 1
    fi

}

#
# Executes a command in a pod identified by a selector
#
# 1 - pod selector. E.g.: "name=pgo-client"
# 2 - namespace
# 3 - the command to run
#
execInPod() {

    local selector=$1
    local namespace=$2
    local command=$3

    # Querying the PGO client CLI pod
    local podName=$(kubectl get pods \
                      --selector=${selector} \
                      --output=jsonpath={.items..metadata.name} \
                      --namespace ${namespace} \
                      --no-headers
                    )

    if [[ ! ${podName} ]]
    then
        echo "ERROR: pod not found with selector: ${selector}"
        exit 1
    fi

    # Executing the command
    kubectl exec -it ${podName} -n ${namespace} -- ${command}

    return $?
}


#
# Uploads a file to a pod identified by a selector
#
# 1 - pod selector. E.g.: "name=pgo-client"
# 2 - namespace
# 3 - the local path of the file
# 4 - the path of the file within the pod
#
copyFileToPod() {

    local selector=$1
    local namespace=$2
    local localPath=$3
    local podPath=$4

    # Querying the PGO client CLI pod
    local podName=$(kubectl get pods \
                      --selector=${selector} \
                      --output=jsonpath={.items..metadata.name} \
                      --namespace=${namespace} \
                      --no-headers
                    )

    if [[ ! ${podName} ]]
    then
        echo "ERROR: pod not found with selector: ${selector}"
        exit 1
    fi

    kubectl cp ${localPath} ${podName}:${podPath} -n ${namespace}

    return $?
}



#
# Checks if a K8s object is present.
#
# It will return false if not
#
# 1 - object type
# 2 - object name
# 3 - namespace
#
isKubeObjectPresent() {

    local objectType=$1
    local objectName=$2
    local namespace=$3

    local result=$(kubectl get ${objectType} \
        --field-selector=metadata.name=${objectName} --no-headers=true \
        --namespace=${namespace})

    if [[ ${result} ]]
    then
        return
    fi

    false
}

#
# Deletes a K8s object if it is present.
#
# It will not throw an error if the object is not present.
#
# 1 - object type
# 2 - object name
# 3 - namespace
#
deleteKubeObject() {

    local objectType=$1
    local objectName=$2
    local namespace=$3

    if ! isKubeObjectPresent "${objectType}" "${objectName}" "${namespace}"
    then
        return 0
    fi

    kubectl delete ${objectType} ${objectName} --namespace=${namespace}
    return $?
}


