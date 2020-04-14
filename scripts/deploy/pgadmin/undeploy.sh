#!/usr/bin/env bash

# ==============================================================================
#
# Deletes pgAdmin from the cluster
#
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing the pgAdmin DB administration tool from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "pgadmin"

# ------------------------------------------------------------
echoSection "Removing via Helm"

helm del --purge ${PGADMIN_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${PGADMIN_APP_NAME}

# ------------------------------------------------------------
echoSection "pgAdmin has been removed from your cluster"

