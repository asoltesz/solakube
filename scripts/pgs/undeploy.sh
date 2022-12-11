#!/usr/bin/env bash

# ==============================================================================
#
# Deletes PostgreSQL from the cluster
#
# ==============================================================================

# Internal parameters


# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Undeploying the PostgreSQL DBMS from your cluster (Postgres-Simple)"

checkAppName "pgs"

# ------------------------------------------------------------
echoSection "Validating parameters"

# ------------------------------------------------------------
deleteHelmRelease "${PGS_APP_NAME}"

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace "${PGS_APP_NAME}"

# ------------------------------------------------------------
echoSection "Postgres has been removed from your cluster  (Postgres-Simple)"

