# Disaster Recovery

SolaKube integrates Velero as the base Disaster Recovery (DR) solution.

The Postgres (and databases in general) has special needs in terms of disaster recovery, so it is not in the scope of the Velero based DR system (see below).

# Velero

Velero has support for saving: 
- Kubernetes object descriptors
- files stored in persistent Volumes (PVCs) with Restic or K8s snapshots

It currently doesn't have support for consistent, online filesystem backups with Restic, so your workloads need to be stopped for backup or must be able to tolerate filesystem backups that are potentially captured over a longer period of time (as opposed to point-in-time filesystem snapshots).

See details in the [Velero Backups](velero-backups.md) page.

# Postgres (simple)

The simplified Postgres database service (the 'postgres' deployer) doesn't have built-in DR support, you need to roll your own.

# Postgres (pgo)

The CrunchyData Postgres Operator (the 'pgo' deployer) has built-in Point-In-Time-Recovery (PITR) level DR support via its integration of pgBackrest (WAL streaming + periodic full database backups).

SolaKube aims to automate the configuration of pgBackest when new Postgres database clusters are created via PGO by configuring the appropriate S3 access parameters.
 
See the details in the [CrunchyData Postgres Operator](postgres-crunchy.md) page. 

# Recovering from complete cluster loss

In case Velero/S3 application and infrastructure backups were properly enabled/deployed and PGO/S3 Postgres database backups were also enabled, the cluster can be recovered from a complete, catastrophic failure (e.g.: all nodes lost, cluster completely destroyed).

Main recovery steps:
- Recreate a "bare" cluster (SK_BUILD_BARE_CLUSTER="Y")
- Install Hetzner components
- Install Velero 
- Restore the "Infra" (Infrastructure) backup with Velero
- Restore the PGO-managed postgres database clusters (see docs for S3 recovery in postgres-pgo.md)
- Restore each application backups with Velero

TBW: More details

# Migrating the cluster

Similarly to the complete cluster loss, the backups can be used to clone a cluster or migrate it to a new place.
