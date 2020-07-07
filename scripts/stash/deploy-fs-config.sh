#!/usr/bin/env bash

# ==============================================================================
#
# Deploy a Stash filesystem backup configuration for an application.
#
# Assumes that the application has its own namespace (as it should).
#
# ==============================================================================

# Internal parameters

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Deploying the ${PROFILE} Stash filesystem backup configuration for ${APPLICATION}"

# ------------------------------------------------------------
echoSection "Validating parameters"

# loading application-specific backup config variables into generic ones
normalizeConfigVariables "${APPLICATION}" "${PROFILE}"

# Finding defaults for generic backup variables if they are not defined
applyGenericDefaults "${APPLICATION}" "${PROFILE}"

# Validates mandatory filesystem/restic specific backup variables
validateFsVariables "${APPLICATION}" "${PROFILE}"

# Applying filesystem/restic backup variable defaults
applyFsDefaults "${APPLICATION}" "${PROFILE}"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "${APPLICATION}"

# ------------------------------------------------------------
echoSection "Preparing deployment descriptors"

processTemplate repo-secret.yaml
processTemplate repo-${BACKUP_REPO_TYPE}.yaml
processTemplate fs-backupconfig.yaml

# ------------------------------------------------------------
echoSection "Checking/creating namespace"

defineNamespace "${APPLICATION}"


# ------------------------------------------------------------
echoSection "Deploying K8s resources"

kubectl apply -f ${TMP_DIR}/repo-secret.yaml \
    -n ${BACKUP_NAMESPACE}
kubectl apply -f ${TMP_DIR}/repo-${BACKUP_REPO_TYPE}.yaml \
    -n ${BACKUP_NAMESPACE}
kubectl apply -f ${TMP_DIR}/fs-backupconfig.yaml \
    -n ${BACKUP_NAMESPACE}


# ------------------------------------------------------------
echoSection "Stash backup configuration ${PROFILE} for ${APPLICATION} has been installed into the ${BACKUP_NAMESPACE}"

