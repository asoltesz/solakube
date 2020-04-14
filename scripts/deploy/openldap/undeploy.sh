#!/usr/bin/env bash

# ==============================================================================
#
# Deletes oPENLDAP from the cluster
#
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing OpenLDAP from your cluster"

# ------------------------------------------------------------
echoSection "Validating parameters"

if [[ ! "${OPENLDAP_APP_NAME}" ]]
then
    echo "Application name not defined: using 'openldap' "
    OPENLDAP_APP_NAME="openldap"
else
    echo "Using application name: '"${OPENLDAP_APP_NAME}"' "
fi

# ------------------------------------------------------------
echoSection "Removing via Helm"

helm del --purge ${OPENLDAP_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${OPENLDAP_APP_NAME}

# ------------------------------------------------------------
echoSection "OPENLDAP has been removed from your cluster"

