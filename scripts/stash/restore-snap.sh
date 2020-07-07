#!/usr/bin/env bash

# ==============================================================================
#
# Restores a snapshot backup from the backup repository
#
# ==============================================================================

# Internal parameters

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Restoring the latest '${PROFILE}' volume snapshot Stash backup for ${APPLICATION}"

# ------------------------------------------------------------
echoSection "Validating parameters"

# loading application-specific backup config variables into generic ones
normalizeConfigVariables "${APPLICATION}" "${PROFILE}"

# Finding defaults for generic backup variables if they are not defined
applyGenericDefaults "${APPLICATION}" "${PROFILE}"

# Validates mandatory snapshot specific backup variables
validateSnapVariables "${APPLICATION}" "${PROFILE}"

# Applying snapshot backup variable defaults
applySnapDefaults "${APPLICATION}" "${PROFILE}"

# ------------------------------------------------------------
echoSection "Preparing temp folder"

createTempDir "${APPLICATION}"

# ------------------------------------------------------------
echoSection "Disabling the scheduled backup to not interfere with restore"

. ${STASH_SCRIPTS_DIR}/disable-config.sh ${PROFILE}

# ------------------------------------------------------------
echoSection "Preparing deployment descriptors"

export BACKUP_TIMEDATE=$(date +%Y%m%d-%H%M)

processTemplate fs-restoresession.yaml

# ------------------------------------------------------------
echoSection "Checking/creating namespace"

defineNamespace "${APPLICATION}"

kubectl apply -f ${TMP_DIR}/fs-restoresession.yaml \
    -n ${APPLICATION}


# ------------------------------------------------------------
echoHeader "Started restore process for the '${PROFILE}' volume snapshot Stash backup for ${APPLICATION}"
echo "After successful finish, don't forget enabling the scheduled backup !"
