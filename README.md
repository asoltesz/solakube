# SolaKube Kubernetes cluster builder on Hetzner Cloud 

This project aims to simplify the creation of K8s clusters on Hetzner Cloud with Terraform, Ansible and Rancher 

Partially based on Vito Botta's Ansible and Terraform plugins and his article: [From zero to Kubernetes in Hetzner Cloud with Terraform, Ansible and Rancher](https://vitobotta.com/2019/10/14/kubernetes-hetzner-cloud-terraform-ansible-rancher/). It also adds example values, documentation, bugfixes, more reproducibility and further automation on top of it.

For the sake of compactness, the project is referenced as SolaKube.

# Work In Progress
 
WARNING: This is a work in progress and shared only in the hope that it may come useful for others. See the [Issues](https://github.com/asoltesz/hetzner-k8s-builder/issues). Until it reaches 1.0, major structural changes may be introduced.

The configuration describe my personal test cloud (named "andromeda"). If you want to utilize it, please read Vito's article and customize everything according to your own preferences, tokens...etc.

# Cluster Features

The resulting cluster has the following features:

Availability
- A single [Hetzner Floating IP (Fip)](https://wiki.hetzner.de/index.php/CloudServer/en#What_are_floating_IPs_and_how_do_they_work.3F) is used to direct incoming traffic to the cluster. The Fip is always assigned to a cluster node and that node will accept traffic and direct it inside the cluster.
-  The Fip is automatically transferred when node failure is detected by Kubernetes, so if the Fip-holder node crashes the Fip is reassigned to a healthy node and the cluster remains operational and available for external requests. 
- The Nginx Ingress Controller (ingress-nginx) is installed on all of the nodes, so if the Fip transfer happens, the new gateway can immediately start directing traffic without manual intervention and minimal delay.

Node structure/resources
- You can choose any node structure (masters, etcd nodes, workers) and resources (RAM, CPU, storage) you want by declaring every node with an appropriate Hetzner VM type (specifies resources) and cluster roles in the Terraform config before cluster creation.
- The cluster can later be extended with new nodes by defining them in the config and re-executing Terraform.

HTTPS Access
- Cert-Manager gets installed on the cluster which allows easy acquiring of HTTPS/TLS certificates from Let's Encrypt for different services installed on the cluster
- A wildcard certificate may also be used for the cluster (if your DNS provider is supported by cert-manager's dns01 challenges) 

Networking
- All cluster nodes are attached to a [Hetzner Network](https://wiki.hetzner.de/index.php/CloudServer/en#Networks) which allows isolated and private communication between the nodes. However the communication is unencrypted.

Storage & persistence
- [Hetzner Volumes (HVol)](https://wiki.hetzner.de/index.php/CloudServer/en#Volumes) are immediately usable for persistence after cluster provisioning, so PVCs get automatically served by allocating them on new Hetzner Volumes.
  - HVols have the minimum size of 10 GB, are extendable and are stored on redundant, HA storage.
- Optionally, [Rook/Ceph](rook.md) can also be used to share the disk space available directly on the Hetzner virtual machines as distributed storage that can be allocated to workloads. The installer script supports setting up a Rook/Ceph storage cluster on the nodes (min. 3 nodes). 
- Databases like PostgreSQL and other workloads requiring persistence can be readily deployed on the new cluster.

Cluster Management
- The newly provisioned cluster is registered into your Rancher instance, so RBAC, Monitoring, Catalog, Etcd backups and other management features are available for it.

Applications
- After the cluster is fully provisioned, you can immediately start installing applications from Rancher Catalogs
- The Tiller component of Helm2 gets installed into the cluster so you can install applications with Helm from your client machine as well (not only from Rancher's UI). Several components are installed with Helm during cluster provisioning


# Requirements, Dependencies
 
## Software versions

The tools and their versions, this cluster building method is tested on:
 
- Terraform 0.12.24
- Ansible 2.9.1
- Rancher 2.3.2
- Kubectl 1.15.5
  - (always the major+minor version of the k8s cluster created by Rancher)
- Helm 2.16.1

As a one-time check, make sure that all necessary software components are available on your machine that are needed for executing the scripts and provisioning artifacts.

Execute the check_dependencies.sh script and check versions on its output.
 
## Rancher
 
 This method requires a working Rancher Installation that has the v3 API available and your access token generated.
 
## Helm

If you don't have Helm installed, the deployment/helm-tiller.sh script may be of help. 

## Ansible, Terraform, Kubectl

Use publicly available installation guides. 

Observe the minimal required versions.

## Ansible roles

A set of Ansible roles need to be installed for the successful provisioning of the nodes of the cluster.

run installer/ansible-roles.sh 
 
 
# Differences with the original article

## S3 storage

No S3 storage is used either for the Terraform state or the generated K8s cloud's etcd backup.

[Details.](docs/s3_storage.md)

## Kernelcare

I don't have access to it, so this is commented out in provision.yml

# Creating and provisioning the cluster

See the [Cluster Creation and Provisioning page](docs/create_provision_cluster.md) about creating the cluster and installing all basic infrastructural elements

# Cluster validation checks

## Nodes fully initialized 

None of the nodes should have the uninitialized taint on them (see #1).
 
## Further validation checks

TODO



    