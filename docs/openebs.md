# OpenEBS storage provisioner

OpenEBS can be utilized in clusters for provisioning fast, local disks for workloads that have their own replication mechanisms. W

Workloads like Elastic, PostgreSQL, Mongo...etc tolerate less durable storage because they have their own data replication and clustering mechanisms. They also run much faster on fast local disks as opposed to cloud-mounted, relatively slow disks like Ceph-disks or similar.

# Volumes from a host folder (openebs-hostpath)

SolaKube configures the host so that OpenEBS can provision volumes from a host folder:

~~~
/var/openebs/local
~~~

When using the "openebs-hostpath" storage class, make sure that you have enough storage space for both the operating system, docker (images) and your volume data.  


# Utilizing the sda2 partition (openebs-device class)

SolaKube has samples how to repartition the VMs disk to have separate sda1 (Operating System) and sda2 (data) disks. See the [Rook](rook.md) for details.

OpenEBS will, hopefully soon able to use sda2 and that would allow provisioning volumes from a safely segregated partition so that the operating system files will never clash with the data partition in any way and OpenEBS can control the whole partition.

Currently, sda2 on Hetzner machines cannot be used because NDM always ignores it because sda2 is on the same device as the operating system partiton (sda1)  (on Hetzner machines at least).

When this issue is fixed in OpenEBS, the separate storage device can be utilized:

https://github.com/openebs/openebs/issues/3133:
