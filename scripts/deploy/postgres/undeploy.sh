#!/usr/bin/env bash

# ==============================================================================
#
# Deletes PostgreSQL from the cluster
#
# ==============================================================================

# Internal parameters


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying the PostgreSQL DBMS from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

# ------------------------------------------------------------
deleteHelmRelease openldap

deleteNamespace openldap

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${POSTGRES_APP_NAME}

# ------------------------------------------------------------
echoSection "Postgres has been removed from your cluster"

