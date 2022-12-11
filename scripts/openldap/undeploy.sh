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

checkAppName "openldap"

# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${OPENLDAP_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${OPENLDAP_APP_NAME}

# ------------------------------------------------------------
echoSection "OPENLDAP has been removed from your cluster"

