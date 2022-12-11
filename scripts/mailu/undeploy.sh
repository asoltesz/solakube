#!/usr/bin/env bash

# ==============================================================================
#
# Deletes Mailu from the cluster
#
# WARNING: Deletes the database as well
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing Mailu (${MAILU_APP_NAME}) from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "mailu"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "mailu"

# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${MAILU_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${MAILU_APP_NAME}

# ------------------------------------------------------------
echoSection "Dropping the Postgres database of Mailu"

dropPgApplicationDatabase ${MAILU_APP_NAME}

if [[ ${MAILU_ROUNDCUBE_ENABLED} == "true" ]]
then
    dropPgApplicationDatabase "${MAILU_APP_NAME}_roundcube"
fi


# Deleted automatically when the namespace is destroyed
## ------------------------------------------------------------
## External-DNS deployed for Mailu
##
#if [[ "${MAILU_DEPLOY_EXTERNAL_DNS}" == "true" ]]
#then
#    echoSection "Removing External-DNS for Mailu"
#    deleteHelmRelease "${MAILU_APP_NAME}-external-dns" "${MAILU_APP_NAME}"
#fi

# ------------------------------------------------------------
echoSection "Mailu has been removed from your cluster"
