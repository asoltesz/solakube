#!/usr/bin/env bash

# ==============================================================================
#
# Deletes Jenkins from the cluster
#
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing Jenkins (${JENKINS_APP_NAME}) from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "jenkins"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "jenkins"

# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${JENKINS_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${JENKINS_APP_NAME}

# ------------------------------------------------------------
echoSection "Jenkins has been removed from your cluster"
