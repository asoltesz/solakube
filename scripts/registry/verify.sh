#!/usr/bin/env bash

# ==============================================================================
# Verifies the Installed Docker Registry on the cluster.
#
# Arguments
# 1 - Large images test (Y/N, default is N)
#     Whether to upload some large images as well
# ==============================================================================


# ------------------------------------------------------------

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Verifying the Docker Registry on your cluster"

# ------------------------------------------------------------
echoSection "Validating parameters"

TEST_LARGE_IMG=${1:-N}

checkFQN "registry"

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


if [[ ${TEST_LARGE_IMG} == "Y" ]]
then
    # ------------------------------------------------------------
    echoSection "Pulling a large image from Docker HUB"

    docker pull elastic/elasticsearch:6.6.1

    # ------------------------------------------------------------
    echoSection "Pushing a large image to the private registry"

    docker tag elastic/elasticsearch:6.6.1 ${REGISTRY_FQN}/elastic/elasticsearch:6.6.1

    docker push ${REGISTRY_FQN}/elastic/elasticsearch:6.6.1

fi


# ------------------------------------------------------------
echoSection "Docker-registry has been verified a operational on your cluster"


