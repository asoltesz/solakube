# Velero based backups

Velero is a backup operator for Kubernetes that has support for saving: 
- Kubernetes object descriptors
- files stored in persistent Volumes (PVCs) 

SolaKube aims to simplify the most common backup/restore configurations with sensible Velero defaults. 

Applications get their backup scheduled profiles individually (typically, per-namespace).

For the applications directly supported by SolaKube there are pre-made backup profiles that can be automatically deployed should you want to use them on your cluster.

The targeted use-case:
- One application is placed in one Kubernetes namespace. Multiple applications cannot share the same namespace
- Backups will be placed in a shared S3 location/bucket or an application may request
  a specific S3 location/bucket
- Application backups are executed automatically, according to a schedule set
  individually to the application (or the default schedule set by SolaKube)
- Kubernetes object definitions will be backed up
- Persistent Volumes will be periodically backed up 

The application/namespace backups are designed to work in tandem with a full etcd backup of the cluster. This can be done with Rancher automatically, periodically. The application backup should be scheduled after the etcd backup for best consistency.

Besides the application backups, there is a "Cluster" backup profile that takes cluster-level resources and infrastructure component namespaces together. 

While Velero supports backing up the whole cluster in one go, that would take a lot of time for any non-trivial cluster. We opt for smaller, more granular backups that have only one application in their scope but finish much faster. This reduces the chance of having inconsistent backups. Also, per-application backups allow for more flexible scheduling (e.g. higher backup frequency for certain apps).  

