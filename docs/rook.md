# Rook/Ceph storage

The **rook-ceph** module of SolaKube installs Rook with Ceph on your cluster so that the available storage of the Hetzner virtual machines can be utilized as highly available storage.

Due to the fixed size of Hetzner virtual machines (e.g.: CX31, 8GB RAM, 80 GB SSD), without this, a lot of local storage would not be utilized on the machines. 

# Prequisites

The Rook/Ceph deployer expects the sda2 partition on the VMs to be available fully for a Ceph storage partition. 

If a node doesn't have an sda2 partition, it will be ignored and will not be part of the Ceph storage cluster. A minimum of 3 nodes must be available with a clean sda2 partition to form a properly replicated HA storage cluster.

The sda2 partition can be made available by repartitioning the VMs virtual disk when the Hetzner API creates them. This can be done by assigning the VM an appropriate user-data Cloud-Init script reference. See the **centos7-default** script in [variables.tf](../terraform/clusters/andromeda/variables.tf).

In case the OS partition needs to be bigger, just copy the script with a different name, change the OS storage space in it and referemce the new script from your VM definitions in [terraform.tfvars](../terraform/clusters/andromeda/terraform.tfvars).

When you 

# Including in the original cluster provisioning

Set the "SK_DEPLOY_ROOK_CEPH" variable to "Y" before you create the cluster with "sk build". 

# Manual deployment 

The **sk deploy rook-ceph** manual command can be used to deploy Rook with Ceph if you didn't include it in your original cluster provisioning execution.

After a successful deployment, wait until the 3 OSD pods become Active in the "rook_ceph" namespace.

Applications/Services will automatically get persistent volumes assigned from Rook/Ceph if you set the service specific *_STORAGE_CLASS variable or the DEFAULT_STORAGE_CLASS variable to 'rook-ceph-block'.

See [Persistent Volumes](persistent-volumes.md) for more details about the storage class hierarchy.

# WARNING: beta state

Currently, the Rook storage solution is still in testing/beta state. It is now properly deploys the storage on a spearate partition (as opposed to using a simple folder on the OS partition) but the resource requests/limits have not been configured and there has been no load testing on the solution whatsoever. 
Minimally, appropriate resource limits should be set to ensure predictable pod execution on the nodes (see the Rook documentation).
