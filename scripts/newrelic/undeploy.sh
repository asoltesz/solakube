#!/usr/bin/env bash

# ==============================================================================
#
# Deletes the New Relic monitoring client from the cluster
#
# ==============================================================================

# Internal parameters

# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Removing the NewRelic monitoring client from your cluster "

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "newrelic"

# ------------------------------------------------------------
echoSection "Removing via Helm"

deleteHelmRelease ${NEWRELIC_APP_NAME}

# ------------------------------------------------------------
echoSection "Deleting namespace"

deleteNamespace ${NEWRELIC_APP_NAME}

# ------------------------------------------------------------
echoSection "NewRelic client has been removed from your cluster"

