#!/usr/bin/env bash

# ==============================================================================
# Template for variable values for SolaKube scripts
#
# This is to be placed as ~/.solakube/${cloud-name}/variables.sh
#
# For detailed variable documentation, see the docs/variables.md
# ==============================================================================



# ------------------------------------------------------------------------------
# Rancher access and the ID of the new cluster
# ------------------------------------------------------------------------------

# The Rancher API for managing the new cluster
export RANCHER_API_TOKEN="token-xxx:xxx"

# The FQN/IP of the host running the Rancher install (and the v3 API)
export RANCHER_HOST="rancher.example.com"

# Loading the Rancher cluster id (apply creates there)
source ~/.solakube/andromeda/rancher_cluster_id.sh

# ------------------------------------------------------------------------------
# Hetzer Cloud API access and other parameters
# ------------------------------------------------------------------------------

# The API token the create/manage Hetzner Cloud VMs and other resources
export HETZNER_CLOUD_TOKEN="xxx"

# The Hetzner Floating IP that will serve as the entry point to the cluster
export HETZNER_FLOATING_IP="xxx.xxx.xxx.xxx"


# ------------------------------------------------------------------------------
# Certificate management
# ------------------------------------------------------------------------------

# Whether to deploy Cert-Manager with SolaKube or not
# WARNING: If cert-manager is not deployed, other deployers cannot use their
# ingress deployments successfully and you will have to do all of them manually
export SK_DEPLOY_CERT_MANAGER="Y"

# The email submitted to Let's Encrypt when requesting certificates
export LETS_ENCRYPT_ACME_EMAIL="xxx@example.com"

# Whether the installer should deploy the Cert-Manager dns01 issuer
export LETS_ENCRYPT_DEPLOY_WC_CERT="Y"

# The name of the secret for the cluster-level, wildcard certificate.
export CLUSTER_CERT_SECRET_NAME="cluster-fqn-tls"

# Whether per-service certificates (http01) are to be supported
export LETS_ENCRYPT_DEPLOY_PS_CERTS="Y"

# The domain FQN for the cluster
export CLUSTER_FQN="andromeda.example.com"

# The Cloudflare administrator account email address (dns01 issuer)
export CLOUDFLARE_EMAIL="xxx@example.com"

# The Cloudflare administrator account API key (dns01 issuer)
export CLOUDFLARE_API_KEY="xxx"


# ------------------------------------------------------------------------------
# Persistent Volumes, Rook
# ------------------------------------------------------------------------------

# Whether to deploy a Rook/Ceph storage cluster on the K8s cluster
export SK_DEPLOY_ROOK_CEPH="Y"

# The default storage class if not specified for an application
export DEFAULT_STORAGE_CLASS="hcloud-volumes"

# Storage class if Rook/Ceph is installed and preferred
if [[ "${SK_DEPLOY_ROOK_CEPH}" == "Y" ]]
then
    export DEFAULT_STORAGE_CLASS="rook-ceph-block"
fi


# ------------------------------------------------------------------------------
# PostgreSQL RDBMS
# ------------------------------------------------------------------------------

# Whether to deploy a PostgreSQL DBMS on your cluster
export SK_DEPLOY_POSTGRES="Y"

# PostgreSQL admin user (postgres) password
export POSTGRES_ADMIN_PASSWORD="secret"

# Postgres persistent volume storage class (only if default is not suitable)
# export POSTGRES_STORAGE_CLASS=

# ------------------------------------------------------------------------------
# pgAdmin
# ------------------------------------------------------------------------------

# Whether to deploy a pgAdmin on your cluster
export SK_DEPLOY_PGADMIN="Y"

# PgAdmin access FQN
export PGADMIN_FQN="pgadmin.andromeda.example.com"

# PgAdmin admin email address (user created automatically)
export PGADMIN_ADMIN_EMAIL="xxx@example.com"

# PgAdmin admin password
export PGADMIN_ADMIN_PASSWORD="secret"

# PgAdmin persistent volume storage class (only if default is not suitable)
# export PGADMIN_STORAGE_CLASS=


# ------------------------------------------------------------------------------
# Private Docker Registry
# ------------------------------------------------------------------------------

# Whether to deploy the Docker Registry on your cluster
export SK_DEPLOY_DOCKER_REGISTRY="Y"

# Private Docker Registry external access FQN
export REGISTRY_FQN="docker-registry.andromeda.example.com"
# Password for the admin user
export REGISTRY_ADMIN_PASSWORD="secret"


# ------------------------------------------------------------------------------
# OpenLDAP
# ------------------------------------------------------------------------------

export SK_DEPLOY_OPENLDAP="Y"



# ------------------------------------------------------------------------------
# Exports for Terraform
# ------------------------------------------------------------------------------

# Hetzner Cloud Token
export TF_VAR_hcloud_token="${HETZNER_CLOUD_TOKEN}"

# The Rancher API Key
export TF_VAR_rancher_api_token="${RANCHER_API_TOKEN}"

# Parameters for the S3 storage for etcd backup (done by Rancher)
export TF_VAR_etcd_s3_access_key=
export TF_VAR_etcd_s3_secret_key=
