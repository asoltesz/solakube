#!/usr/bin/env bash

# ==============================================================================
#
# Deletes PostgreSQL from the cluster
#
# ==============================================================================

# Internal parameters


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Undeploying the PostgreSQL DBMS from your cluster "

checkAppName "postgres"

# ------------------------------------------------------------
echoSection "Validating parameters"

# ------------------------------------------------------------
deleteHelmRelease postgres

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${POSTGRES_APP_NAME}

# ------------------------------------------------------------
echoSection "Postgres has been removed from your cluster"

