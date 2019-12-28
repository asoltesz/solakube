#!/usr/bin/env bash

# ==============================================================================
# Template for variable values for SolaKube scripts
#
# This is to be placed in ~/.secrets after filled out
#
# For detailed variable documentation, see the docs/variables.md
# ==============================================================================



# ------------------------------------------------------------------------------
# Rancher access and the ID of the new cluster
# ------------------------------------------------------------------------------

# The Rancher API for managing the new cluster
export RANCHER_API_TOKEN="token-xxxxx:sdfsd...."

# The FQN/IP of the host running the Rancher install (and the v3 API)
export RANCHER_HOST="rancher.example.com"

# The ID of the newly created cluster in your Rancher installation
export RANCHER_CLUSTER_ID="c-xxxxx"


# ------------------------------------------------------------------------------
# Hetzer Cloud API access and other parameters
# ------------------------------------------------------------------------------

# The API token the create/manage Hetzner Cloud VMs and other resources
export HETZNER_CLOUD_TOKEN="tzz..."

# The Hetzner Floating IP that will serve as the entry point to the cluster
export HETZNER_FLOATING_IP="88.198.44.44"


# ------------------------------------------------------------------------------
# Certificate management
# ------------------------------------------------------------------------------

# The email submitted to Let's Encrypt when requesting certificates
export LETS_ENCRYPT_ACME_EMAIL="cert-admin@example.com"

# Whether the installer should deploy the Cert-Manager dns01 issuer
export LETS_ENCRYPT_DEPLOY_WC_CERT="Y"

# The name of the secret for the cluster-level, wildcard certificate.
export CLUSTER_CERT_SECRET_NAME="cluster-fqn-tls"

# Whether per-service certificates (http01) are to be supported
export LETS_ENCRYPT_DEPLOY_PS_CERTS="Y"

# The domain FQN for the cluster
export CLUSTER_FQN="andromeda.example.com"

# The Cloudflare administrator account email address (dns01 issuer)
export CLOUDFLARE_EMAIL="dns-admin@example.com"

# The Cloudflare administrator account API key (dns01 issuer)
export CLOUDFLARE_API_KEY="h567..."


# ------------------------------------------------------------------------------
# Persistent Volumes, Rook
# ------------------------------------------------------------------------------

# The default storage class if not specified for an application
export DEFAULT_STORAGE_CLASS="hcloud-volumes"
# Storage class if Rook/Ceph is installed and preferred
# export DEFAULT_STORAGE_CLASS="rook-ceph-block"


# ------------------------------------------------------------------------------
# PostgreSQL RDBMS and pgAdmin
# ------------------------------------------------------------------------------

# PostgreSQL admin user (postgres) password
export POSTGRES_ADMIN_PASSWORD="secret"

# Postgres persistent volume storage class (only if default is not suitable)
# export POSTGRES_STORAGE_CLASS=

# PgAdmin access FQN
export PGADMIN_FQN="pgadmin.andromeda.example.com"

# PgAdmin admin email address (user created automatically)
export PGADMIN_ADMIN_EMAIL="pgadmin@example.com"

# PgAdmin admin password
export PGADMIN_ADMIN_PASSWORD="secret"

# PgAdmin persistent volume storage class (only if default is not suitable)
# export PGADMIN_STORAGE_CLASS=


# ------------------------------------------------------------------------------
# Private Docker Registry
# ------------------------------------------------------------------------------

# Private Docker Registry external access FQN
export REGISTRY_FQN="docker-registry.andromeda.example.com"
# Password for the admin user
export REGISTRY_ADMIN_PASSWORD="secret"




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
