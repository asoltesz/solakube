#!/usr/bin/env bash

# ==============================================================================
# Template for variable values for SolaKube scripts
#
# This is to be placed as ~/.solakube/${cloud-name}/variables.sh
#
# For detailed variable documentation, see the docs/variables.md
# ==============================================================================


# ------------------------------------------------------------------------------
# Cluster attributes
# ------------------------------------------------------------------------------

# Loading the Rancher cluster id (sk apply creates it there)
CC_FILE=~/.solakube/${SK_CLUSTER}/variables_cluster_context.sh
if [[ -f ${CC_FILE} ]]
then
    source ${CC_FILE}
fi

# The cluster context for Kubectl
export SK_CLUSTER_CTX="${SK_CLUSTER}"
if [[ ${SK_CLUSTER_TYPE} == "minikube" ]]
then
    export SK_CLUSTER_CTX="minikube"
fi

# General admin password
export SK_ADMIN_PASSWORD="xxx"
export SK_ADMIN_EMAIL="xxxxxxx@example.com"


# ------------------------------------------------------------------------------
# Components to install
# ------------------------------------------------------------------------------

# Whether to deploy Cert-Manager with SolaKube or not
# WARNING: If cert-manager is not deployed, other deployers cannot use their
# ingress deployments successfully and you will have to roll your own
# cert management
export SK_DEPLOY_CERT_MANAGER="Y"

# Whether to deploy a Rook/Ceph storage cluster on the K8s cluster
export SK_DEPLOY_ROOK_CEPH="Y"

# Whether to deploy the OpenEBS storage provisioner
export SK_DEPLOY_OPENEBS="Y"

# Whether to deploy the Velero backup/restore operator
export SK_DEPLOY_VELERO="Y"

# Whether to deploy Backblaze B2 support as S3 storage on your cluster
# (via a Minio gateway)
export SK_DEPLOY_B2S3="Y"

# Whether to deploy a PostgreSQL DBMS on your cluster (simple version)
# export SK_DEPLOY_POSTGRES_SIMPLE="Y"

# Whether to deploy a pgAdmin on your cluster
export SK_DEPLOY_PGADMIN="Y"

# Whether to install the CrunchyData Postgres Operator
export SK_DEPLOY_PGO="Y"

# Whether to deploy the Docker Registry on your cluster
# export SK_DEPLOY_DOCKER_REGISTRY="N"

# Whether to install the OpenLDAP identity server
# export SK_DEPLOY_OPENLDAP="N"

# Whether to install the Nextcloud Groupware
export SK_DEPLOY_NEXTCLOUD="Y"

# Whether to install the Wordpress CMS
# export SK_DEPLOY_WORDPRESS="N"

# ------------------------------------------------------------------------------
# Shared SMTP settings
# Only SSL-based SMTP is supported
# ------------------------------------------------------------------------------

# Whether email sending via SMTP is allowed or not (for applications)
# Do not comment this line out, application deployers need it
export SMTP_ENABLED="false"
export SMTP_HOST="xxx"
export SMTP_PORT="xxx"
export SMTP_USERNAME="xxx"
export SMTP_PASSWORD="xxx"


# ------------------------------------------------------------------------------
# Shared S3 storage access settings.
# (if you want to use this for multiple purposes like (pg backups, etcd backups)
# In case you use B2S3, these will be auto-defined for you
# ------------------------------------------------------------------------------

# export S3_ENDPOINT="https://xxx"
# export S3_ACCESS_KEY="xxx"
# export S3_SECRET_KEY="xxx"
# export S3_REGION="xxx"


# ------------------------------------------------------------------------------
# Rancher access and the ID of the new cluster
# ------------------------------------------------------------------------------

# The Rancher API for managing the new cluster
export RANCHER_API_TOKEN="token-xxx:xxx"

# The FQN/IP of the host running the Rancher install (and the v3 API)
export RANCHER_HOST="rancher.example.com"

# Loading the Rancher cluster id (sk apply creates it there)
CLID_FILE=~/.solakube/${SK_CLUSTER}/rancher_cluster_id.sh
if [[ -f ${CLID_FILE} ]]
then
    source ${CLID_FILE}
fi

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


# The email submitted to Let's Encrypt when requesting certificates
export LETS_ENCRYPT_ACME_EMAIL="${SK_ADMIN_EMAIL}"

# Whether the installer should deploy the Cert-Manager dns01 issuer
# and request a wildcard-cartificate from Let's Encrypt
export LETS_ENCRYPT_DEPLOY_WC_CERT="Y"

# The name of the secret for the cluster-level, wildcard certificate.
export CLUSTER_CERT_SECRET_NAME="cluster-fqn-tls"

# Whether per-service certificates (http01) are to be supported
export LETS_ENCRYPT_DEPLOY_PS_CERTS="Y"