See the [limitations](#limitations) for a proper view of the capabilities of Velero and the integration provided by SolaKube.


# Configuration

## SolaKube-default S3 endpoint

For storing the backups, you need to provide access parameters to an S3 compatible remote storage repository.

SolaKube has the option to default a default S3 endpoint for all services.

For the Solakube-default S3 endpoint, you can set the access parameters centrally in variables.sh:
~~~
# export S3_ENDPOINT="xxx"
# export S3_ACCESS_KEY="xxx"
# export S3_SECRET_KEY="xxx"
# export S3_REGION="xxx"
~~~

Unless configured otherwise, Velero will use the above central S3 endpoint.


## Velero-specific, default S3 endpoint

If needed, Velero can have a specific S3 endpoint so that is different from the Solakube-default.

~~~
# Overriding the default S3 access parameters for Velero backups
#export VELERO_S3_ENDPOINT=xxx
#export VELERO_S3_ACCESS_KEY=xxx
#export VELERO_S3_SECRET_KEY=xxx
#export VELERO_S3_REGION=xxx
~~~

If set Velero will store all backups on this endpoint by default.

NOTE: It is possible to store certain application backups in different endpoints and buckets. For this see the "Application-specific S3 location" section.
 

## The default Velero S3 bucket

Whatever S3 endpoint is used, a specific bucket also needs to be named, in which Velero should store the backups within the location.

Set it in the default parameter in variables.sh:

~~~
# The storage for all Velero based backups
export VELERO_S3_BUCKET_NAME="andromeda-velero-backups"
~~~ 

Velero keeps a specific folder structure in the bucket. Basically, Kubernetes objects and restic backups are stored in subfolders named according to the backup profile (see the Velero docs for specific details).

NOTE: It is possible to store certain application backups in different endpoints and buckets. For this see the "Application-specific S3 location" section.


# Enabling backup profile deployment

In general, the built-in SolaKube application backup profiles will only be deployed if they are allowed, in order to account for the case when you want to deploy/use Velero but you want to define your own backup profiles/strategy for the applications.

~~~
export VELERO_APP_BACKUPS_ENABLED="Y"
~~~

If not specified, application backups are enabled by default and will be deployed.

If you set this to "N", SolaKube backup profiles will not be deployed for any of the applications and you need to craft those by yourself.
 

# Installing the Velero client CLI to your machine

Use public guides or the following command:

~~~
sk deploy-script velero install-cli.sh
~~~

Without this, none of the backup operations and application profile deployments can happen because SolaKube uses the CLI client to define the Velero resources in the cluster.

Test the installation:

~~~
velero version
~~~

# Deploying Velero to the cluster

Either during the original cluster building by setting this in variables.sh:

~~~
export SK_DEPLOY_VELERO="Y"
~~~

Or, afterwards, by executing the SolaKube deployer:

~~~
sk deploy velero
~~~


# Deploying application backup configurations/profiles

For most applications that have a SolaKube deployer, there is a pre-built backup profile.

That usually only needs minimal configuration (e.g: retention and scheduling).

You may also use SolaKube's Velero support do deploy backup profiles for your own application deployments.

## Ensuring pod annotations for Velero

As of version 1.4, Velero requires that pods are labeled so that Restic is allowed to backup their PVCs.

For applications that have a SolaKube pre-built backup profile, this annotation is solved, typically as part of the application deployment process.

Placing the annotation directly on a pod:
~~~
kubectl get pod -n pgadmin
 
kubectl annotate \
    pod/pgadmin-7cd84f9484-t6m4b \
    backup.velero.io/backup-volumes=pgadmin-data \
    -n pgadmin 
~~~

For details, see the [Velero/Restic documentaion](https://velero.io/docs/v1.3.2/restic/).

WARNING: Placing the annotation directly on the pod is not sufficient for long term because that will not survive a pod restart. These annotations are better placed via the Deployment pod specification.



## Backup schedule and retention

As of v1.4, Velero has no proper retention policy support for backups, only retention based on TTL. See this [issue](https://github.com/vmware-tanzu/velero/issues/2267).

SolaKube approximates a daily/monthly/yearly counting-based retention policy with creating multiple schedules for daily, monthly, yearly backups. See the relevant limitation section below to understand the mechanism better.

~~~
# The backup schedule cron expression for automatic starting of the backup

# Every day, 01:00 in the morning
cexport BACKUP_SCHEDULE_DAILY "0 1 * * *"
# First day of the month, 03:00 in the morning
cexport BACKUP_SCHEDULE_MONTHLY "0 3 1 * *"
# First day of the year, 05:00 in the morning
cexport BACKUP_SCHEDULE_YEARLY "0 5 1 1 *"

# Retention of different backups
# If the retention is 0 (zero), the schedule will not even be deployed.
export BACKUP_RETENTION_DAILY=30
export BACKUP_RETENTION_MONTHLY=6
export BACKUP_RETENTION_YEARLY=0
~~~

## Application-specific S3 location

It is possible to to save certain applications's backups to separate S3 repos or different buckets.

You need the set a specific Velero Backup Location name for this:
~~~
export PGADMIN_BACKUP_LOCATION_NAME="not-the-default"
~~~
Without this the backup will be stored in the default Velero backup location (S3).

### Defining a new Velero backup location

You need to manually create the Velero backup location before you deploy the backup profile that targets that location. See the [Velero documentation about locations](https://velero.io/docs/v1.3.2/locations/).  

NOTE: You will need to manually add the access and secret key to the secret called "velero" in the "velero" namespace:

~~~
[default]
aws_access_key_id = xxx
aws_secret_access_key = xxx

[pgadmin]
aws_access_key_id = xxx
aws_secret_access_key = xxx
~~~

## Namespaces included/excluded

### Namespaces included into the backup

In case the namespace differs from the name of the application:

~~~
export PGADMIN_BACKUP_NAMESPACES=pgadmin2
~~~

This is optional and defaults to the name of the application (e.g.: pgadmin).

In case, the "none" value is specified, SK will not default it to the application name and all namespaces will be included into the backup. This is not typically needed for application backups and used for infrastructure/cluster-level backup (see the Infrastructure backup profile section). In case you set this "none", you may want to exclude namespaces like kube-system. See exclusions below. 

NOTE: In Velero, this is the --include-namespaces parameter 

### Namespaces excluded from the backup

~~~
export PGADMIN_BACKUP_NAMESPACES_EXCLUDED="kube-system"
~~~

This is optional and can be left empty.

NOTE: In Velero, this is the --exclude-namespaces parameter 

## Cluster-level resources

Velero allows backing-up cluster-level resources (like Cert-Manager's Certificate Issuer).

This is not needed for simple application backups and used for infrastructure/cluster-level backups (see the Infrastructure backup profile section)

~~~
export PGADMIN_BACKUP_CLUSTER_RESOURCES="false"
~~~

This is optional and defaults to "false".

NOTE: In Velero, this is the --include-cluster-resources parameter 

## Resource types to be included/excluded

### Resource types to be included in the backup

It is possible to limit Velero backups to certain K8S resource types (e.g.: secrets).

~~~
export PGADMIN_BACKUP_RESOURCES="*"
~~~

This is optional and defaults to "*" (all resource types to be included).

NOTE: In Velero, this is the --include-resources parameter 

### Resource types to be excluded from the backup

It is possible to exclude K8S resource types (e.g.: secrets) when the resource inclusion is "*".

~~~
export PGADMIN_BACKUP_RESOURCES_EXCLUDED=""
~~~

This is optional and defaults to empty (no resource types to be excluded).

NOTE: In Velero, this is the --exclude-resources parameter 


## Deploying the backup profile

In case an application has a pre-built backup profile, you can deploy it similarly to this pgAdmin example:

a) Before the original cluster building by setting the appropriate variable:
~~~
export SK_DEPLOY_PGADMIN_BACKUP="Y"
~~~

b) After the original cluster building, with a specific deploy command:
~~~
sk deploy-script pgadmin backup-config.sh
~~~


# Secondary backup profiles

For an application, it is possible to define multiple backup profiles in addition to the default.

Parameter names in this case contain the backup profile as well:

For example, in case of a 'secondary' backup profile:
~~~
PGADMIN_SECONDARY_BACKUP_NAMESPACES="pgadmin3"
~~~ 

Deploying a secondary backup profile schedule:

~~~
sk velero backup schedule pgadmin secondary
~~~


# The 'Cluster' and 'Schedules' backup profiles

SolaKube separates backups into three categories:
- Cluster-level resources like ClusterRoles, Nodes...stc ("Cluster" backup)
- Velero backup schedules ("Schedules" backup) 
- "Normal" application backups
  - Gitea, Nextcloud, pgAdmin...etc
  - typically with persistent volumes as well

Schedules for the Cluster and Schedules backup are deployed immediately when Velero is installed to the cluster by SolaKube.

The Schedules and Cluster backups, by default, do not deal with persistent volumes, only take Kubernetes objects. Normal applications usually contain persistent volumes as well.

Backup parameters for these backups can be customized the same way as any other backup profiles (e.g.: schedule, labels).

Taking them manually:

~~~
sk velero backup execute velero schedules
sk velero backup execute velero cluster
~~~ 

# Backing up

## Manually

Executing a backup with a profile with immediate start:

~~~
sk velero backup execute pgadmin default
~~~

## Scheduled, automatic

The scheduled backup profiles will be executed automatically by Velero when their schedule make it necessary.

# Restoring from backups

## Restore from latest backup

Restore the manual backup you took before destroying the Nextcloud namespace.
~~~
sk velero restore pgadmin default 
~~~

NOTE: This will auto-query the last fully successful backup and restore from that.

## Restore from earlier backup (optional)

In case you need to restore from an earlier backup, you can query the exact name / time of the backups and restore from tha one you find suitable:
~~~
velero get backup | grep pgadmin-default

sk velero restore pgadmin default "--from-backup=pgadmin-default-20200724-2333"
~~~


# Application disaster recovery test

Manually verifying the installation.

Demonstrated vie the SolaKube Nextcloud deployment.

## Check pod annotation 

Velero pod annotation is handled automatically by the SolaKube deployer for Nextcloud.

To check if they are present:
~~~
# Query pods to see the exact pod name
kubectl get pod -n nextcloud

# Describe pod
kubectl describe pod/nextcloud-XXXXXXX-XXXXX \
  -n nextcloud 

# The "backup.velero.io/backup-volumes=nextcloud-data" annotation must be present
# in the "Annotations" field 
~~~

## Create backup 

Back up an application (only those PVCs are backed up with Restic which are specifically annotated via their pod)

~~~
sk velero backup execute nextcloud 
~~~

Check the backup results according to the instructions on screen

Similarly to this:

~~~
velero backup describe nextcloud-default-20200724-2333 --details 
~~~

The "Phase" field must be "Completed".

The "Restic Backups" \ "Completed" field must list a single nextcloud-data PVC that was needed to be backed up. 

The "Resource List" should contain all of the Kubernetes objects you have deployed in the nextcloud namespace.  


## Simulate disaster scenario

Drop application namespace (but keep its Postgres database).

~~~
kubectl delete namespace nextcloud
~~~

## Restore 

Restore the manual backup you took before destroying the Nextcloud namespace.
~~~
sk velero restore nextcloud 
~~~


## Check the application

Wait until Nextcloud starts up.

Check if everything works properly in Nextcloud (file syncing, your manually installed Nextcloud applications...etc)


# Limitations

Velero currently doesn't have support for consistent, online filesystem backups with Restic, so your workloads need to be stopped for backup or must be able to tolerate filesystem backups that are potentially captured over a longer period of time (as opposed to point-in-time filesystem snapshots). See the connected VolumeSnapshot details below as well.

The built-in simplifications of SolaKube target the most common scenario for an application when there is a Kubernetes namespace with one or more deployments with persistent volumes mounted to the pods of the deployments. This is covered with one SolaKube DR 'profile'.

## File Excludes

At the moment Velero doesn't seem to support file exclusions so that files within a root folder (backed up by Restic) could be filtered. 

## Excluding Kubernetes objects

Excluding specific Kubernetes object definitions from the backup is currently not supported by SolaKube but is supported by Velero. 

This should normally not be a problem when backing up application namespaces (as opposed to backing up a whole cluster). 

## VolumeSnapshots and consistent online filesystem backups are not supported

Velero is capable of automating the scheduled creation of VolumeSnapshots which is the proper way to make consistent, online backups from workloads (point-in-time snapshotting of PVCs).

However, Velero can only back the filesystem content of a VolumeSnapshot up in a remote backup repository (like S3 or B2) if the storage provider is specifically supported. Neither Rook/Ceph, nor Hetzner Cloud Volumes are supported by Velero ATM. 

This means that in case of SolaKube's in-cluster Rook/Ceph storage, a backup like this cannot survive the destruction of the cluster (or even the loss of the Ceph storage cluster nodes). 

In case of a typical single-datacenter cluster, the loss/unavailability of that datacenter would mean that the VolumeSnapshot backups also become unavailable/lost.

Of course, the complete loss/unavailability of a datacenter is fairly unlikely, but basic disaster recovery principles say that backups should always be remote to the site from which they originate. 

Moreover, Hetzner Cloud Volumes don't support taking VolumeSnapshots at all, so this kind of snapshotting backup could only be used with the Rook/Ceph storage provisioner.

Due to the above limitations, currently there is no way to take a consistent backup from a workload while that is online (under load) with Velero and safely store it remotely.

Hopefully this will change soon, and a hybrid VolumeSnapshot + Restic solution will be developed in Velero as [suggested in this issue](https://github.com/vmware-tanzu/velero/issues/2671).

A secondary, major problem is that Velero only supports the VolumeSnapshot v1beta1 API that requires Kubernetes 1.17+. SolaKube currently targets 1.15.11. Hopefully, we will [migrate to 1.17+ sometime in the future](https://github.com/asoltesz/solakube/issues/21) and this issue will be a barrier no more.

As a result, SolaKube cannot - as of yet - support VolumeSnapshot based backups.

## Coarse retention

As of v1.4, Velero has no proper retention policy support, only retention based on TTL.

See this [issue](https://github.com/vmware-tanzu/velero/issues/2267).

SolaKube approximates a daily/monthly/yearly counting-based retention policy with creating multiple schedules for daily, monthly, yearly backups. This is more wasteful from both backup execution resource needs and also wastes some percentage of storage space.

In case you define all of the daily, monthly, and yearly schedules there will be days when the backup schedule gets executed 3 times (once a year), 2 times (every month). 


