#!/usr/bin/env bash

# ==============================================================================
#
# Deletes pgAdmin from the cluster
#
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------
source ../shared.sh

# Stop immediately if any of the deployments fail
trap errorHandler ERR

# ------------------------------------------------------------
echoSection "Validating parameters"

if [[ ! "${PGADMIN_APP_NAME}" ]]
then
    echo "Application name not defined: using 'pgadmin' "
    PGADMIN_APP_NAME="pgadmin"
else
    echo "Using application name: '"${PGADMIN_APP_NAME}"' "
fi

# ------------------------------------------------------------
echoSection "Removing via Helm"

helm del --purge ${PGADMIN_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${PGADMIN_APP_NAME}

# ------------------------------------------------------------
echoSection "PgAdmin has been removed from your cluster"