# Making sure that if Cert-Manager is not installed, none of the
# cert marker variables are true so other deployers can decide properly
if [[ ${SK_DEPLOY_CERT_MANAGER} != "Y" ]]
then
    export LETS_ENCRYPT_DEPLOY_WC_CERT="N"
    export LETS_ENCRYPT_DEPLOY_PS_CERTS="N"
fi

# The name of the secret for the cluster-level, wildcard certificate.
export CLUSTER_CERT_SECRET_NAME="cluster-fqn-tls"


# The domain FQN for the cluster
export CLUSTER_FQN="andromeda.example.com"

if [[ ${SK_CLUSTER_TYPE} == "minikube" ]]
then
    export CLUSTER_FQN="andromeda.mk"
fi

# The Cloudflare administrator account email address (dns01 issuer)
export CLOUDFLARE_EMAIL="${SK_ADMIN_EMAIL}"

# The Cloudflare administrator account API key (dns01 issuer)
export CLOUDFLARE_API_KEY="xxx"


# ------------------------------------------------------------------------------
# Persistent Volume storage class default
# ------------------------------------------------------------------------------

# The default storage class for applications that have no specific storage
# class configured.
# This is a list of storage classes. The first class available in the K8s
# cluster will be auto-selected.
export DEFAULT_STORAGE_CLASS="rook-ceph-block,hcloud-volumes,openebs-hostpath,standard"


# ------------------------------------------------------------------------------
# Rook/Ceph
# ------------------------------------------------------------------------------

if [[ "${SK_DEPLOY_ROOK_CEPH}" == "Y" ]]
then
    # By default, the Cloud-Init script creates the sda2 partition for Rook/Ceph
    export ROOK_STORAGE_DEVICE="sda2"

    if [[ ${SK_CLUSTER_TYPE} == "vagrant" ]]
    then
        # In the RKE Vagrant box, sdb is the storage volume
        export ROOK_STORAGE_DEVICE="sdb"
    fi
fi

# ------------------------------------------------------------------------------
# Backblaze B2 storage access parameters
# ------------------------------------------------------------------------------

# The access key (application key) created for cluser access in your B2 account
export B2_ACCESS_KEY="xxx"

# The secret key belonging to the B2 access key
export B2_SECRET_KEY="xxx"

# ------------------------------------------------------------------------------
# Backblaze B2 access as S3 compatible storage (Minio gateway)
# ------------------------------------------------------------------------------

# If the generic S3 endpoint parameters are not defined we auto-define them with
# B2 access data
if [[ "${SK_DEPLOY_B2S3}" == "Y" ]]
then
    cexport S3_ENDPOINT "${B2S3_ENDPOINT}"
    cexport S3_ACCESS_KEY "${B2_ACCESS_KEY}"
    cexport S3_SECRET_KEY "${B2_SECRET_KEY}"
    cexport S3_REGION "${B2S3_REGION}"
fi

# The region to be used (doesn't matter what at the moment)
export B2S3_REGION="default"

# The BackBlaze endpoint URL as visible within the cluster
export B2S3_ENDPOINT="http://b2s3.b2s3.svc.cluster.local:9000"


# ------------------------------------------------------------------------------
# Velero backup/restore service
# ------------------------------------------------------------------------------

# Whether Velero is allowed to use snapshots for backing up volumes
# If not, Restic will be used to backup volumes (not point-in-time snapshot)
# Defaults to false
# export VELERO_SNAPSHOTS_ENABLED="false"

# Whether it is generally allowed to deploy Velero based application backup
# profiles when an application is deployed (and has a profile defined for it)
# export VELERO_APP_BACKUPS_ENABLED="Y"

# Overriding the default S3 access parameters for Velero backups
#export VELERO_S3_ENDPOINT=xxx
#export VELERO_S3_ACCESS_KEY=xxx
#export VELERO_S3_SECRET_KEY=xxx
#export VELERO_S3_REGION=xxx

# The name of the storage bucket to store the backups of the application in.
# If not defined, the default Velero backup bucket will be used
export VELERO_S3_BUCKET_NAME="andromeda-velero-backups"


# ------------------------------------------------------------------------------
# PostgreSQL - Simple installation
# ------------------------------------------------------------------------------

if [[ ${SK_DEPLOY_POSTGRES_SIMPLE} == "Y" ]]
then
    # The username of the admin user in the new cluster
    export POSTGRES_ADMIN_USERNAME="postgres"

    # PostgreSQL admin user (DBA, typically called 'postgres') password
    export POSTGRES_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"

    # The namespace in which the Postgres service is installed
    # If an external service is used, create a namespace called postgres-client
    # to allow the pg client to run in it (for administrative pg commands)
    export POSTGRES_NAMESPACE="postgres"

    # The host name on which the Postgres service is available
    # In case of an in-cluster Postgres, this ends with a namespace as the domain
    export POSTGRES_SERVICE_HOST="postgres-postgresql.postgres"

    # Postgres persistent volume storage class (only if default is not suitable)
    # export POSTGRES_STORAGE_CLASS=
