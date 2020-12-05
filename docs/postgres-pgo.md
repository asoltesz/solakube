# CrunchyData Postgres Operator

For quick and simple Postgres installations, the 'postgres-simple' deployer can be used but that is limited in capabilities (see [the postgres deployer page](postgres.md) for details). 

For higher-end Postgres setups, SolaKube supports the deployment of the [CrunchyData Postgres Operator](https://github.com/CrunchyData/postgres-operator) (PGO in short), which is the subject of this documentation page. 

Features of PGO at a glance:

- multi-node Postgres clusters with streaming replication and proper fail-over
- multiple Postgres clusters within your K8S cluster (Postgres as a service)
- multi-cluster DB user management
- efficient, high-resolution, onsite and offsite backups
- migrations between K8s clusters

See the operator details in the [CrunchyData Postgres Operator Documentation](https://access.crunchydata.com/documentation/postgres-operator/4.2.2/). 

SolaKube tries to simplify certain aspects of PGO in order to allow a faster setup of your Postgres service(s). This results in an opinionated setup but can be customized and extended later.  

SolaKube's does NOT try to implement a highly-optimized, massively scalable, enterprise-level Postgres installation since that requires the in-depth knowledge of both Postgres and PGO from the administrator. SolaKube balances the requirements of a quick and easy-to-understand setup, reliability and performance so that none of those factors suffer unacceptably.

When you become familiar enough with PGO, you can switch to directly using it instead of the helpers provided by SolaKube. For a number of operations you need to use PGO directly anyway, since SolaKube only has dedicated commands for a limited set of operations (e.g.: creating a new PG database cluster)

# PGO Features

Features provided by PGO, in a bit more detail. 

We only discuss those features that are interesting for small/medium sized organizations but must be part of any reliable, production-grade setup. Enterprise-level features are not discussed. 

## Streaming replication and failover

PGO sets up your PG cluster in a way that it allows a multi-node database cluster to operate within your K8S cluster with appropriate, automatic failover. You may use local disks (hostpath storage) for high performance disk access with several Postgres replicas (one primary, one or more standbys).

The primary database node streams its changes to the standby nodes (see [Postgres Streaming Replication](https://www.percona.com/blog/2018/09/07/setting-up-streaming-replication-postgresql/)), so they can follow the primary node very closely in database state and the standbys can relieve the primary from query loads via load-balancing.

If the master Postgres node suffers a catastrophic failure, PGO will automatically promote one of the healthy standbys as master (automatic failover).

## Multiple PG clusters within your K8S cluster

PGO allows for the easy creation of several PG clusters within your K8S cluster. 

Each PG clusters may have separate resource allocation and storage settings. 
E.g.: 

- a production cluster may be created with fast, local disks, big resource allocation and proper backups (local + S3 bucket)
- a staging (pre-prod) cluster can be created with similar resources than the production but with no backups
- a developer cluster may be created with slower storage, limited resources and no backups
- ...etc

Optionally, you may place each PG clusters into their own K8S namespace or keep all of them in the same namespace. NOTE: SolaKube places all of the clusters in the same namespace called "pgo" (which also hosts the operator itself).

NOTE: SolaKube commands always target a single Postgres/PGO cluster (defined by the PGO_CLUSTER variable) 

## Multi-cluster user management

PGO allows for creating/updating DB users in all PG clusters simultaneously. 

## Efficient, high-resolution backups

PGO automatically creates a local backup repository (pgBackrest) within the K8S cluster for each managed Postgres cluster. This is used for quick scale-out (adding standby replicas) and healing failed Postgres nodes.

The local backup repository contains both the WAL files and full/incremental backups for fast recoveries. This is "local" in the sense that it is on the same Kubernetes cluster (typically in the same datacenter as the PG nodes) Incremental backups can be created with high frequency and WAL files are shipped to the local backup storage very quickly.

The WAL and backups may be configured to be pushed automatically into a remote, S3-compatible backup storage. This is much slower than the local repository but it can be offsite, so good backup practices can be followed. S3 compatible storage may be Amazon S3, Wasabi, Backblaze...etc.

Backups are high resolution because the WAL files are archived/saved every minute or when written database file content reaches 16MB. Recovery speed can be further increased with scheduled full/incremental backups (WAL redo can take long if the base backup is very old).

After a disaster event, the database can be recovered for a specific point in time (PITR) or simply the latest state from either the local backup repo or the remote, S3 storage (whichever survives). Via an offsite S3 backup, your data may survive the total loss of your K8S cluster and a relative painless recovery method is provided. 

# SolaKube features and defaults

SolaKube utilizes PGO the following ways:

SK tries to use sensible defaults, assuming a non-trivial, production setup and allows disabling some of the core features.

pgBackrest is always deployed to allow healing failed primaries and standbys. WAL files are always stored, in sync with the full backups saved into the pgBackrest storage spaces.

SK's backup support only targets physical backups with pgBackrest so you cannot upgrade/migrate between Postgres version via these backups. However, logical backups can be taken by using the PGO client directly (see the PGO documentation).

Unless specifically disabled, SK will deploy scheduling for automatic, periodic full backups for the first day of every month. 

Incremental backups will only be scheduled if you provide the schedule for it (see Configuration). Since WAL files following the full backups are always stored, you only need incremental backups if your disaster recovery time limit requires them. For example, when there is high write activity on the database, so that a month-long WAL file-replay would take too much time (in case of a disaster right before the next full/monthly backup).

If OpenEBS is available on your cluster (can be deployed with sk), SolaKube will default to using local disks for maximum database performance (see Storage Configuration).

# Configuration

The following variables need to be defined in variables.sh. 

SolaKube commands helps managing a single PG cluster at a time (identified by PGO_CLUSTER).

## PGO-global variables

### PGO_CREATE_CLUSTER

(Y)es or (N)o.

Defaults to (Y).

Whether it is allowed to automatically create the configured, default Postgres DB cluster after the operator has been deployed to the K8s cluster.

It can be set to (N)o if you want to manually create the first Postgres DB cluster. In this case, only the operator itself will be deployed.

### PGO_CURRENT_CLUSTER

The name of the currently selected cluster definition for SolaKube scripts.

If a PGO-related SolaKube command doesn't get a specific cluster name as a parameter, this will be used instead.

If not set, defaults to **"default"**.

In case, it is "default", the simple/shorter SolaKube variables will be used to describe the DB cluster for PGO. (for example: **PGO_CLUSTER_ADMIN_USERNAME**).

In case it is a non-default DB cluster (e.g. "nextcloud"), then the longer, fully-qualified SolaKube DB cluster variable names will be used. For example: **NEXTCLOUD_PGO_CLUSTER_ADMIN_USERNAME**) 

### PGO_ADMIN_PASSWORD

The password for the root PGO administrator user that can create new Postgres clusters, delete them, can start manual backups, restores...etc.

Optional, defaults to: SK_ADMIN_PASSWORD

## DB-cluster-specific variables 

All configuration variables that has with PGO_CLUSTER_ or <clustername>_PGO_CLUSTER_ are cluster specific.

Cluster specific variables can be defined in two form:

- Variable for the default DB cluster. These are shorter, since the variable name omits the name of the DB cluster. E.g.: PGO_CLUSTER_ADMIN_USERNAME.
- Variable for a non-default cluster. E.g.: PGO_WORDPRESS_CLUSTER_ADMIN_NAME


All variables (e.g.: PGO_CREATE_CLUSTER) are PGO-global and can be defined only once.

### PGO_CLUSTER_NAME

The name of the Postgres cluster within PGO.

Typically, it is the same as PGO_CURRENT_CLUSTER since it is highly recommended using the same cluster names within SolaKube as they are named within PGO.

Nevertheless, it is possible to use a different cluster name within PGO as in SolaKube via this variable. 

If not provided, it defaults to "default".

### PGO_CLUSTER_APP_USERNAME

Application (non-dba) username for the Postgres cluster.

Defaults to the name of the PGO cluster (PGO_CLUSTER_NAME).

A user with this name will be created in the newly created Postgres db cluster.

### PGO_CLUSTER_APP_PASSWORD

Password for the default application (non-dba) user in the postgres cluster.

Optional, defaults to the SK_ADMIN_PASSWORD base variable.

### PGO_CLUSTER_ADMIN_PASSWORD

Admin password for the targeted Postgres cluster (for the postgres user).

Optional, defaults to the SK_ADMIN_PASSWORD base variable.

### PGO_CLUSTER_SERVICE_HOST

The hostname, on which the targeted PG cluster is visible for in-cluster services that need a database (e.g.: Nextcloud).

By Kubernetes rules, this is <clustername>.<namespace>, so in case of default, it is "default.pgo" (SolaKube uses the "pgo" namespace for clusters).

Optional, defaults to <PGO_CLUSTER_NAME>.pgo

### S3 access parameters

If you want to be able to backup your cluster to an offsite S3-compatible storage location, you need to provide your S3 access parameters.

Minimally, the bucket name must be provided (PGO_CLUSTER_S3_BUCKET), all of the others are auto-loaded from your generic S3 access parameters (S3_XXX). In case, you want to specify them for the targeted PG cluster, the prefix is PGO_CLUSTER_S3 and the endings are the same as with the generic S3 parameters.

The PGO_CLUSTER_S3_REPO_PATH specifies the folder of the backups within the S3 cluster. Defaults to "/backrestrepo/<CLUSTER_NAME>-backrest-shared-repo", so in case of default, it is:

~~~
/backrestrepo/default-backrest-shared-repo
~~~ 

#### S3 certificates

PGO/pgBackrest requires that you provide the full public certificate chain for the S3 service.

Place all of them in the following file:
 
~~~
~/.solakube/${SK_CLUSTER}/s3-cert-chain.pem
~~~

You can get the certificate chain from your provider with the OpenSSH client tools:

~~~
openssl s_client -connect s3.eu-central-1.wasabisys.com:443 2>/dev/null </dev/null |  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'
~~~

In certain cases (e.g. Wasabi) the full chain is not provided by the server and you need to manually look up what the root certificates are:

~~~
openssl s_client -connect s3.eu-central-1.wasabisys.com:443
~~~ 

You manually need to export the root certificates in PEM and include them in the file. I use the Firefox gui for this since that includes all current root certificates the S3 services usually refer to.

### Resource allocations

You will need enough CPU and memory allocated for your Postgres pods in order to allow them serving the load you subject them to.

SolaKube does not try to set the requests/limits for pgBackrest and other components, use PGO_CLUSTER_CREATE_EXTRA_OPTIONS to supply these if needed. 
 
#### PGO_CLUSTER_MEMORY

The minimum memory allocation requested for the Postgres pods (in Kubernetes memory units).

Kubernetes will always reserve this amount of memory on the node, and the PG pod will not be able to schedule on a node if there is not at least this amount available.
 
#### PGO_CLUSTER_MEMORY_LIMIT

The maximum memory allocation possible for the Postgres pods (in Kubernetes memory units).

Optional, no default.

If not defined, the Postgres pod may use as much memory on the node as available.

In production Kubernetes workloads, it is recommended that memory limits are set.

Kubernetes may kill the postgres pod if it consumes more than this amount of memory.
  
#### PGO_CLUSTER_CPU

The minimum CPU allocation requested for the Postgres pods.

Kubernetes will always reserve this amount of CPU on the node, and the PG pod will not be able to schedule on a node if there is not at least this amount available.
 
#### PGO_CLUSTER_CPU_LIMIT

The maximum CPU allocation possible for the Postgres pods.

Optional, no default.

In production Kubernetes workloads, it is recommended that cpu limits are set.


### (A)synchronous replication configuration

This concerns the way how streaming replication works between the database nodes of a PG cluster.

Streaming replication is the fastest way to put your Postgres-managed data into a safe place (into one or more standby databases) but even that has two levels of safety.  

With synchronous replication the primary database node will not finish a transaction until it is replicated to at least one standbys. This is the safest, but slowest solution and requires the standby databases to be as fast as the primary.

In case of async replication, the cluster primary node can work faster but the chance of loosing data is higher since the primary can finish a transaction before it is replicated to a standby. In this case your standby nodes can be slower but on average they must still be able to keep up with the primary.

In contrast with streaming replication, WAL file archiving are much slower since they take 1-2 minutes to reach the safety of the pgbackrest backup repository (although the level of safety can be higher in case of an offsite S3 location).

The default with SolaKube is async, but the operator default setting can be changed in the [inventory.ini](../deployment/pgo/inventory.ini) of PGO before deploying the operator (the "sync_replication" key).

Also, you can use the PGO_CLUSTER_CREATE_EXTRA_OPTIONS to supply the "--sync-replication" extra option when creating a cluster to put it in synchronous replication mode.

### PGO_CLUSTER_REPLICA_COUNT

The number of database nodes in the PG cluster.

Defaults to 0 (a single primary, no standby replicas).

### PGO_CLUSTER_CREATE_EXTRA_OPTIONS

Extra options for the ["pgo create cluster"](https://access.crunchydata.com/documentation/postgres-operator/4.3.2/pgo-client/reference/pgo_create_cluster/) command not covered by any of the PGO_CLUSTER_ variables of SolaKube.

This can be utilized if the SolaKube/PGO create mechanism is mostly OK but you want to include some extra options.

### Backup parameters

#### PGO_CLUSTER_BACKUP_LOCATIONS

The backup locations for scheduled/manual database backups and the continuous WAL file archiving.

It can be "s3", "local,s3" or "local".

If you provide the S3 bucket name (see S3 access parameters), it will auto-default to "local,s3", otherwise, defaults to "local".

##### s3

Backups will only be stored in S3. 

A local pgBacrest repo will still be created for node healing (WAL files) and scale-out but cannot hold backups.

##### local,s3

Backups can be stored in both s3 and the local pgBackrest repository

Manually started backups can specify both as backup target, so different backups can be stored in them. E.g.: Higher incremental backup frequency for the local.

Both repositories will contain the WAL files as soon as can be shipped to them from the primary.

##### local 

Backups will only be stored in the local, in-cluster pgBackrest repositories.

In this case, there is no offsite backup, so if the whole K8s cluster or only the critical data PVCs are lost, you cannot recover from the disaster.

Only suitable if your pgBackrest repository storage class ensures the availability needed for your Disaster Recovery requirements (see Storage Configuration). Should only be used with durable storage (e.g.: Hetzner Cloud Volumes which stores all data on 3 machines). 

#### PGO_CLUSTER_BACKUP_SCHEDULED_LOCATIONS

The storage locations of scheduled backups.

Accepts the same values as the generic config (PGO_CLUSTER_BACKUP_LOCATIONS).

Can only be a target that is also included in PGO_CLUSTER_BACKUP_LOCATIONS, otherwise scheduled backups will fail.

#### PGO_CLUSTER_BACKUP_FULL_SCHEDULE

The cron schedule of the full backups.

If not specified, full backups will not be scheduled.

If the schedule script is started manually, it defaults to "0 0 1 * *" (on the first day of each month, at 00:00)

#### PGO_CLUSTER_BACKUP_FULL_RETENTION

The number of full backups to retain 
    
Defaults to 6.

Together with the default schedule, this results in a full backup retention for 6 months. (unless manual backups are made, which will shorten it)

#### PGO_CLUSTER_BACKUP_INCR_SCHEDULE 

The cron schedule for incremental backups.

It has no default.

If not specified, incremental backups will not be scheduled and only full backups + WAL will be used for recoveries (this may take longer than with incremental backups if a lot of WALs have been collected since the last full backup).

### Storage configuration

A PGO-managed Postgres cluster uses Kubernetes Persistent Volume Claims (PVCs) to allocate storage for various components.

PVCs are allocated for these purposes

- primary - The storage for the primary database node. Should be the fastest storage available. This doesn't need to be highly available, especially if you run standby nodes as well.

- replica - The storage for the standby nodes. Should be as fast as the primary if synchronous replication is used, may be slower if async replication is used (see PGO docs and the replication configuration above)

- wal - The storage for the WAL files not yet shipped to backup locations. WAL storage can be slower than primary/replica since the write amount is less than on the actual database files.

- backrest - The storage for the local pgBackrest repository PVC holding the local backups and WAL files.

The inventory.ini file contains the default, operator-level storage settings that can be assigned to these functions. Even though their purpose is broader, in SolaKube, these are treated as Kubernetes storage classes and the base PGO set is extended with OpenEBS, Rook and Hetzner Cloud Volumes. 

SolaKube automatically configures these, unless specific setting is not provided for them: 

In order of precedence:
- If OpenEBS is installed on the cluster, it configures the primary and replica to local hostpath for maximum database performance. 
- If Rook is deployed on the cluster, it will configure the non-configured storage settings to **rook-ceph-block**
- If Hetzner Cloud Volumes are available, it will configure the non-configured storage settings to **hcloud-volumes** (Hetzner Cloud Volume)
- If the environment is Minikube, then the **standard** storage class will be available, and the non-configured storage settings will be configured to this class.

You can manually override the storage settings for each storage types with the following variables in variables.sh:

- PGO_CLUSTER_PRIMARY_STORAGE_CLASS
- PGO_CLUSTER_REPLICA_STORAGE_CLASS
- PGO_CLUSTER_BACKREST_STORAGE_CLASS
- PGO_CLUSTER_WAL_STORAGE_CLASS

Each of these variables can be set to a concrete value (e.g: "rook-ceph-block") or the list of preferred storage classes (e.g: "openebs-hostpath,rook-ceph-block,hcloud-volume,standard"). In tha latter case, the first class available on the K8s cluster will be utilized.

The class based on these variables will be set to the PGO defaults when the operator itself is deployed.

The variables are also used when the DB cluster-create operation is used so, if you manually create your first DB cluster, you may use different values compared to the operator-level defaults. Same for other DB clusters created manually later on.

Initial PVC sizes can also be configured with the following variables:

- PGO_CLUSTER_PRIMARY_STORAGE_SIZE
- PGO_CLUSTER_BACKREST_STORAGE_SIZE
- PGO_CLUSTER_WAL_STORAGE_SIZE

All sizes are "1Gi" by default. Replicas don'thave separate setting, they use the same value as the primary.

If your volumes cannot be dynamically resized, make sure that they are big enough for the foreseeable future.

# Deployment of PGO

With the following command:

~~~
sk deploy pgo
~~~

This should:

- Deploy the PGO operator on the cluster
- Create the default/first Postgres DB cluster with all of its components (if not disabled)
- Create the local pdBackrest repository within the cluster
- Create the pdBackrest repository in your S3 bucket (if S3 is configured))
- Create an initial, full backup, starts streaming the WAL files
- Schedules the automatic full backups (if schedule is provided)
- Schedules the incremental backups (if schedule is provided)


# Using PGO to manage Postgres clusters

## Running PGO client commands directly

The PGO CLI client can be installed directly on the administrator machine (see CrunchyData docs), or you can log into the PGO client Docker container with the following SK command:

~~~
sk pgo client-shell
~~~

NOTE: SolaKube always installs the PGO client pod on your cluster.

Alternatively, you can install the PGO client directly on your machine (see the PGO docs for instructions).

## Creating the DB cluster

After the configuration has been done, the cluster can be created with the following SolaKube command:

~~~
sk pgo create-cluster
~~~

NOTE: You can create several PG clusters by modifying the PGO_CLUSTER_NAME variable, optionally changing the config parameters, and re-executing the command. 

The create-cluster command also accepts the SolaKube name of the DB cluster like this:

~~~
sk pgo create-cluster default
~~~

## Testing the cluster

Deploy pgadmin with the appropriate SK deployer.

Then on the UI, create a Server entry with the username (PGO_ADMIN_USERNAME) and password (PGO_ADMIN_PASSWORD) with the host path set into POSTGRES_SERVICE_HOST.

Connect to the server, open a Query Tool tab and execute the following SQL statements:

~~~
CREATE TABLE fruit (
  id VARCHAR(100) PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO fruit (id) VALUES ('apple');
INSERT INTO fruit (id) VALUES ('pear');
INSERT INTO fruit (id) VALUES ('cherry');

SELECT * FROM fruit;

-- Cleaning up
DROP TABLE fruit;
~~~

If there was no error when executing the statements, your database cluster should be functional.

## Starting a manual backup

In case you need to take a backup manually (as opposed to the automatic, scheduled backups) SolaKube provides a helper script which wraps the "pgo backup" command which allows to take a backup with pgBackrest.

~~~
# A full backup to s3 storage (slower)
sk pgo backup "s3" "full"

# An incremental backup to the local pgbackrest repo
sk pgo backup "local" "incr"

# A full backup to the default backup storage places, tracking for 20 minutes
# (the DB is big, it will complete lower)
sk pgo backup "" "full" 1200
~~~

If you have multiple PG clusters, ensure the PGO_CURRENT_CLUSTER is set appropriately.

In more complex cases, start a PGO client shell (see earlier) and execute a manually constructed pgo backup command.

## Restoring a PG cluster from backups

### When the DB cluster is lost

In this case, the local backup repository is also lost, so you can only recover the data from the S3 repository.

Restoring from S3 backups may be necessary in the following scenarios:
- total loss of the K8s cluster (the local backup repository is lost too or we didn't even keep local backups, only remote S3 backups)
- total loss of a specific Postgres cluster (backing PVCs lost or corrupted, so neither the local backup repo nor the database itself survived) 
- migrating the Postgres cluster into a new K8s cluster (old one will be removed)

Currently, there is no formal documentation about this in PGOs docs so only this [issue](https://github.com/CrunchyData/postgres-operator/issues/1305) serves as the basis for our instructions.

With the following SolaKube command:

~~~
sk pgo create-cluster default Y 
~~~

In this case "default" is the name of the cluster in SolaKube.

The last parameter (Y) will instruct SolaKube that the cluster creation is to be done with restoring the database-cluster content from the S3 backups.

The S3 access parameters need to be configured for the DB cluster (see configuration).

After the successful recovery, you need to manually promote the cluster from standby state (read-only) to working (read/write):

~~~
sk pgo client-shell

pgo update cluster default --promote-standby
~~~ 

("default" is the name of the database cluster in PGO)


### When the DB cluster is not completely lost

If the Postgres cluster only suffered a data corruption but otherwise would be operational, you may recover from both the local backups and from s3 (if it was configured at cluster creation time).

You can use the "pgo restore" command directly from the PGO client-shell:

~~~
pgo restore default --pgbackrest-storage-type=s3 ...
~~~
 
or the SolaKube wrapper with 3 different parametering:

~~~
# Last backup from local repo
sk pgo restore local

# Point In Time Recovery from S3
sk pgo restore s3 "2020-06-07 19:20:00.000000-02"

# Point In Time Recovery from local, tracking the restore for at least 30 minutes
# (default tracking stops at 10 minutes)
sk pgo restore local "2020-06-07 19:20:00.000000-02" 1800
~~~

If you have multiple PG clusters, ensure the PGO_CURRENT_CLUSTER is set appropriately.

# Miscellaneous

## Tracking the success of PGO operations

As of v4.3.2 the PGO command line client doesn't provide any tracking for the operations it starts. It starts the operation and displays what it starts but then the user/administrator is left without the actual result and has to manually check for problems and issues. See this [feature request](https://github.com/CrunchyData/postgres-operator/issues/1604)

For the few operations supported/wrapped by SolaKube there is tracking for the task completion itself (success or fail) but logs and error statuses are not returned. In case you want to implement tracking for your own automation, you may be able to use the tracking code in pgo-shared.sh.


# Troubleshooting

Unfortunately, as of version 4.3.2 PGO doesn't provide easy ways to track the success of its operations.

You need to manually query pod statuses with kubectl (or the dashboard) and take logs from pods to investigate issues.

In the examples, I will use pod names that assume the Postgres cluster name 'default'

## pgBackrest stanza-create error for S3

The job "default-stanza-create" fails.

Possible reasons:

### S3 provider doesn't support URI-style bucket names

The bucket must be available as a hostname. E.g.: s3.eu-central-1.wasabisys.com

In case of using Minio, you need to ensure that the bucket is also accessible on a hostname (e.g.: via a hand-deployed service).

URI style S3 bucket URL-s are not yet supported in PGO but may become possible [if this issue is fixed](https://github.com/CrunchyData/postgres-operator/issues/1228) because pgBackrest itself is capable of handling URI-style paths.

### S3 access parameters are wrong

Check if you can write into the S3 bucket with your credentials.

### The S3 bucket has already been used to backup a PG7173271b-532a-44e8-bffd-d8fd9985efa9 cluster named default

You need to use a different S3 bucket or manually remove the pgbackrest folder created for the backups of the cluster in question. 