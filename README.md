# SolaKube Kubernetes cluster builder on Hetzner Cloud 

This project aims to simplify the creation of K8s clusters on Hetzner Cloud with Terraform, Ansible and Rancher 

Partially based on Vito Botta's Ansible and Terraform plugins and his article: [From zero to Kubernetes in Hetzner Cloud with Terraform, Ansible and Rancher](https://vitobotta.com/2019/10/14/kubernetes-hetzner-cloud-terraform-ansible-rancher/). It also adds example values, documentation, bugfixes, more reproducibility and further automation on top of it.

For the sake of compactness, the project is referenced as SolaKube.

# Work In Progress
 
WARNING: This is a work in progress and shared only in the hope that it may come useful for others. See the [Issues](https://github.com/asoltesz/hetzner-k8s-builder/issues). Until it reaches 1.0, major structural changes may be introduced.

The configuration describe my personal test cloud (named "andromeda"). If you want to utilize it, please read Vito's article and customize everything according to your own preferences, tokens...etc.

# Cluster features

The SolaKube deployed cluster will have the following features in short:
- Highly available via Hetzner Floating IP and Nginx-Ingress
- Flexible cluster node structuring and roles
- Automatic HTTPS certificates (per-service or wildcard) via Let's Encrypt 
- Data persistence (Hetzner Volumes + Rook/Ceph)
- Custom application/component deployments

For details, see the [Features page](docs/features.md)

# Requirements, Dependencies
 
## Software versions

The tools and their versions, this cluster building method is tested on:
 
- Terraform 0.12.24
- Ansible 2.9.1
- Rancher 2.3.6
- Kubectl 1.15.5
  - (always the major+minor version of the k8s cluster created by Rancher)
- Helm 2.16.1

As a one-time check, make sure that all necessary software components are available on your machine that are needed for executing the scripts and provisioning artifacts.

Execute the **scripts/check_dependencies.sh** script and check versions on its output.
 
## Rancher / RKE
 
SolaKube requires a working Rancher Installation that has the v3 API available and your access token generated.
 
Nodes will be first prepared with Ansible, then Kubernetes will be installed on them via Rancher's RKE. Nodes will all register to Rancher as well. 
 
## Helm

If you don't have Helm installed on your machine, the **scripts/installer/helm.sh** script may be of help. 

## Ansible, Terraform, Kubectl

Use publicly available installation guides. 

Observe the minimal required versions.

## Ansible roles

A set of Ansible roles need to be installed for the successful provisioning of the nodes of the cluster.

run installer/ansible-roles.sh 

# Differences with the original article

## S3 storage

No S3 storage is used either for the Terraform state or the generated K8s cloud's etcd backup.

[Details.](docs/s3-storage.md)

Nodes may be repartitioned at VM creation time to support Rook/Ceph using a partition for distributed filesystem storage. See [Rook](docs/rook.md) 

## Kernelcare

I don't have access to it, so this is commented out in provision.yml

# Creating and provisioning the cluster

See the [Cluster Creation and Provisioning page](docs/create-provision-cluster.md) about creating the cluster and installing all basic infrastructural elements
