#!/usr/bin/env bash

# ==============================================================================
#
# Executes a Registry Tool Command in the regtool pod in order to list
# or delete an image tag from the registry
#
# Parameters:
# 1 - Regtool command to execute ("list" or "delete")
#     - "list" - List in the registry
#     - "delete" - Delete a tag from the registry
# 2 - Image repository to target (e.g.: busybox)
# 3 - Image tag within the repository to target (e.g.: latest)
# ==============================================================================


# Stop immediately if any of the deployments fail
trap errorHandler ERR

. ${SK_SCRIPT_HOME}/registry/registry-shared.sh

checkAppName "registry"

createTempDir "registry"

defineNamespace "registry"

export COMMAND=$1

export REPO=$2

export TAG=$3

# ------------------------------------------------------------
echoSection "Deploying reg-tool"

processTemplate regtool.sh

echo "Uploading script"
copyFileToPod "app=reg-tool" ${REGISTRY_APP_NAME} ${TMP_DIR}/regtool.sh /regtool.sh

echo "Adding privileges to regtool"
execInPod "app=reg-tool" ${REGISTRY_APP_NAME} "chmod 777 regtool.sh"


echo "Executing regtool. Command: '${COMMAND}' Repo: '${REPO}' Tag: '${TAG}'"
echo "----------"
execInPod "app=reg-tool" ${REGISTRY_APP_NAME} "bash ./regtool.sh"
echo "----------"
