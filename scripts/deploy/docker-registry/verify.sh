#!/usr/bin/env bash

# ==============================================================================
# Verifies the Installed Docker Registry on the cluster.
#
# ==============================================================================


# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Verifying the Docker Registry on your cluster"

# ------------------------------------------------------------
echoSection "Validating parameters"

paramValidation "REGISTRY_FQN" \
   "the Fully Qualified Domain Name, you want to access the registry with from outside the cluster. e.g.: registry.example.com"

paramValidation "REGISTRY_ADMIN_PASSWORD" \
   "the password of the 'admin' user of the registry"

# ------------------------------------------------------------
echoSection "Logging into the registry: ${REGISTRY_FQN}"

docker login --username admin --password ${REGISTRY_ADMIN_PASSWORD} ${REGISTRY_FQN}

# ------------------------------------------------------------
echoSection "Pulling a small image from Docker HUB"

docker pull busybox:latest

# ------------------------------------------------------------
echoSection "Pushing a small image to the private registry"

docker tag busybox:latest ${REGISTRY_FQN}/busybox:latest

docker push ${REGISTRY_FQN}/busybox:latest

# ------------------------------------------------------------
echoSection "Docker-registry has been verified a operational on your cluster"


