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

# Whether to deploy the JFrog Container Registry
export SK_DEPLOY_JCR="Y"

# Whether to deploy Backblaze B2 support as S3 storage on your cluster
# (via a Minio gateway)
export SK_DEPLOY_B2S3="Y"

# Whether to deploy a PostgreSQL DBMS on your cluster (simple version)
export SK_DEPLOY_PGS="Y"

# Whether to install Mailu Email Services
export SK_DEPLOY_MAILU="Y"

# Whether to deploy a pgAdmin on your cluster
export SK_DEPLOY_PGADMIN="Y"

# Whether to install the CrunchyData Postgres Operator
export SK_DEPLOY_PGO="Y"

# Whether to deploy the Docker Registry on your cluster
# export SK_DEPLOY_DOCKER_REGISTRY="N"

# Whether to install the OpenLDAP identity server
# export SK_DEPLOY_OPENLDAP="N"

# Whether to install the Gitea Development Teamwork Server
export SK_DEPLOY_GITEA="Y"

# Whether to install the Redmine Issue/Project Management Server
# export SK_DEPLOY_REDMINE="Y"

# Whether to install the Jenkins CI/CD server
export SK_DEPLOY_JENKINS="Y"

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
# Shared Private Docker Registry settings
# Only needed if:
# - Private Docker Registry is needed for an application
#   (images come from a private registry)
# - Registry is external to the cluster
# - Registry is internal but auto-discovery is not supported for it
#   (auto discovery is only supported for the SolaKube deployed Docker Registry
#    via the "registry" deployer)
# ------------------------------------------------------------------------------

# Hostname and port of the registry service
export DEFAULT_PRIVATE_REGISTRY_FQN=""
# Username for the registry access
export DEFAULT_PRIVATE_REGISTRY_USERNAME=""
# Password for the username for the registry access
export DEFAULT_PRIVATE_REGISTRY_PASSWORD=""


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
export DEFAULT_STORAGE_CLASS="rook-ceph-block,hcloud-volumes,openebs-hostpath,standard,local-path"


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
# PostgreSQL - Simple installation (PGS)
# ------------------------------------------------------------------------------

# The username of the admin user in the new cluster
export PGS_ADMIN_USERNAME="postgres"

# PostgreSQL admin user (DBA, typically called 'postgres') password
export PGS_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"

# The namespace in which the Postgres service is installed
# If an external service is used, create a namespace called postgres-client
# to allow the pg client to run in it (for administrative pg commands)
export PGS_NAMESPACE="pgs"

# The host name on which the Postgres service is available
# In case of an in-cluster Postgres, this ends with a namespace as the domain
export PGS_SERVICE_HOST="pgs-postgresql.pgs"

# Postgres persistent volume storage class (only if default is not suitable)
# export PGS_STORAGE_CLASS=


# ------------------------------------------------------------------------------
# PostgreSQL - Crunchy Postgres Operator (PGO)
# ------------------------------------------------------------------------------

# The password of the PGO 'admin' user
export PGO_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"


# The currently selected PG cluster for SolaKube scripts
export PGO_CURRENT_CLUSTER_NAME="default"

# The name of the PG cluster in PGO (cluster identifier for PGO)
export PGO_CLUSTER_NAME="default"

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
# Private Docker Registry (by Docker)
# ------------------------------------------------------------------------------

# Private Docker Registry external access FQN (derived if not specified)
#export REGISTRY_FQN="docker-registry.andromeda.example.com"

# The registry will need a fair amount of space, so class preference is changed
export REGISTRY_STORAGE_CLASS="hcloud-volumes,openebs-hostpath,rook-ceph-block,standard"

# The volume size for storing the Docker images
#export REGISTRY_PVC_SIZE="20Gi"

# Whether the built-in backup profile (Velero) can be deployed (by default Y)
export REGISTRY_BACKUP_ENABLED="Y"

# Password for the 'admin' user of the registry
export REGISTRY_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"


# ------------------------------------------------------------------------------
# JFrog Container Registry
# ------------------------------------------------------------------------------

#
# The password for the 'admin' user of Jcr (the main administrative user).
#
export JCR_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"

#
# The email address for the 'admin' user of Jcr (the main administrative user).
#
export JCR_ADMIN_EMAIL="${SK_ADMIN_EMAIL}"

#
# The password for the 'admin' DB user in Postgres that has permissions
# for the data stored in the 'jcr' database which is the storage place
# for all relational data of Jcr
#
export JCR_DB_PASSWORD="${SK_ADMIN_PASSWORD}"

# The size of the persistent storage for the application
# export JCR_PVC_SIZE="3Gi"

# Whether the built-in backup profile (Velero) can be deployed
export JCR_BACKUP_ENABLED="Y"


# ------------------------------------------------------------------------------
# OpenLDAP
# ------------------------------------------------------------------------------

# No config params yet


# ------------------------------------------------------------------------------
# Gitea Git/Code-Review/CI Server (SW Development Server)
# ------------------------------------------------------------------------------

#
# The password for the 'admin' user of Gitea (the main administrative user).
#
export GITEA_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"

#
# The email address for the 'gitea' user of Gitea (the main administrative user).
#
export GITEA_ADMIN_EMAIL="${SK_ADMIN_EMAIL}"

