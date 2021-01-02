# Disaster Recovery

SolaKube integrates Velero as the base Disaster Recovery (DR) solution.

The Postgres (and databases in general) has special needs in terms of disaster recovery, so it is not in the scope of the Velero based DR system (see below).

# Data Protection and Disaster Recovery Strategy

The strategy consists of:
- Application/Infra-Component level filesystem (PV) and Kubernetes configuration backups (Velero)
- Cluster-level Kubernetes configuration backups (Velero)
- PostgreSQL db cluster backups (WAL archiving to S3 + periodic backups)
- Single-application recovery strategy:
  - Restoring Kubernetes objects and PVC data from Velero backups (S3)
  - Latest DB state (PGO/pgBackrest)
- Strategy for Complete-Cluster-Loss scenario 
  - re-creating the cluster
  - reinstalling the infrastructure components
  - recovering application configuration and data files from Velero backups
  - recovering application database data from PGO database backups
- Requirements for successful recoveries
  - Velero and PGO/pgBackrest backups
  - for Complete-Cluster-Loss scenarios:
    - The SolaKube cluster definition files (typically versioned as a git repo) available and fully up-to-date (e.g.: the OpenEBS configuration, Cert-Manager parameters...etc)
    - A working SolaKube installation to re-create a bare cluster as the base of the recovery 

## Data Protection

The following kinds of data is covered by the strategy.

### Database data (PostgreSQL)

The PostgreSQL database-as-a-service functionality (PGO) ensures that database changes are saved with ~1 minute timeout to S3 and/or a local pgBackrest repo (WAL archiving). This also allows scheduled backups (full, incremental, differential). Postgres data-page checksums are activated by default.

NOTE: MySQL has no built-in support, an operator like PGO needs to be used for this. 

### File data (Persistent Volumes)

PVs are backed up to S3, using Velero's built-in Restic filesystem backup functionality.

NOTE: PV Snapshotting is not yet directly supported (see the Velero page for reasons).

### Kubernetes objects & application configuration

Kubernetes object definitions are saved by Velero to S3.

Application configuration is supposed to be represented by ConfigMaps, Secrets and the deployment objects (e.g.: Deployment, Statefulset, Daemonset...etc), thus saved by Velero.

## Application, Infrastructure Component & Cluster-level backups

## Application backups

An application is typically installed into a separate namespace. The PVs and Kubernetes objects are saved by Velero via, the automatically or manually deployed Velero schedules.

The database of the application is backed up separately via PGO's mechanisms. The application may be part of a shared PGO database cluster (e.g.: default) or may have a dedicated database cluster. In either case, the backup mechanism works at the level of the database cluster, so it may not be in sync with the Velero backups perfectly.

Examples:
- Gitea
- Nextcloud
- Redmine

## Infrastructure component backups

These components typically don't have relation-databases, only Kubernetes namespaces and configurations.

Thus, Velero backups cover the needs of these components.

Examples:
- Cert-Manager
- Replicator
- OpenEBS
- PGO (only the operator itself, not the database cluster)

# Cluster-level backup

The Velero 'Cluster' and 'Schedules' backup profiles deal with all Kubernetes objects that need to be protected and not part of any application or component namespaces.  See the Velero page for details.

# Backup tools and mechanisms

## Velero

Velero has support for saving: 
- Kubernetes object descriptors
- files stored in persistent Volumes (PVCs) with Restic or K8s snapshots

It currently doesn't have support for consistent, online filesystem backups with Restic, so your workloads need to be stopped for backup or must be able to tolerate filesystem backups that are potentially captured over a longer period of time (as opposed to point-in-time filesystem snapshots).

See details in the [Velero Backups](velero-backups.md) page.

## Postgres databases (simple)

The simplified Postgres database service (the 'postgres' deployer) doesn't have built-in DR support, you need to roll your own.

## Postgres databases (PGO-managed DB clusters)

The CrunchyData Postgres Operator (the 'pgo' deployer) has built-in Point-In-Time-Recovery (PITR) level DR support via its integration of pgBackrest (WAL streaming + periodic full database backups).

SolaKube aims to automate the configuration of pgBackest when new Postgres database clusters are created via PGO by configuring the appropriate S3 access parameters and backup schedules.
 
See the details in the [CrunchyData Postgres Operator page](postgres-crunchy.md) page. 

# Recovering from complete cluster loss

In case Velero/S3 application and infrastructure backups were properly enabled/deployed and PGO/S3 Postgres database backups were also enabled, the cluster can be recovered from a complete, catastrophic failure (e.g.: all nodes lost, cluster completely destroyed).

Main recovery steps:
- Recreate a "bare" cluster (details below)
- Install storage orchestrator
  - OpenEBS, Rook-Ceph
- Install Velero (in recovery mode)
  - sk deploy velero recovery
- Restore the Velero "cluster" profile
  - Cluster-level, non-namespaced objects (like ClusterRoles)
- Install + Restore Cert-manager (details in sub-section below)
- Install Replicator 
- Install PGO and its PostgreSQL clusters 
  - see the details below
- Restore the internal Docker Registry (if used)
  - with Velero, the 'default' profile
- Restore each application backups with Velero (see the [Velero](velero-backups.md) page)
  - with Velero, their 'default' profiles
  - These usually also contain persistent volume data (files)
- Restore the Velero "schedules" profile
  - The automatic Velero backup schedules (sk velero restore velero schedules) 
- Restore monitoring applications (like New-Relic, if used)
  - with Velero, the 'default' profile
- Validate all workloads for correct, operational behavior

## Recreate a "bare" cluster

Assuming:
- You have a working SolaKube installation
- You have the SolaKube cluster definition that was used to create the cluster originally 

Set the SK_BUILD_BARE_CLUSTER variable to "Y" in variables.sh

Execute "sk build"

A bare cluster should be created with all Hetzner components installed (but no other infrastructure components)

## Restoring Cert-Manager

### Reinstall Cert-Manager

Reinstall cert-manager in "upgrade" mode:

~~~
sk deploy cert-manager upgrade
~~~

NOTE: This is needed because Velero cannot correctly restore permissions around service-accounts.

### Restore cert-manager backup

Restore the cert-manager backup with Velero, the 'default' profile

~~~
sk velero restore cert-manager
~~~
This restores:
- the cluster wildcard certificate (if one is used)
- The dns01 and http01 issuer settings


## Restoring PGO and PostgreSQL clusters

### Re-Install PGO

~~~
sk deploy pgo recovery
~~~

### Restoring PGO itself

With Velero, the 'default' backup profile:

~~~
sk velero restore pgo
~~~
This restores all of the Postgres database cluster definitions. 

After this, the database clusters will fail to start because they are not instructed to start in recovery mode.

### Restoring the database clusters

Restore the PGO-managed postgres database clusters ([see the description of S3 recovery in the PGO docs](postgres-pgo.md#Restoring a PG cluster from backups))

Don't forget to promote the db clusters to online state.

# Migrating the cluster

Similarly to the complete cluster loss, the backups can be used to clone a cluster or migrate it to a new place.
