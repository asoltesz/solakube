# Stash based filesystem backups

Stash is an operator for Restic and allows taking filesystem backups from stateful workloads.

SolaKube aims to simplify the most common backup/restore configurations with sensible Stash defaults. Persistent Volumes will be periodically backed up by Stash/Restic to a remote, out-of-site, out-of-cluster location (any S3 compatible repository) 

For the applications directly supported by SolaKube there are pre-made backup profiles that can be automatically deployed should you want to use them on your cluster.

See the [limitations](#limitations) for a proper view of the capabilities of Stash and the integration provided by SolaKube.

# Deploying Stash

Stash needs to be deployed on the cluster in order to have generic filesystem backups/restores.

Either during the original cluster building by setting this in variables.sh:

~~~
export SK_DEPLOY_STASH="Y"
~~~

Or, afterwards, by executing the SolaKube deployer:

~~~
sk deploy stash
~~~

# Basic configuration

For storing the backups, you need to provide access parameters to an S3 compatible remote storage repository.

For a normal S3-compatible service, you can set the access parameters centrally in variables.sh:
~~~
# export S3_ENDPOINT="xxx"
# export S3_ACCESS_KEY="xxx"
# export S3_SECRET_KEY="xxx"
# export S3_REGION="xxx"
~~~

In case of BackBlaze B2, you need to use the B2S3 module to make it S3 compatible. See the [B2S3 module page](backblaze-b2-s3-storage.md) for configuration and details. When B2S3 is marked for deployment (SK_DEPLOY_B2S3=="Y") S3 parameters get auto-defined from the B2 ones.


# Deploying backup configurations/profiles

## The default bucket

In case you want to store all of your application backups in one storage bucket, set it in the default parameter in variables.sh:

~~~
export STASH_REPO_DEFAULT_BUCKET_NAME="mycluster-stash-backups"
~~~

In case of no specifi instruction for an application's backup, a subfolder will be created for the application (e.g.: pgadmin) in the shared bucket and the backups will be stored there. 

## Typical customizations

You can customize some of the backup parameters for each application:

~~~
# The name of the storage bucket to store the backups of the application in
# If not defined, the default bucket will be used
export PGADMIN_BACKUP_REPO_BUCKET_NAME="pgadmin-backups"

# The path of the folder within the bucket
# If not defined, it will be auto-defined 
export PGADMIN_BACKUP_REPO_PREFIX="/path/within/bucket"

# The backup schedule cron expression for automatic starting of the backup
# If not defined, it will start at every day at 23:00
export PGADMIN_BACKUP_SCHEDULE="0 23 * * *"

#
# The retention policy of the backup (in JSON format, see the Stash docs)
#
# If not defined, the following will be applied:
# - The last backup in every day will be kept for 7 days 
# - The last backup in every week will be kept 4 weeks
# - The last backup for every month will be kept for 6 months
# - Files that are not referenced from any backups will be deleted 
#
export PGADMIN_BACKUP_RETENTION_POLICY="{}"
~~~

## Overriding generic S3 access parameters for all Stash backups

It is possible to override the default S3 access parameters for Stash backups (but not for other possible S3 user workloads):

~~~
export STASH_S3_ENDPOINT=xxx
export STASH_S3_ACCESS_KEY=xxx
export STASH_S3_SECRET_KEY=xxx
export STASH_S3_REGION=xxx
~~~

## Overriding S3 access parameters per application

It is possible to override the default S3 access parameters for each applications in order to save certain backups to separate S3 repos:

~~~
export PGADMIN_BACKUP_S3_ENDPOINT=xxx
export PGADMIN_BACKUP_S3_ACCESS_KEY=xxx
export PGADMIN_BACKUP_S3_SECRET_KEY=xxx
export PGADMIN_BACKUP_S3_REGION=xxx
~~~

## Deploying the profile

In case an application has a pre-built backup profile, you can deploy it similarly to this pgAdmin example:

a) Before the original cluster building by setting the appropriate variable:
~~~
export SK_DEPLOY_PGADMIN_BACKUP="Y"
~~~

b) After the original cluster building, with a specific deploy command:
~~~
sk deploy pgadmin deploy-backup-config 
~~~


# Building backup profiles

You may build backup profiles for the filesystem backups of your own applications in case they are deployed with a Kubernetes DeploymentConfig.

Always/often needed parameters (for the default profile)

