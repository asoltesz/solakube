#!/usr/bin/env bash

# ==============================================================================
#
# Deletes NextCloud from the cluster
#
# WARNING: Deletes the database as well
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing NextCloud from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "nextcloud"


# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${NEXTCLOUD_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${NEXTCLOUD_APP_NAME}

# ------------------------------------------------------------
echoSection "Dropping the Postgres database of NextCloud"

executePostgresAdminScript drop-pg-database.sql ${POSTGRES_NAMESPACE} ${POSTGRES_SERVICE_HOST}


# ------------------------------------------------------------
echoSection "NextCloud has been removed from your cluster"

