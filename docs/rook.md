# Rook/Ceph storage

The **rook-ceph** module of SolaKube installs Rook with Ceph on your cluster so that the available storage of the Hetzner virtual machines can be utilized as highly available storage.

Due to the fixed size of Hetzner virtual machines (e.g.: CX31, 8GB RAM, 80 GB SSD), without this, a lot of local storage would not be utilized on the machines. 

# Configuration

## Data partition (Terraform, CLoud-INit)

The Rook/Ceph deployer expects the sda2 partition on the VMs to be available fully for a Ceph storage partition. 

If a node doesn't have an sda2 partition, it will be ignored and will not be part of the Ceph storage cluster. A minimum of 3 nodes must be available with a clean sda2 partition to form a properly replicated HA storage cluster.

The sda2 partition can be made available by repartitioning the VMs virtual disk when the Hetzner API creates them. This can be done by assigning the VM an appropriate user-data Cloud-Init script reference. See the **centos7-default** script in [variables.tf](../terraform/clusters/andromeda/variables.tf).

In case the OS partition needs to be bigger, just copy the script with a different name, change the OS storage space in it and referemce the new script from your VM definitions in [terraform.tfvars](../terraform/clusters/andromeda/terraform.tfvars).

## Resources

Rook/Ceph requires a fair amount of resources for a production deployment.

Resource usage should be configured in cluster-default.yaml.

A minimum amount of resources is pre-configured like this. (request is always the same as limits):
~~~
        mgr:
          requests:
            cpu: "250m"
            memory: "512Mi"
        mon:
            requests:
                cpu: "250m"
                memory: "512Mi"
        osd:
            requests:
                cpu: "250m"
                memory: "512Mi" 
~~~

OSDs are per-node. MON and MGR are single pods in a small cluster (3 nodes).

If you encounter any anomalies (e.g.: Rook pods are killed and restarted), remove the limits and load-test your cluster to find out how much memory and CPU you need for the acceptable performance levels. 

Use this to check the Rook resource usage:

~~~
kubectl top pod -n rook-ceph
~~~

Use the standard query to see pod restarts:

~~~
kubectl get pod -n rook-ceph
~~~

If any of the OSD, MON or MGR pods have periodic restarts, then they probably need more memory or there is some other stability issue.

If you set ROOK_CLUSTER_TYPE to "testing", no resource constraints will be set. However, this is not recommended for production use. 


# Deployment

## Including in the original cluster provisioning

Set the "SK_DEPLOY_ROOK_CEPH" variable to "Y" before you create the cluster with "sk build". 

## Manual deployment 

The **sk deploy rook-ceph** manual command can be used to deploy Rook with Ceph if you didn't include it in your original cluster provisioning execution.

After a successful deployment, wait until the 3 OSD pods become Active in the "rook_ceph" namespace.

Applications/Services will automatically get persistent volumes assigned from Rook/Ceph if you set the service specific *_STORAGE_CLASS variable or the DEFAULT_STORAGE_CLASS variable to 'rook-ceph-block'.

See [Persistent Volumes](persistent-volumes.md) for more details about the storage class hierarchy.

# Checking Ceph storage cluster

The following command displays status info about the Ceph storage cluster:

~~~
sk deploy rook-ceph status 
~~~

This will utilize the rook-ceph-tools deployment that can also be utilized from a shell:

~~~
sk deploy rook-ceph toolbox-shell 
~~~


# Testing Rook PVCs

Deploy pgadmin or postgres-simple with the default storage settings. They should allocate storage with the "rook-ceph-block" storage class.

If the applications work properly and you see the allocated volume, then Rook should work properly.

Ideally, you should also load-test at least some of your applications to see if their storage is performant enough.
 