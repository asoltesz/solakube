# K8s cluster builder on Hetzner Cloud with Terraform, Ansible and Rancher 

It is based on Vito Botta's Ansible and Terraform plugins and his article: [From zero to Kubernetes in Hetzner Cloud with Terraform, Ansible and Rancher](https://vitobotta.com/2019/10/14/kubernetes-hetzner-cloud-terraform-ansible-rancher/).

# Work In Progress
 
WARNING: This is a work in progress and shared only in hope that it may come useful for others. See the issues.


The configuration describe my personal test cloud (named andromeda). If you want to utilize it, please read Vito's article and customize everything accordingly.

# Requirements
 
## Software versions
 
 Terraform 0.12.15
 Ansible 2.9.1
 Rancher 2.3.2
 
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

# Usage

The general flow of work is as follows.

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

## Execute Hetzner feature deployment

Download the cluster settings from Rancher and place them into ~/.kube/config.

Check kubectl and the access to your cluster by executing "kubectl get nodes". This should show the virtual-machines/nodes you configured in terraform.tfvars when you configured the cluster.

Define FLOATING_IP and HETZNER_TOKEN in your shell.

Execute deployment/hetzner_features.sh.

The deployer should print a SUCCESS message at the end if everything deployed successfully.


# Cluster validation checks

## Nodes fully initialized 

None of the nodes should have the uninitialized taint on them (see #1).
 
## Further validation checks

TODO



    