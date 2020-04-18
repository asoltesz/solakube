# Differences with the original Vito Botta article

This work is partially based on Vito Botta's Ansible and Terraform plugins and his article: [From zero to Kubernetes in Hetzner Cloud with Terraform, Ansible and Rancher](https://vitobotta.com/2019/10/14/kubernetes-hetzner-cloud-terraform-ansible-rancher/). It also adds example values, documentation, bugfixes, more reproducibility and further automation on top of it.

This page tries to list the major differences.

# Configuration folders & files

Instead of the ~/.secrets folder and the "terraform-<cluster name>.sh" file in it, we use the "~/solakube/<clustername>" folder and the variables.sh file in it.

The variables.sh file contains much more exports and also driving logic for the cluster provisioning process.


# S3 storage

No S3 storage is used either for the Terraform state or the generated K8s cloud's etcd backup.

[Details.](docs/s3-storage.md)

Nodes may be repartitioned at VM creation time to support Rook/Ceph using a partition for distributed filesystem storage. See [Rook](docs/rook.md) 

# Kernelcare

I don't have access to it, so this is commented out in provision.yml. I intend to find a better customization for it in time so that can optionally remain.