fi


# ------------------------------------------------------------------------------
# PostgreSQL - Crunchy Postgres Operator (PGO)
# ------------------------------------------------------------------------------

# The password of the PGO 'admin' user
export PGO_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"

if [[ ${SK_DEPLOY_PGO} == "Y" ]]
then
    # The username of the admin user in the new cluster
    export POSTGRES_ADMIN_USERNAME="hippo"
    # The password of the admin user in the new cluster
    export POSTGRES_ADMIN_PASSWORD="${PGO_ADMIN_PASSWORD}"
    # The namespace in which the Postgres service is installed
    export POSTGRES_NAMESPACE="pgo"
    # The internal host name on which the Postgres service is available
    export POSTGRES_SERVICE_HOST="hippo.pgo"
fi

# The name of the targeted PG cluster (cluster identifier for PGO)
export PGO_CLUSTER_NAME="hippo"

# The S3 bucket needs to be defined to activate s3 backups by pgBackRest
export PGO_CLUSTER_S3_BUCKET="${SK_CLUSTER}-postgres-backup"

# Number of standby database nodes
# export PGO_CLUSTER_REPLICA_COUNT="0"

# Postgres persistent volume storage class (only if default/calculated is not suitable)
# export PGO_CLUSTER_PRIMARY_STORAGE_CLASS=
# export PGO_CLUSTER_REPLICA_STORAGE_CLASS=
# export PGO_CLUSTER_BACKUP_STORAGE_CLASS=
# export PGO_CLUSTER_BACKREST_STORAGE_CLASS=
# export PGO_CLUSTER_WAL_STORAGE_CLASS=

# Where to store backups. Locally (local) , on S3-compatibles storage (s3)
# or both (local,s3)
# cexport PGO_CLUSTER_BACKUP_LOCATIONS "local,s3"
# The number of full backups to retain
# cexport PGO_CLUSTER_BACKUP_FULL_RETENTION "6"
# The cron schedule for automatic FULL backups
# cexport PGO_CLUSTER_BACKUP_FULL_SCHEDULE "* * * * *"
# The cron schedule for automatic INCREMENTAL backups
# cexport PGO_CLUSTER_BACKUP_INCR_SCHEDULE "* * * * *"
# Where to store scheduled backups.
# cexport PGO_CLUSTER_BACKUP_SCHEDULED_LOCATIONS "s3"

# Extra cluster creation options, if needed
# cexport PGO_CLUSTER_CREATE_EXTRA_OPTIONS ""


# ------------------------------------------------------------------------------
# pgAdmin
# ------------------------------------------------------------------------------

# PgAdmin access FQN (derived if not specified)
# export PGADMIN_FQN="pgadmin.andromeda.example.com"

# PgAdmin admin email address (user created automatically)
export PGADMIN_ADMIN_EMAIL="${SK_ADMIN_EMAIL}"

# PgAdmin admin password
export PGADMIN_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"

# PgAdmin persistent volume storage class (only if default is not suitable)
# export PGADMIN_STORAGE_CLASS=

# Whether the built-in backup profile (Velero) can be deployed
export PGADMIN_BACKUP_ENABLED="Y"


# ------------------------------------------------------------------------------
# Private Docker Registry
# ------------------------------------------------------------------------------

# Private Docker Registry external access FQN (derived if not specified)
#export REGISTRY_FQN="docker-registry.andromeda.example.com"

# Password for the admin user
export REGISTRY_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"


# ------------------------------------------------------------------------------
# OpenLDAP
# ------------------------------------------------------------------------------

# No config params yet


# ------------------------------------------------------------------------------
# Nextcloud Groupware Server
# ------------------------------------------------------------------------------

#
# The password for the 'admin' user of Nextcloud (the main administrative user).
#
export NEXTCLOUD_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"

#
# The password for the 'nextcloud' DB user in Postgres that has permissions
# for the data stored in the 'nextcloud' database which is the storage place
# for all relational data of NextCloud
#
export NEXTCLOUD_DB_PASSWORD="${SK_ADMIN_PASSWORD}"

# The size of the persistent storage for the application
# export NEXTCLOUD_PVC_SIZE="10Gi"

# Whether the built-in backup profile (Velero) can be deployed
export NEXTCLOUD_BACKUP_ENABLED="Y"

# ------------------------------------------------------------------------------
# WordPress CMS
# ------------------------------------------------------------------------------

#
# The password for the 'admin' user of Wordpress (the main administrative user).
#
export WORDPRESS_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"
export WORDPRESS_ADMIN_EMAIL="${SK_ADMIN_EMAIL}"

#
# The password for the 'wordpress' DB user in Postgres that has permissions
# for the data stored in the 'wordpress' database which is the storage place
# for all relational data of Wordpress
#
export WORDPRESS_DB_PASSWORD="${SK_ADMIN_PASSWORD}"




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
