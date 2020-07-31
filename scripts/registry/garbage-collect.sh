#!/usr/bin/env bash

# ==============================================================================
#
# Executes the garbage collection in the Registry
#
# ==============================================================================

# Internal parameters

# Stop immediately if any of the deployments fail
trap errorHandler ERR

checkAppName "registry"

#
# Uploads a file to a pod identified by a selector
#
copyFileToPod "app=docker-registry" ${REGISTRY_APP_NAME} garbage-config.yml /tmp/garbage-config.yml

#
# Executes a command in a pod identified by a selector
#
# 1 - pod selector. E.g.: "name=pgo-client"
# 2 - namespace
# 3 - the command to run
#
execInPod "app=docker-registry" ${REGISTRY_APP_NAME} "registry garbage-collect /tmp/garbage-config.yml"

