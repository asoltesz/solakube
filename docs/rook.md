# Rook/Ceph storage

This module of SolaKube installs Rook with Ceph on your cluster so that the available storage of the Hetzner virtual machines can be utilized as highly available storage.

Due to the fixed size of Hetzner virtual machines (e.g.: CX31, 8GB RAM, 80 GB SSD), without this, a lot of local storage would not be utilized on the machines. 

The deployment/rook/deploy.sh script can be used to deploy Rook with Ceph.

After a successful deployment, wait until the 3 osd pods become Active in the "rook_ceph" namespace.

Applications/Services will automatically get persistent volumes assigned from Rook/Ceph if you set the service specific *_STORAGE_CLASS variable or the DEFAULT_STORAGE_CLASS variable to 'rook-ceph-block'.

See [Persistent Volumes](persistent-volumes.md) for more details.

# Warning

Currently, the Hetzner installer system cannot partition the disks of the virtual machines in order to provide Ceph with a clean partition to operate over. 

This only allows having Ceph operate over a filesystem folder (/var/lib/rook) which is not supported for production purposes with Rook and Ceph.  

Ensure that the volumes reserved will not use up all storage space on the machines. Vice-versa for operatig system files.
