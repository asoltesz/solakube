# Persistent Volumes

For all applications/components installed by SolaKube, the storage class can be specified in an environment variable (e.g.: PGADMIN_STORAGE_CLASS)

The storage class drives the allocation of Persistent Volumes when an application requires storage (submits a Persistent Volume Claim aka PVC)

In case, no application-specific storage class is set, the value of the DEFAULT_STORAGE_CLASS environment variable will be used as the default.

If the DEFAULT_STORAGE_CLASS is not set, the 'hcloud-volumes' (Hetzner Cloud Volumes) will be used as the default (assuming Hetzner features are deployed on the cluster).

# Hetzner Cloud Volumes

Hetzner provides Ceph based highly-availablecloud storage in the form of Hetzner Cloud Volumes (hvol). All data is stored on 3 different servers.

At the time of this writing, the minimum size of volumes is 10 GB which makes it uneconomical for cases where the persistent needs are modest but there are many PVCs (many applications with light workloads).

Also, there is no snapshotting ability for these volumes which makes it impossible to take a consistent backup online (when there is a lot of read/write/delete activity on the volume).

# Rook-Ceph Volumes

SolaKube supports the simplified creation of a Rook/Ceph storage cluster within your k8s cluster.
 
This is also highly available, all data is stored on 3 different servers.
 
Supports both snapshotting and allocation of small volumes (any size).
