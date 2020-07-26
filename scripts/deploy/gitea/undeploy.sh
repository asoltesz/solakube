#!/usr/bin/env bash

# ==============================================================================
#
# Deletes Gitea from the cluster
#
# WARNING: Deletes the database as well
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing Gitea (${GITEA_APP_NAME}) from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "gitea"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "gitea"

# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${GITEA_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${GITEA_APP_NAME}

# ------------------------------------------------------------
echoSection "Dropping the Postgres database of Gitea"

processTemplate drop-pg-database.sql

executePostgresAdminScript ${TMP_DIR}/drop-pg-database.sql ${POSTGRES_NAMESPACE} ${POSTGRES_SERVICE_HOST}


# ------------------------------------------------------------
echoSection "Gitea has been removed from your cluster"
