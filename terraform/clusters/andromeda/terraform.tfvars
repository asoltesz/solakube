# Shared configuration
cluster_name    = "andromeda"

ssh_private_key = "~/.ssh/id_rsa"
ssh_public_key  = "~/.ssh/id_rsa.pub"

# Rancher configuration
rancher_api_url     = "https://rancher.nostran.com/v3"

etcd_backup_enabled = false
etcd_s3_bucket_name = "..."
etcd_s3_endpoint    = "..."
etcd_s3_region      = "..."

enable_cluster_monitoring = true
enable_cluster_alerting = true

# Hetzner Cloud configuration
ansible_playbook_path       = "../../../ansible/provision.yml"
ansible_vault_password_path = "~/.solakube/ansible-vault-pass"

#
# The definition of teh virtual machines forming the Kubernetes nodes
#
# server_type: The type of the Hetzner Cloud virtual machine
#
# As of 2019-11-15, some of the relevant types:
#
# cx11 - 1 vCPU,  2 GB RAM,  20 GB SSD
# cx21 - 2 vCPU,  4 GB RAM,  40 GB SSD
# cx31 - 2 vCPU,  8 GB RAM,  80 GB SSD
# cx41 - 4 vCPU, 16 GB RAM, 160 GB SSD
#
servers = {

  1 = {
    name               = "andromeda-master1-v2"
    private_ip_address = "10.0.0.3"
    server_type        = "cx21"
    image              = "centos-7"
    location           = "nbg1"
    backups            = false
    user_data_script   = "centos7_generic"
    roles              = "--worker --etcd --controlplane"
  },

  2 = {
    name               = "andromeda-master2-v2"
    private_ip_address = "10.0.0.4"
    server_type        = "cx21"
    image              = "centos-7"
    location           = "nbg1"
    backups            = false
    user_data_script   = "centos7_generic"
    roles              = "--worker --etcd --controlplane"
  },

  3 = {
    name               = "andromeda-master3-v2"
    private_ip_address = "10.0.0.5"
    server_type        = "cx21"
    image              = "centos-7"
    location           = "nbg1"
    backups            = false
    user_data_script   = "centos7_generic"
    roles              = "--worker --etcd --controlplane"
  },
}

# Set it to "none" if no ingress controller should be deployed
ingress_provider = "nginx"
