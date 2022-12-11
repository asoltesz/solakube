#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Variable defaults, trivial transformations and context-dependent overrides/redefinitions
# of variables
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Rancher API access
# ------------------------------------------------------------------------------

# Loading the Rancher cluster id ("sk apply" creates it there)
CLID_FILE=~/.solakube/${SK_CLUSTER}/state/rancher_cluster_id.sh
if [[ -f ${CLID_FILE} ]]
then
    source ${CLID_FILE}
fi


# ------------------------------------------------------------------------------
# Certificate-Management
# ------------------------------------------------------------------------------

# Making sure that if Cert-Manager is not installed, none of the
# cert marker variables are true so other deployers can decide properly
# and not try to deploy certificate requests
if [[ ${SK_DEPLOY_CERT_MANAGER} != "Y" ]]
then
    export LETS_ENCRYPT_DEPLOY_WC_CERT="N"
    export LETS_ENCRYPT_DEPLOY_PS_CERTS="N"
fi



# ------------------------------------------------------------------------------
# Shared Private Docker Registry settings
# ------------------------------------------------------------------------------

if [[ ${SK_CLUSTER_TYPE} == "hetzner" ]]
then
    # If private registry is NOT configured
    # we try to set a more sensible default (expecting the Docker Registry
    # to be installed on the cluster as an internal registry)

    # Hostname and port of the registry service
    cexport DEFAULT_PRIVATE_REGISTRY_FQN "registry.${CLUSTER_FQN}"
    # Username for the registry access
    cexport DEFAULT_PRIVATE_REGISTRY_USERNAME "admin"
    # Password for the username for the registry access
    cexport DEFAULT_PRIVATE_REGISTRY_PASSWORD "${SK_ADMIN_PASSWORD}"
fi



# ------------------------------------------------------------------------------
# Rook/Ceph
# ------------------------------------------------------------------------------


if [[ "${SK_DEPLOY_ROOK_CEPH}" == "Y" ]]
then
    if [[ ${SK_CLUSTER_TYPE} == "vagrant" ]]
    then
        # In the RKE Vagrant box, sdb is the storage volume
        cexport ROOK_STORAGE_DEVICE "sdb"
    else
        # By default, on Hetzner, our Cloud-Init scripts create the
        # sda2 partition for Rook/Ceph
        cexport ROOK_STORAGE_DEVICE "sda2"
    fi
fi



# ------------------------------------------------------------------------------
# OpenEBS
# ------------------------------------------------------------------------------

# The dedicated storage device/partition for OpenEBS on the nodes
# cexport OPENEBS_STORAGE_DEVICE "sda2"

#if [[ -n "${OPENEBS_STORAGE_DEVICE}" ]]
#then
#    # A dedicated local data partition/device is marked for usage for OpenEBS
#    # Replacing the hostpath storage class with the device one
#    export DEFAULT_STORAGE_CLASS="${DEFAULT_STORAGE_CLASS//openebs-hostpath/openebs-device}
#fi


# ------------------------------------------------------------------------------
# Velero backup/restore service
# ------------------------------------------------------------------------------

# The name of the storage bucket to store the backups of the application in.
# If not defined, the default Velero backup bucket will be used
cexport VELERO_S3_BUCKET_NAME "${SK_CLUSTER}-velero-backup"
