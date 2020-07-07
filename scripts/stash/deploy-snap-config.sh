#!/usr/bin/env bash

# ==============================================================================
#
# Deploy a Stash volume snapshot backup configuration for an application.
#
# Assumes that the application has its own namespace (as it should).
#
# ==============================================================================

# Internal parameters

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying the '${PROFILE}' Stash snapshot backup configuration for application '${APPLICATION}'"

# ------------------------------------------------------------
echoSection "Validating parameters"

# loading application-specific backup config variables into generic ones
normalizeConfigVariables "${APPLICATION}" "${PROFILE}"

# Finding defaults for generic backup variables if they are not defined
applyGenericDefaults "${APPLICATION}" "${PROFILE}"

# Validates mandatory snapshot/restic specific backup variables
validateSnapVariables "${APPLICATION}" "${PROFILE}"

# Applying snapshot/restic backup variable defaults
applySnapDefaults "${APPLICATION}" "${PROFILE}"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "${APPLICATION}"

# ------------------------------------------------------------
echoSection "Preparing deployment descriptors"

processTemplate snap-backupconfig.yaml

# ------------------------------------------------------------
echoSection "Checking/creating namespace"

defineNamespace "${APPLICATION}"


# ------------------------------------------------------------
echoSection "Deploying K8s resources"

kubectl apply -f ${TMP_DIR}/snap-backupconfig.yaml \
    -n ${BACKUP_NAMESPACE}


# ------------------------------------------------------------
echoSection "Stash backup configuration '${PROFILE}' for application '${APPLICATION}' has been installed into the '${BACKUP_NAMESPACE}' namespace"