#
# The password for the 'gitea' DB user in Postgres that has permissions
# for the data stored in the 'gitea' database which is the storage place
# for all relational data of Gitea
#
export GITEA_DB_PASSWORD="${SK_ADMIN_PASSWORD}"

# The size of the persistent storage for the application
# export GITEA_PVC_SIZE="3Gi"

# Whether the built-in backup profile (Velero) can be deployed
export GITEA_BACKUP_ENABLED="Y"


# ------------------------------------------------------------------------------
# Redmine Issue/Project Management
# ------------------------------------------------------------------------------

#
# The password for the 'admin' user of Redmine (the main administrative user).
#
export REDMINE_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"

#
# The email address for the 'admin' user of Redmine (the main administrative user).
#
export REDMINE_ADMIN_EMAIL="${SK_ADMIN_EMAIL}"

#
# The password for the 'admin' DB user in Postgres that has permissions
# for the data stored in the 'redmine' database which is the storage place
# for all relational data of Redmine
#
export REDMINE_DB_PASSWORD="${SK_ADMIN_PASSWORD}"

# The size of the persistent storage for the application
# export REDMINE_PVC_SIZE="3Gi"

# Whether the built-in backup profile (Velero) can be deployed
export REDMINE_BACKUP_ENABLED="Y"


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
# Jenkins CI/CD Server
# ------------------------------------------------------------------------------

#
# The password for the 'admin' user of Jenkins (the main administrative user).
#
export JENKINS_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"

# The email address of the 'admin' user of Jenkins (the main administrative user).
export JENKINS_ADMIN_EMAIL="${SK_ADMIN_EMAIL}"

# The size of the persistent storage for the application
# export JENKINS_PVC_SIZE="5Gi"

# The short-name/id of the main Git repo host you will typically check-out
# sources with Jenkins (e.g.: "github" or "internal-gitlab"
export JENKINS_MAIN_GIT_ID="company-repo"

# The base URL of the repos on the main repo host
# E.g.: https://github.com
export JENKINS_MAIN_GIT_BASE_URL="https://our-company-repo.com"

# The username for the main Git repo host that can be used for Jenkins
# to check out sources for build jobs
export JENKINS_MAIN_GIT_USERNAME="xxxxx"

# The password belonging to the username for the main Git repo host
export JENKINS_MAIN_GIT_PASSWORD="xxxxx"

#
# The repo path of a test Git repo that can be used for creating a sample
# job for validating the Jenkins installation.
# This will be attached to the main Git repo (JENKINS_MAIN_GIT_BASE_URL)
# to form a full repo URL.
#
# E.g.: my-app/sources.git
#
# If this is provided, a sample Job will be deployed into Jenkins that
# checks out this repository with the main git credentials.
#
# export JENKINS_MAIN_GIT_TEST_REPO_PATH="group/my-test-project.git"

# Whether the built-in backup profile (Velero) can be deployed
# export JENKINS_BACKUP_ENABLED="Y"


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
# Mailu Email Services
# ------------------------------------------------------------------------------

# Whether the Roundcube webmail is enabled
export MAILU_ROUNDCUBE_ENABLED="true"

# Whether email virus-checking service is enbaled
export MAILU_CLAMAV_ENABLED="false"

# Whether the Dovecot IMAP service is enabled
export MAILU_DOVECOT_ENABLED="true"

# The mailer domain (a single domain, may not even be one that receives email)
export MAILU_DOMAIN="${CLUSTER_FQN}"

# The list of mail hosts handled by Mailu (JSON array definition)
# e.g.: "[ 'mail.example.com', 'mail.example2.io' ]"
# If not defined, the ${CLUSTER_FQN} will be used
#export MAILU_HOSTNAMES="[ 'mailu.${CLUSTER_FQN}' ]"

# The admin email MUST be from one of the domains listed in the MAILU_HOSTNAMES
export MAILU_ADMIN_EMAIL="admin@${CLUSTER_FQN}"
# Password for the admin user
export MAILU_ADMIN_PASSWORD="${SK_ADMIN_PASSWORD}"


# The TLS settings for Mailu communications
export MAILU_TLS_FLAVOR="cert"

# The password for the mailu DB user
export MAILU_DB_PASSWORD="${SK_ADMIN_PASSWORD}"

# The secret key is required for protecting authentication cookies and must be set individually for each deployment
# Generate it with the "pwgen" on linux: sudo apt install pwgen && pwgen 16 1
export MAILU_SECRET_KEY="baiph8Chizai7boo"

# No IMAP storage and no ClamAV in this instance, so a smaller PV size is enough
# (only mail forwarding, mail aliases ...etc)
export MAILU_PVC_SIZE="5Gi"

# Whether Mailu frontend needs to be exposed with External-DNS
export MAILU_DEPLOY_EXTERNAL_DNS="true"

# The type of DNS service provider to expose DNS MX record with
# If you change this, ensure that you include fields in
# chart-values-external-dns.yaml as well
export MAILU_EXTERNAL_DNS_PROVIDER="cloudflare"

# Whether TLS certificate with Cert-Manager needs to be requested
export MAILU_CERT_NEEDED="N"

# ------------------------------------------------------------------------------
# Limes (WARNING: DO NOT INCLUDE IN THE TEMPLATE)
# ------------------------------------------------------------------------------
export LIMES_CONFIG="$(resolvePathOnRoots "variables-limes.sh")"
. "${LIMES_CONFIG}"

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
