#!/usr/bin/env bash

# ==============================================================================
#
# Install the Velero CLI client on your computer.
#
# This is required to be able to automatically deploy backup profiles
# for applications.
#
# WARNING: Requires root privileges in order to install into /usr/local/sbin
#
# ==============================================================================

# Internal parameters

VELERO_VERSION="1.4.0"

# Stop immediately if any of the deployments fail
trap errorHandler ERR

echoHeader "Installing the Velero Backup/Restore Operator CLI client"

# ------------------------------------------------------------
echoSection "Validating parameters"

cd /tmp

wget https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz

tar -xzf velero-v${VELERO_VERSION}-linux-amd64.tar.gz

echo
echo "-----------------------------------"
echo "Installing the binary into /usr/local/sbin. Please, provide sudo credentials !"
echo "-----------------------------------"
echo

sudo mv velero-v${VELERO_VERSION}-linux-amd64/velero /usr/local/sbin

# ------------------------------------------------------------
echoHeader "Finished: Installing the Velero Backup/Restore Operator CLI client"

