#!/usr/bin/env bash

# ==============================================================================
#
# Displays information about the private registry
#
# 1 - Nam of an app (optional, if not provided, the global settings will be shown)
# ==============================================================================

APP_NAME=$1

# Stop immediately if any of the deployments fail
trap errorHandler ERR

. ${SK_SCRIPT_HOME}/registry/registry-shared.sh

exportPrivateRegistryAccessForApp ${APP_NAME}

echo
echo "export PRIVATE_REGISTRY_FQN=${PRIVATE_REGISTRY_FQN}"
echo "export PRIVATE_REGISTRY_USERNAME=${PRIVATE_REGISTRY_USERNAME}"
echo "export PRIVATE_REGISTRY_PASSWORD=${PRIVATE_REGISTRY_PASSWORD}"
echo