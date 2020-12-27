#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Exports variables for Terraform
# ------------------------------------------------------------------------------

# Hetzner Cloud Token
cexport TF_VAR_hcloud_token "${HETZNER_CLOUD_TOKEN}"

# The Rancher API Key
cexport TF_VAR_rancher_api_token "${RANCHER_API_TOKEN}"

#
# Parameters for the S3 storage for etcd backup (done by Rancher)
#
if [[ -n "${S3_ENDPOINT}" ]]
then
    cexport TF_VAR_etcd_backup_enabled "true"
    cexport TF_VAR_etcd_s3_bucket_name "${SK_CLUSTER}-rancher-etcd-backup"
    # Endpoint must come without the protocol for Rancher "https://"
    cexport TF_VAR_etcd_s3_endpoint "${S3_ENDPOINT//https:\/\/}"
    cexport TF_VAR_etcd_s3_region "${S3_REGION}"
    cexport TF_VAR_etcd_s3_access_key "${S3_ACCESS_KEY}"
    cexport TF_VAR_etcd_s3_secret_key "${S3_SECRET_KEY}"
fi
