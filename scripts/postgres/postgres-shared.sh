#!/usr/bin/env bash

# ==============================================================================
# Methods usable for both PGS (Postgres-Simple) and PGO-based Postgres
# installations.
# ==============================================================================



#
# Executes a script with the Postgres client as the globally configured
# admin user (the POSTGRES_ADMIN_PASSWORD user) and its password
# (POSTGRES_ADMIN_PASSWORD).
#
# 1 - path of the SQL script to be executed
# 2 - The namespace in which the postgres pod runs
#     (defaults to 'postgres')
# 3 - The hostname on which the Postgres service is available
#     (defaults to 'postgres-postgresql')
# 4 - The database to connect to
#     (defaults to 'postgres')
#
executePostgresAdminScript() {

    local scriptPath=$1
    local namespace=${2:-postgres}
    local hostname=${3:-postgres-postgresql}
    local db=${4:-postgres}

    # Copy the create script into the postgres container

    deleteKubeObject "configmap" "postgres-script" "${namespace}"

    kubectl create configmap postgres-script \
        --namespace ${namespace} \
        --from-file=sql-script.sql=${scriptPath}

    local overrides="$(cat <<-EOF
        {
            "spec": {
                "containers": [
                    {
                        "stdin": true,
                        "tty": true,
                        "args": [
                          "psql",
                          "--host=${hostname}",
                          "-U", "${POSTGRES_ADMIN_USERNAME}",
                          "-d", "${db}",
                          "-p", "5432",
                          "-f", "/script/sql-script.sql"
                        ],
                        "env": [
                            {
                                "name": "PGPASSWORD",
                                "value": "${POSTGRES_ADMIN_PASSWORD}"
                            }
                        ],
                        "name": "pg-client-cont",
                        "image": "docker.io/bitnami/postgresql:12.5.0-debian-10-r16",
                        "volumeMounts": [
                            {
                                "name": "postgres-script",
                                "mountPath": "/script/sql-script.sql",
                                "subPath": "sql-script.sql"
                            }
                        ]
                    }
                ],
                "volumes": [
                    {
                        "name": "postgres-script",
                        "configMap": {
                                "name": "postgres-script"
                        }
                    }
                ]
            }
        }
EOF
)"
    deleteKubeObject "pod" "postgres-client" "${namespace}"

    kubectl run postgres-client \
        -i --rm --tty --restart='Never' \
        --namespace ${namespace} \
        --image="will-be-overridden" \
        --overrides="${overrides}" \
        --command \
        -- psql --host ${hostname} -U postgres -d ${db} -p 5432
}




#
# In case the default cluster is not defined, it auto-selects it based on
# the presence of PGO or Postgres-Simple in the Kubernetes cluster.
#
# Sets the value of POSTGRES_DEFAULT_CLUSTER
#
# If PGO is present in the cluster, the currently targeted DB cluster will
# be selected (based on PGO_CLUSTER_NAME).
#
# If only Postgres-Simple is present, the 'SIMPLE' cluster will be selected.
#
# S
function autoSelectDefaultCluster() {

    # The default cluster is defined
    [[ ! -z "${POSTGRES_DEFAULT_CLUSTER}" ]] && return

    # Otherwise, a default cluster must be selected

    if namespaceExists "pgo"
    then
        # PGO is present on the cluster

        if [[ ! -z "${PGO_CLUSTER_NAME}" ]]
        then
            export POSTGRES_DEFAULT_CLUSTER="${PGO_CLUSTER_NAME}"
            return
        fi

        # Otherwise, we select the default PGO cluster
        export POSTGRES_DEFAULT_CLUSTER="default"
        return
    fi

    # PGO is not present
    if namespaceExists "pgs"
    then
        # Postgres-Simple is present on the K8s cluster

        export POSTGRES_DEFAULT_CLUSTER="simple"
        return
    fi


    if namespaceExists "pgs"
    then
        # Postgres-Simple is present on the K8s cluster

        export POSTGRES_DEFAULT_CLUSTER="simple"
        return
    fi

    # None of the known PG services are present
    echo "ERROR: Neither PGO, nor postgres-simple (PGS) is present in the cluster"
    return 1
}

#
# Ensures that it is possible to create an application database in one
# of the database clusters of the Kubernetes cluster
#
# Parameters:
# 1 - Application name (APP_NAME)
#     This will be the username and database name in a shared cluster.
#     This will be the cluster name, database name and user name in a dedicated
#     database cluster.
#
# It sets the <APP_NAME>_POSTGRES_CLUSTER variable with the aut-selected
# cluster (if it was not set)
#
function ensurePgApplicationClusterSelected() {

    local appName=$1

    local varName

    varName="${appName^^}_POSTGRES_CLUSTER_NAME"
    local clusterName="${!varName}"
    clusterName="${clusterName:-"default"}"

    local sharedClusterUC="${clusterName^^}"

    # Checking if the default cluster is defined or auto-selectable
    if [[ ${clusterName} == "default" && -z ${POSTGRES_DEFAULT_CLUSTER} ]]
    then
        if ! autoSelectDefaultCluster
        then
            local m
            m="FATAL: Postgres cluster name is not defined for the"
            m="${m} application ($varName) and auto-selection is not possible,"
            m="${m} since neither PGO, nor Postgres-Simple is present on the"
            m="${m} cluster "
            echo "${m}"
            return 1
        fi

        # Cluster auto-selection was successful
    fi

    cexport ${varName} "${POSTGRES_DEFAULT_CLUSTER}"
}

