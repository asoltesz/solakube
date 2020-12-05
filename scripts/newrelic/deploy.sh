#!/usr/bin/env bash

# ==============================================================================
#
# Install the NewRelic Monitoring Client on your cluster
#
# ==============================================================================

# Internal parameters

# HELM_CHART_VERSION=latest

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying the NewRelic monitoring client"

# ------------------------------------------------------------
echoSection "Validating parameters"

checkAppName "newrelic"

checkStorageClass "newrelic"

checkFQN "newrelic"

checkCertificate "newrelic"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "newrelic"

# ------------------------------------------------------------
echoSection "Preparing Helm chart values"

processTemplate chart-values.yaml


# ------------------------------------------------------------
echoSection "Creating namespace"

defineNamespace ${NEWRELIC_APP_NAME}


# ------------------------------------------------------------
echoSection "Installing application with Helm chart (without ingress)"

helm repo add newrelic https://helm-charts.newrelic.com

helm upgrade ${NEWRELIC_APP_NAME} newrelic/nri-bundle \
    --install \
    --namespace ${NEWRELIC_APP_NAME} \
    --values ${TMP_DIR}/chart-values.yaml


# ------------------------------------------------------------
echoSection "NewRelic monitoring client has been installed on your cluster"

