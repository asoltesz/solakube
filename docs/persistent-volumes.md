# Persistent Volumes

For all applications/components installed by SolaKube, the storage class can be specified in an environment variable (e.g.: PGADMIN_STORAGE_CLASS). 

The storage class drives the allocation of Persistent Volumes when an application requires storage (submits a Persistent Volume Claim aka PVC)

This can refer to a single storage class, or a prioritized list of storage classes (see at DEFAULT_STORAGE_CLASS) 

In case, the application-specific storage class is NOT set, the value of the DEFAULT_STORAGE_CLASS environment variable will be used as the default.

The DEFAULT_STORAGE_CLASS can be a single storage class, or it can be a prioritized list of storage classes (like "rook-ceph-block,hcloud-volumes"). The SolaKube deployment system will select the first storage class on the list that exists in the cluster.

If the DEFAULT_STORAGE_CLASS is NOT set, a hard-wired, prioritized list will be used. 

If none of the storage classes can be found in the cluster, the SolaKube deployment in question will fail before even starting the actual deployment.

# Storage classes

## Hetzner Cloud Volumes

Hetzner provides Ceph based highly-available cloud storage in the form of Hetzner Cloud Volumes (hvol). All data is stored on 3 different servers.

At the time of this writing, the minimum size of volumes is 10 GB which makes it somewhat uneconomical for cases where the persistent needs are modest but there are many PVCs (many applications with light workloads).

Also, there is no snapshotting ability for these volumes which makes it impossible to take a consistent backup while the workload is online (when there is a lot of read/write/delete activity on the volume). If point-in-time-consistent backups are required for successful restores, the workload using this type of storage needs to be taken offline for the duration of the backup operation.

## Rook/Ceph Volumes

SolaKube supports the simplified creation of a Rook/Ceph storage cluster within your k8s cluster.
 
This is also highly available, all data is stored on 3 different servers.
 
Supports both snapshotting and allocation of small volumes (any size).

A disadvantage of Rook/Ceph is that operating it requires both CPU and memory allocated for it specifically, which reduces the available resources available for actual workloads. 