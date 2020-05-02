#!/usr/bin/env bash

# ==============================================================================
#
# Deletes Wordpress from the cluster
#
# WARNING: Deletes the database as well
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing Wordpress from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "wordpress"


# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${WORDPRESS_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${WORDPRESS_APP_NAME}


# ------------------------------------------------------------
echoSection "Wordpress has been removed from your cluster"