~~~
# The name of the DeploymentConfig in the namespace of the application
export PGADMIN_BACKUP_DEPLOYMENT_NAME="pgadmin"

# The name of the Persistent Volume 
export PGADMIN_BACKUP_DATA_VOLUME_NAME="pgadmin-data"

# The path of the data folder within the container (to be backed up)
export PGADMIN_BACKUP_DATA_FOLDER_PATH="/var/lib/pgadmin"

# The security context (e.g.: if the container runs with a specific user ID and 
# the backup cannot run as root but has to run with the same user ID as the
# application container
# See details in the Stash documentation
export PGADMIN_BACKUP_SECURITY_CONTEXT="{}"
~~~

Rarely needed customizations
~~~
# The name of the Stash Repository object in the namespace
# Optional, auto-calculated from the profile name
export PGADMIN_BACKUP_REPO_NAME=xxx

# The namespace into which the backup objects need to be deployed
# (should be the same as the application)
export PGADMIN_BACKUP_NAMESPACE=pgadmin
~~~

Manually deploying a non-built-in filesystem backup profile defined with variables for the 'pgadmin' application: 
~~~
sk stash deploy-fs-config pgadmin
~~~


# Secondary backup profiles

For an application, it is possible to define multiple backup profiles in addition to the default.

Parameter names in this case contain the backup profile as well:

For example, in case of a 'secondary' backup profile:
~~~
# The name of the DeploymentConfig in the namespace of the application
export PGADMIN_SECONDARY_BACKUP_DEPLOYMENT_NAME="pgadmin"

# The name of the Persistent Volume 
export PGADMIN_SECONDARY_BACKUP_DATA_VOLUME_NAME="pgadmin-data"
~~~ 

Deploying a secondary filesystem backup profile:

~~~
sk stash deploy-fs-config pgadmin secondary
~~~



# Limitations

The built-in simplifications of SolaKube target the most common scenario when there is a Kubernetes Deployment with one PersistentVolume mounted into one folder within your container. This is covered with one SolaKube DR 'profile'.

## Multiple PVCs or root folders

In case there are multiple PVCs, you either craft the Stash configuration for them manually, or each of them can have a dedicated SolaKube DR Profile. (see the "Secondary backup profiles" section)

## File Excludes

At the moment Stash doesn't seem to support file exclusions so that files within a root folder (backed up by Restic) could be filtered. 

Relevant [question](https://github.com/stashed/stash/issues/1098) for the Stash team.

## Workloads based on StatefulSets

StatefulSets are not yet supported by the SolaKube DR config generator but Stash supports them. 

In case your workload uses them, you can create a Stash configuration files manually (Repo, BackupConfigurations).

## VolumeSnapshots not yet supported

Stash is capable of automating the scheduled creation of VolumeSnapshots which is the proper way to make consistent, online backups from workloads (point-in-time snapshotting of PVCs).

However, Stash cannot back the filesystem content of a VolumeSnapshot up in a remote backup repository (like S3 or B2). This means that in case of SolaKube's in-cluster Rook/Ceph storage, a backup like this cannot survive the destruction of the cluster (or even the loss of the Ceph storage cluster nodes). 

In case of a typical single-datacenter cluster, the loss/unavailability of that datacenter would mean that the VolumeSnapshot backups also become unavailable.

Of course, the complete loss/unavailability of a datacenter is fairly unlikely but the basic disaster recovery principle says that backups should always be remote to the site from which they originate. 

Moreover, Hetzner Cloud Volumes don't support taking VolumeSnapshots at all, so this kind of backup could only be used with the Rook/Ceph storage provisioner.

Due to the above limitations, currently there is no way to take a consistent backup from a workload while that is online (under load) with Stash and safely store it remotely.

Hopefully this will change soon, and a hybrid VolumeSnapshot + Restic solution will be developed in Stash as [suggested in this issue](https://github.com/stashed/stash/issues/1099).

A secondary, major problem is that Stash only supports the VolumeSnapshot v1beta1 API that requires Kubernetes 1.17+. SolaKube currently targets 1.15.11. Hopefully, we will [migrate to 1.17+ sometime in the future](https://github.com/asoltesz/solakube/issues/21) and this issue will be a barrier no more.

As a result, SolaKube cannot - as of yet - support VolumeSnapshot based backups. Alpha-level command scripts are provided in the stash command script folder but they have not been tested with a full, successful backup/restore cycle. 