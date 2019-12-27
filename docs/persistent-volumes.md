# Persistent Volumes

For all applications/components installed by SolaKube, the storage class can be specified in an environment variable (e.g.: PGADMIN_STORAGE_CLASS)

The storage class drives the allocation of Persistent Volumes when an application requires storage (submits a Persistent Volume Claim aka PVC)

In case, no application-specific storage class is set, the value of the DEFAULT_STORAGE_CLASS environment variable will be used as the default.

If the DEFAULT_STORAGE_CLASS is not set, the 'hcloud-volumes' (Hetzner Cloud Volumes) will be used as the default (assuming Hetzner features are deployed on the cluster).
