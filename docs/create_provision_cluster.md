# Creating and provisioning the cluster

The general flow of work is described below.

## Notes

All scripts expect that you start them from their own folder.

## Configure Terraform and Ansible

Read [Vito's article](https://vitobotta.com/2019/10/14/kubernetes-hetzner-cloud-terraform-ansible-rancher/)), because I only discuss highlights here.

Major params:
- Hetzner Cloud token
- Rancher API Token
- Rancher API URL

Lesser params:
- Whitelisted IPs (whitelisted_ips) 
- Fail2Ban Ignored IPs (fail2ban_ignoredips)

Use create_vault.sh and edit_vault.sh for easily make/change sensitive settings in the Ansible vault (tokens, passwords).

## Cluster creation

In the scripts folder, execute **./apply-cluster.sh**

This executes Terraform with the Ansible machine provisioner.

This will create the cluster and registers it with your Rancher installation.

When Terraform finishes, wait until Rancher shows the cluster status as **"Active"** (as opposed to "Provisioning").

## Download cluster config for kubectl 

Download the cluster settings from Rancher and place them into **~/.kube/config**.

You can use the **download-cluster-config.sh** script for this. This automatically backs up the current config file in case later it is needed. Set the RANCHER_API_TOKEN, RANCHER_HOST, RANCHER_CLUSTER_ID [variables](variables.md) for the script in the shell.

Check kubectl and the access to your cluster by executing "kubectl get nodes". This should show the virtual-machines/nodes you configured in terraform.tfvars when you configured the cluster.

## Helm and Tiller

Helm's server side component (Tiller) for being able to install applications via Helm charts from CLI, without going to the Rancher UI

Execute **helm-tiller.sh** script in the **deployment** folder.

# Add basic cluster features

## Execute Hetzner feature deployment

Execute the **deploy.sh** script in the **deployment/hetzner** folder.

Required [variables](variables.md) are HETZNER_FLOATING_IP, HETZNER_TOKEN for the script.

The deployer should print a SUCCESS message at the end if everything deployed successfully.

## Cert-Manager, Let's Encrypt, Issuers

Cert-Manager is supported for automatically getting TLS certificates for applications made available via Ingresses (also handles automatic renewals).

Per-service certificate and shared/wildcard certificates are both supported via Let's Encrypt, see [the relevant docs page](certificate-management.md) for the explanation of the mechanisms and their configuration variables.

Execute the **deploy.sh** script in the **deployment/cert-manager** folder.

## Replicator

If you use a wildcard/cluster-level certificate, you need to install Replicator in order to have the cluster certificate copied into every application namespace that wants to define an ingress that uses the wildcard certificate. (installers define the necessary metadata but only Replicator can do the actual copy/update operations)

This is needed because Nginx-Ingress can only use TLS secrets defined in the same namespace as the ingress object itself.

Execute the **deploy.sh** in the **deployment/replicator** folder.

# Rook / Ceph

To utilize the storage directly attached to your Hetzner VMs (in addition to Hetzner Cloud Volumes), you may want to deploy Rook with Ceph. 

Execute deployment/rook/deploy.sh.

See the relevant [Rook](rook.md) and [Persistent Volumes](persistent-volumes.md) docs for details.

# Further steps

After these steps, your cluster should be available for application workloads.

PostgreSQL (deployment/pgadmin) and pgAdmin (deployment/pgadmin) are two sample deployments.