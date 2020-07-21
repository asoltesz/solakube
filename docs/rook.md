# Rook/Ceph storage

The **rook-ceph** module of SolaKube installs Rook with Ceph on your cluster so that the available storage of the Hetzner virtual machines can be utilized as highly available storage.

Due to the fixed size of Hetzner virtual machines (e.g.: CX31, 8GB RAM, 80 GB SSD), without this, a lot of local storage would not be utilized on the VMs.

NOTE: A production deployment of Rook/Ceph requires a fair amount of resources to be allocated to different Ceph components. See the Resources section whether it is worth using it.

# Configuration

## Data partition (Terraform, CLoud-Init)

The Rook/Ceph deployer expects the sda2 partition on the VMs to be available fully for a Ceph storage partition. 

If a node doesn't have an sda2 partition, it will be ignored and will not be part of the Ceph storage cluster. A minimum of 3 nodes must be available with a clean sda2 partition to form a properly replicated HA storage cluster.

The sda2 partition can be made available by repartitioning the VMs virtual disk when the Hetzner API creates them. This can be done by assigning the VM an appropriate user-data Cloud-Init script reference. See the **centos7-default** script in [variables.tf](../terraform/clusters/andromeda/variables.tf).

In case the OS partition needs to be bigger, just copy the script with a different name, change the OS storage space in it and reference the new script from your VM definitions in [terraform.tfvars](../terraform/clusters/andromeda/terraform.tfvars).

## Resources

Rook/Ceph requires a fair amount of resources for a production deployment.

Resource usage can be customized in cluster-default.yaml.

### Pod requests/limits

A minimum amount of resources is pre-configured like this. (request is always the same as limits):
~~~
    resources:
        mgr:
          limits:
            cpu: "250m"
            memory: "512Mi"
          requests:
            cpu: "100m"
            memory: "512Mi"
        mon:
            limits:
                cpu: "250m"
                memory: "1024Mi"
            requests:
                cpu: "100m"
                memory: "512Mi"
        osd:
            limits:
                cpu: "250m"
                memory: "2048Mi"
            requests:
                cpu: "100m"
                memory: "1024Mi"
~~~

OSDs are per-node. 

MONs are allocated as a 3-pod cluster (each on different nodes). 

MGR is a single pod in a smaller cluster (e.g. a 3 node storage cluster).

Also, there are a set of smaller pods (e.g. the Rook operator itself, the CSI driver...etc) that should be allowed to use 512 MB of RAM among them. 

The SolaKube default CPU request is slightly lower than the official Rook/Ceph production sample, because my own workload tests showed much less CPU usage. The memory requests are also toned-down slightly according to my load tests.

Your mileage may vary, modify them if:
- monitoring shows that these pods are limited by CPU allocation.
- you encounter any anomalies (e.g.: Rook pods are killed and restarted) or monitoring clearly shows that Rook pod memory allocations are not enough for your loads

In case you encounter anomalies, remove the limits and load-test your cluster to find out how much memory and CPU you need for the acceptable performance levels. 

Without full-blown monitoring, you may use this to check the Rook/Ceph resource usage:

~~~
kubectl top pod -n rook-ceph
~~~

Use the standard query to see pod restarts:

~~~
kubectl get pod -n rook-ceph
~~~

If any of the OSD, MON or MGR pods have periodic restarts, then they probably need more memory or there is some other stability issue.

If you set ROOK_CLUSTER_TYPE to "testing", no resource constraints will be set. However, this is not recommended for production use because over-allocated nodes will produce random errors in your workloads as the OOM killer kills your pods. 

### Summary & When is it worth it ?

Altogether, a small, 3-node Rook/Ceph storage cluster will require about ~5632 MB of RAM and 750m CPU.

In case of Hetzner Cloud, it means that it is not really viable to use a Rook/Ceph storage cluster in a weaker setup than a 3 x CX31 (3 x 8 GB RAM + 80 GB SSD) node set (24 GB of RAM altogether). Even with this setup, you spend ~25% of your RAM resource on the storage cluster instead of actual workloads.

With a weaker node-set, storage on Hetzner Cloud Volumes seems to make more sense.

#### Value of storage calculation

With Hetzner prices on 2020-JUL-21.

A 3 x CX31 cluster will give you 60 GB storage. 20 GB is reserved for the OS and Kubernetes on each node, and every data is replicated to 2 other nodes.

At current prices, 60 GB worth of Hetzner Cloud Volumes can be had for 2.4 EUR/month (10 GB = 0.4 EUR/month) if your cloud volume utilization can be sufficiently high (since the minimum volume size is 10 GB) 

If your volume space utilization is low and you would actually need, say, 12 volumes for your storage ( 5 GB / volume in avg), the cost then rises to 4.8 EUR/month because you will have to pay for 12 * 10 GB = 120 GB but actually use only 60 GB.

If we value only the CPU and the RAM in the nodes and value them equally, then:
- the 8GB of RAM in the CX31 node is worth 4.45 EUR (node=8.9 EUR/month) and the 5.632 MB of RAM usage of Rook/Ceph represents ~3.105 EUR of value.
- the 2000m CPU in the CX31 node is worth 4.45 EUR (node=8.9 EUR/month) and the 750m CPU usage of Rook/Ceph represents ~1.66 EUR of value.

Altogether, the 60 GB storage cluster costs ~4.7 EUR/month.

Thus - unless we need a high number of small volumes - we are likely more cost-effective to use Hetzner Cloud volumes. That is externally/professionally managed and doesn't consume any resources of our own cluster.

Economics of the Rook/Ceph storage cluster may be somewhat better with larger/more nodes since:
 - storage RAM/CPU usage may not grow linearly (certain of your services are used less often)
 - larger nodes are cheaper per resource unit


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
 