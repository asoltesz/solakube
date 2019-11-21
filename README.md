# Kubernetes cluster builder on Hetzner Cloud with Terraform, Ansible and Rancher 

This project is based on Vito Botta's Ansible and Terraform plugins and his article: [From zero to Kubernetes in Hetzner Cloud with Terraform, Ansible and Rancher](https://vitobotta.com/2019/10/14/kubernetes-hetzner-cloud-terraform-ansible-rancher/) and strives to add example values, documentation, bugfixes, more reproducibility and further automation on top of it.

# Work In Progress
 
WARNING: This is a work in progress and shared only in the hope that it may come useful for others. See the [Issues](https://github.com/asoltesz/hetzner-k8s-builder/issues).

The configuration describe my personal test cloud (named "andromeda"). If you want to utilize it, please read Vito's article and customize everything accordingly according to your own preferences, tokens...etc.

# Cluster Features

The resulting cluster has the following features:

Availability
- A single [Hetzner Floating IP (Fip)](https://wiki.hetzner.de/index.php/CloudServer/en#What_are_floating_IPs_and_how_do_they_work.3F) is used to direct incoming traffic to the cluster. The Fip is always assigned to a cluster node and that node will accept traffic and direct it inside the cluster.
-  The Fip is automatically transferred when node failure is detected by Kubernetes, so if the Fip-holder node crashes the Fip is reassigned to a healthy node and the cluster remains operational and available for external requests. 
- The Nginx Ingress Controller (ingress-nginx) is installed on all of the nodes, so if the Fip transfer happens, the new gateway can immediately start directing traffic without manual intervention and minimal delay.

Node structure/resources
- You can choose any node structure and resources you want by declaring every node with Hetzner VM type and cluster role (master, etcd, worker) in the Terraform config before cluster creation.
- The cluster can later be extended with new nodes by defining them in the config and re-executing Terraform.

HTTPS Access
- Cert-Manager gets installed

Networking
- All cluster nodes are attached to a [Hetzner Network](https://wiki.hetzner.de/index.php/CloudServer/en#Networks) which allows isolated and private communication between the nodes. However the communication is unencrypted.

Storage & persistence
- [Hetzner Volumes (HVol)](https://wiki.hetzner.de/index.php/CloudServer/en#Volumes) are immediately usable for persistence after cluster provisioning, so PVCs get automatically served by allocating them on new Hetzner Volumes.
- HVols have the minimum size of 10 GB, are extendable and are stored on redundant storage.
- Databases like PostgreSQL and other workloads requiring persistence can be deployed  
Cluster Management
- The newly provisioned cluster is registered into your Rancher instance, so RBAC, Monitoring, Catalog, Etcd backups and other management features are available for it.

Applications
- After the cluster is fully provisioned, you can immediately start install applications from Rancher Catalogs
- Helm's Tiller component gets installed into the cluster so you can install applications with Helm from your client machine as well (not only from Rancher's UI). Several components are installed with Helm during the cluster provisioning


# Requirements
 
## Software versions

The tools and their versions, this cluster building method is tested on:
 
- Terraform 0.12.15
- Ansible 2.9.1
- Rancher 2.3.2
- kubectl 1.15.5
  - (always the major+minor version of the k8s cluster created by Rancher)
- Helm 2.16.1
 
## Rancher
 
 This method requires a working Rancher Installation that has the v3 API available and your access token generated.
 
# Differences with the article

## S3 storage

No S3 used either for the Terraform state or the generated K8s cloud's etcd backup. Since this is a test cloud, I didn't want to pay for S3 storage yet. 

Terraform uses local disk state storage (S3 backend parameters simply commented out, so reverts to default, local disk storage)

Generated K8s cluster doesn't have its etcd backed up.

In production, these will be needed. Wasabe seems to be a good provider.

## Kernelcare

I don't have access to it, so this is commented out in provision.yml

# Creating and provisioning the cluster

The general flow of work is as follows.

## Check dependencies

As a one-time check, this makes sure that all necessary software components are available on your machine that are needed for executing the scripts and provisioning artifacts.

Execute the check_dependencies.sh script and check versions on its output.

### Helm

If you don't have Helm installed, the installer/helm.sh script may help you. 

### Ansible, Terraform, Kubectl

Use publicly available installation guides. 

Observe the minimal required versions.

### Ansible roles

A set of Ansible roles need to be installed for the successful provisioning of the nodes of the cluster.

run installer/ansible-roles.sh 

## Configure Terraform and Ansible

Read Vito's article, I only include highlights here.

Major params:
- Hetzner Cloud token
- Rancher Token
- Rancher API URL

Lesser params:
- Whitelisted IPs (whitelisted_ips) 
- Fail2Ban Ignored IPs (fail2ban_ignoredips)

Use create_vault.sh and edit_vault.sh for easily make/change settings in the Ansible vault.

## Cluster creation

In the scripts folder, execute ./apply-cluster.sh

This executes Terraform with the Ansible machine provisioner.

This will create the cluster and registers it with your Rancher installation.

When Terraform finishes, wait until Rancher shows the cluster status as "Active" (as opposed to "Provisioning").

## Download cluster config for kubectl 

Download the cluster settings from Rancher and place them into ~/.kube/config.

You can use the 'download-cluster-config.sh' script for this. This automatically backs up the current config file in case later it is needed.

Check kubectl and the access to your cluster by executing "kubectl get nodes". This should show the virtual-machines/nodes you configured in terraform.tfvars when you configured the cluster.

## Execute Hetzner feature deployment

Define FLOATING_IP and HETZNER_TOKEN in your shell.

Execute deployment/hetzner_features.sh.

The deployer should print a SUCCESS message at the end if everything deployed successfully.

## Add basic cluster features

### Helm and Tiller

Helm's server side component (Tiller) for being able to install applications via Helm charts from CLI, without going to the Rancher UI

Execute deployment/tiller.sh.

### Cert-Manager and Let'sEncrypt

Cert-Manager for semi-automatically getting TLS certificates for applications made available via Ingresses. Also handles automatic renewals 

A default certificate issuer for Cert-Manager (Let's Encrypt)

Define LETS_ENCRIPT_ACME_EMAIL in your shell. This is the email address you want to present to Let's Encrypt as the person responsible for the certs of your domain.

Execute deployment/cert-manager.sh.


# Cluster validation checks

## Nodes fully initialized 

None of the nodes should have the uninitialized taint on them (see #1).
 
## Further validation checks

TODO



    