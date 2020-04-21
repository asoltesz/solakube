# Creating and provisioning the cluster

The general flow of work is described below.

# Notes

Scripts - except "sk" - expect that you start them from their own folder.

# Configure Terraform and Ansible

See the [Configuration](configuration.md) page for the files and variables.

Major params:
- Hetzner Cloud token
- Rancher API Token
- Rancher API URL

Lesser params:
- Whitelisted IPs (whitelisted_ips) 
- Fail2Ban Ignored IPs (fail2ban_ignoredips)

# Cluster creation and provisioning

Execute **sk build**

This will do the following:
1) Creates/registers the cluster definition in your Rancher instance (via Terraform)
2) Creates the virtual machines (VMs) in Hetzner Cloud (via Terraform) and allows for a Cloud-Init script execution (e.g.: repartitioning for Rook)
3) Provisions the VMs with Ansible (OS-level configuration, installing Docker...etc)
4) Starts the RKE installer on all nodes (via Ansible)
5) Waits for the cluster to finish startup and the installation of Rancher/RKE components (sk wait-for-rancher)
6) Configures KubeCtl for executing k8s administrative commands against the new cluster (sk dl-config)
7) Deploys Hetzner Cloud support components to the new cluster (sk deploy hetzner). This will allow Floating IP and Cloud Volume usage.
8) Optionally, deploys Rook for creating a distributed Ceph storage cluster on your new K8s cluster (sk deploy rook-ceph).
9) Optionally, deploys Cert-Manager and the configured Cluster Issuers (see [Certificate Management](certificate-management.md)). (sk deploy cert-manager)
10) Optionally, deploys other applications/components supported by SolaKube (see the variables)
 
This process tries to be fully automated and avoid manual interventions to setup a cluster in as complete a state as possible. 

However, it may happen that the process is interrupted by errors. In this case, you may continue by running the steps manually (when this is possible). Manual execution command is included in brackets at the steps where it is applicable.
 
Typically the steps after the basic k8s cluster provisioning - starting with item 5 - are executable easily as manual steps.

Some of the deployers also have uninstall scripts that can be executed with "sk deploy ${modulename} undeploy" and thus easier to re-try without tearing down the cluster.
   

# Complete restart

If critical part(s) of the process fail, you may want to completely destroy your k8s cluster in order to restart. Steps needed:

- Deleting the cluster in the Rancher UI
- Removing all VMs belonging to the cluster in the Hetzner Console.

# Manual deployments

In these subsections we detail how to execute steps manually, in case you didn't include them in the original cluster building process or that failed and you want to continue manually.

## Downloading the cluster config for kubectl (manual) 

If "sk build" ran successfully at least until step 7, you already have KubeCtl configured for your new cluster. 

If not, you can use the **sk dl-config** command for this. This automatically backs up the current config file in case later it is needed.

Check KubeCtl and the access to your cluster by executing "kubectl get nodes". This should show the virtual-machines/nodes you configured in terraform.tfvars when you configured the cluster.

## Helm and Tiller

Helm's server side component (Tiller) for being able to install applications via Helm charts from CLI, without going to the Rancher UI

Execute **sk deploy helm-tiller**.


## Hetzner-Cloud support

Deploying components needed to integrate the new Kubernetes cluster with the Hetzner Cloud infrastructure (Floating IP, Cloud Volumes ...etc)

Execute **sk deploy hetzner**.

Required [variables](variables.md) are HETZNER_FLOATING_IP, HETZNER_TOKEN for the script.

The deployer should print a SUCCESS message at the end if everything deployed successfully.

## Cert-Manager, Let's Encrypt, Issuers

Cert-Manager is supported for automatically getting TLS certificates for applications made available via Ingresses (also handles automatic renewals).

Per-service certificate and shared/wildcard certificates are both supported via Let's Encrypt, see [the relevant docs page](certificate-management.md) for the explanation of the mechanisms and their configuration variables.

Execute **sk deploy cert-manager**.

## Replicator

If you use a wildcard/cluster-level certificate, you need to install Replicator in order to have the cluster certificate copied into every application namespace that wants to define an ingress that uses the wildcard certificate. (installers define the necessary metadata but only Replicator can do the actual copy/update operations)

This is needed because Nginx-Ingress can only use TLS secrets defined in the same namespace as the ingress object itself.

Execute **sk deploy replicator**.

# Rook / Ceph

To utilize the storage directly attached to your Hetzner VMs (in addition to Hetzner Cloud Volumes), you may want to deploy Rook with Ceph. 

Execute "sk deploy rook-ceph"

See the relevant [Rook](rook.md) and [Persistent Volumes](persistent-volumes.md) docs for details.

Important: The storage cluster starts up fairly slow and the script doesn't wait for the complete initialization. Make sure you do before deploying persistent workloads.

# Further steps

After these steps, your cluster should be available for application workloads.

PostgreSQL and pgAdmin are two sample deployments.

See the [Applications page](applications.md) for more details

# Cluster validation checks

## Nodes fully initialized 

None of the nodes should have the uninitialized taint on them (see issue #1).
 
## VMs / Nodes properly distributed on physical machines

On Hetzner cloud, virtual machines are not guaranteed to be perfectly distributed on separate virtual machines.

However, the API seems to strive to do this (according to our [testing](https://github.com/asoltesz/solakube/issues/9) ).

It is recommended that you check your nodes after creation so that you ensure that they are on separate physical machines.

Checking the physical machine ith MyTraceRoute:

~~~
mtr <ip-address-of-the-vm>
~~~ 

The "<machine-number>.your-cloud.host" entry shows the physical machine. 

All of your VMs should be on a different machine marked by the <machine-number>.
  

 
## Further validation checks

TBW
