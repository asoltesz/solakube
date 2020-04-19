# Requirements, Dependencies

Before using SolaKube, you need to ensure that all necessary software is present that are needed for the cluster building processes.
 
In case you only want to do a quick evaluation, you may want to use the SolaKube [Vagrant box](vagrant.md) instead of installing all required dependencies onto your machine.

## Operating System

The Bash scripts expect a modern Linux environment (Bash 4+, envsubst ..etc).

Due to being a small project with very limited resources, macOS and Windows is not supported.

You may be able to use SolaKube on macOS if you upgrade your Bash to 4.0+.

On Windows, you may be able to use SolaKube under WSL/WSL2.

In both cases, the Vagrant box is the recommended way.

## Software packages

The tools and their versions, this cluster building method is tested on:
 
- Terraform 0.12.24
- Ansible 2.9.1
- Rancher Server 2.3.6
- Kubectl 1.15.5
  - (always the major+minor version of the k8s cluster created by Rancher)
- Helm 2.16.1
- Bash 4+
- envsubst

As a one-time check, make sure that all necessary software components are available on your machine that are needed for executing the scripts and provisioning artifacts.

Execute the **scripts/check_dependencies.sh** script and check versions on its output.

NOTE: The [Vagrant box sources](https://github.com/asoltesz/solakube-vagrant) may serve as a guideline how to install & configure the dependencies on a Linux system (some of them are non-trivial).
 
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