#
# Checks if the PGO cluster exists and creates if it needed
#
# 1 - Name of the cluster
#
function ensureCluster() {

    local cluster=${1}

    # SolaKube hosted Postgres cluster

    # Checking the Postgres-Simple service if that is requested
    if [[ ${cluster} == "simple" ]]
    then
        if ! namespaceExists "pgs"
        then
            echo "Postgres-Simple (pgs) service is not present on the cluster"
            return 1
        fi

        # Exporting variables of Postgres-Simple in the common form
        exportPgsClusterAccessVars

        return
    fi

    # PGO-hosted cluster
    ensurePgoCluster "${cluster}"

    # Export the access variables in the common form
    exportPgoClusterAccessVars "${cluster}"
}

#
# Creates a database for an application in either a shared Postgres cluster
# or in a dedicated cluster.
#
# If the specified Postgres DB cluster doesn't exist, it auto-creates it but for
# that, PGO must be installed on the Kubernetes cluster and cluster-descriptor
# environment variables present.
#
# Parameters:
# 1 - Application name (APP_NAME)
#     This will be the username and database name in a shared cluster.
#     This will be the cluster name, database name and user name in a dedicated
#     database cluster.
# 2 - The password for the database user of the application
#
# Environment variables that have effect:
#
# <APP_NAME>_POSTGRES_CLUSTER_NAME (referenced as <CLUSTER_NAME>)
#     The name of the shared or dedicated cluster.
#     If it doesn't exist yet, it must be fully configured according to PGO's
#     expectations (see DB cluster configuration variables in SolaKube's PGO docs)
#     Defaults to: 'DEFAULT'
#
# <APP_NAME>_POSTGRES_PASSWORD
#     The password of the application user created in the cluster.
#     Defaults to: SK_ADMIN_PASSWORD
#
function createPgApplicationDatabase() {

    local appName=$1
    local appPassword=$2

    local varName
    varName="${appName^^}_POSTGRES_CLUSTER_NAME"
    local clusterName="${!varName}"

    if [[ -z "${clusterName}" ]]
    then
        # Checks if it is possible to auto-allocate the application database
        # into a cluster
        ensurePgApplicationClusterSelected "${appName}" || exit 1

        # Reloading the autoselected cluster name
        clusterName="${!varName}"
    fi

    varName="POSTGRES_${cluster^^}_IS_EXTERNAL"
    local isExternal="${!varName}"
    isExternal="${isExternal:-N}"

    if [[ ${isExternal} != "Y" ]]
    then
        ensureCluster "${clusterName}"
    fi

    # Setting the remaining common variables for db creation
    export POSTGRES_APP_NAME=${appName}
    export POSTGRES_APP_DB_PASSWORD=${appPassword}

    cexport POSTGRES_SEARCH_PATH "public"

    local script="$(resolvePathOnRoots "deployment/postgres/create-app-database.sql")"

    processTemplate ${script}

    executePostgresAdminScript ${TMP_DIR}/create-app-database.sql \
        ${POSTGRES_NAMESPACE} ${POSTGRES_SERVICE_HOST}
}

function dropPgApplicationDatabase() {

    local appName=$1

    local varName
    varName="${appName^^}_POSTGRES_CLUSTER_NAME"
    local clusterName="${!varName}"

    if [[ -z "${clusterName}" ]]
    then
        # Checks if it is possible to auto-allocate the application database
        # into a cluster
        ensurePgApplicationClusterSelected "${appName}" || exit 1

        # Reloading the autoselected cluster name
        clusterName="${!varName}"
    fi

    varName="POSTGRES_${cluster^^}_IS_EXTERNAL"
    local isExternal="${!varName}"
    isExternal="${isExternal:-N}"

    if [[ ${isExternal} != "Y" ]]
    then
        ensureCluster "${clusterName}"
    fi

    export POSTGRES_APP_NAME=${appName}

    local script="$(resolvePathOnRoots "deployment/postgres/drop-app-database.sql")"

    processTemplate ${script}

    executePostgresAdminScript ${TMP_DIR}/drop-app-database.sql \
        ${POSTGRES_NAMESPACE} ${POSTGRES_SERVICE_HOST}
}


# Loading PGO-s shared methods

. ${SK_SCRIPT_HOME}/pgo/pgo-shared.sh

# Loading PGS-s shared methods (Postgres-Simple)

. ${SK_SCRIPT_HOME}/pgs/pgs-shared.sh