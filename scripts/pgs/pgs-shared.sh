#!/usr/bin/env bash


#
# Exports a variable set for Postgres-Simple
#
function exportPgsClusterVariable() {

    local varShortName=$1

    local varName

    varName="PGS_${varShortName}"
    local value="${!varName}"

    varName="POSTGRES_${varShortName}"
    export ${varName}="${value}"
}


#
# Exports the access variables of the Postgres-Simple cluster in a
# short/common form.
#
# E.g.: PGS_ADMIN_USERNAME >> POSTGRES_ADMIN_USERNAME
#
# Variables configured this way:
# - POSTGRES_ADMIN_USERNAME
# - POSTGRES_ADMIN_PASSWORD
# - POSTGRES_SERVICE_HOST
# - POSTGRES_NAMESPACE
#
function exportPgsClusterAccessVars() {

    exportPgsClusterVariable "SERVICE_HOST"
    exportPgsClusterVariable "NAMESPACE"

    exportPgsClusterVariable "ADMIN_USERNAME"
    exportPgsClusterVariable "ADMIN_PASSWORD"

    exportPgsClusterVariable "SEARCH_PATH"
}