#!/usr/bin/env bash

# ==============================================================================
#
# Deletes Redmine from the cluster
#
# WARNING: Deletes the database as well
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing Redmine (${REDMINE_APP_NAME}) from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "redmine"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "redmine"

# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${REDMINE_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${REDMINE_APP_NAME}

# ------------------------------------------------------------
echoSection "Dropping the Postgres database of Redmine"

processTemplate drop-pg-database.sql

executePostgresAdminScript ${TMP_DIR}/drop-pg-database.sql ${POSTGRES_NAMESPACE} ${POSTGRES_SERVICE_HOST}


# ------------------------------------------------------------
echoSection "Redmine has been removed from your cluster"
