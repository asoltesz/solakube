#!/usr/bin/env bash

# ==============================================================================
#
# Deletes PostgreSQL from the cluster
#
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------
source ../shared.sh

# Stop immediately if any of the deployments fail
trap errorHandler ERR

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "postgres"

# ------------------------------------------------------------
echoSection "Removing via Helm"

helm del --purge ${POSTGRES_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${POSTGRES_APP_NAME}

# ------------------------------------------------------------
echoSection "Postgres has been removed from your cluster"

