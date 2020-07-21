# Shared configuration
cluster_name    = "andromeda"

ssh_private_key = "~/.ssh/id_rsa"
ssh_public_key  = "~/.ssh/id_rsa.pub"

# Rancher configuration
rancher_api_url     = "https://rancher.nostran.com/v3"

etcd_backup_enabled = false

enable_cluster_monitoring = true
enable_cluster_alerting = true

# Hetzner Cloud configuration
ansible_playbook_path       = "../../../ansible/provision.yml"
ansible_vault_password_path = "~/.solakube/ansible-vault-pass"

#
# The definition of teh virtual machines forming the Kubernetes nodes
# (see variables.tf for detailed docs)
#
servers = {

  1 = {
    name               = "andromeda-master-1"
    private_ip_address = "10.0.0.3"
    server_type        = "cx31"
    image              = "centos-7"
    location           = "nbg1"
    backups            = false
    user_data_script   = "centos7_generic"
    roles              = "--worker --etcd --controlplane"
  },

  2 = {
    name               = "andromeda-master-2"
    private_ip_address = "10.0.0.4"
    server_type        = "cx31"
    image              = "centos-7"
    location           = "nbg1"
    backups            = false
    user_data_script   = "centos7_generic"
    roles              = "--worker --etcd --controlplane"
  },

  3 = {
    name               = "andromeda-master-3"
    private_ip_address = "10.0.0.5"
    server_type        = "cx31"
    image              = "centos-7"
    location           = "nbg1"
    backups            = false
    user_data_script   = "centos7_generic"
    roles              = "--worker --etcd --controlplane"
  },
}

