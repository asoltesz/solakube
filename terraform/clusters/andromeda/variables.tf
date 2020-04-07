variable "cluster_name" {}
variable "hcloud_token" {}
variable "ssh_private_key" {}
variable "ssh_public_key" {}
variable "rancher_api_url" {}
variable "rancher_api_token" {}

#
# Whether the Rancher server is allowed to regularly backup the
# etcd database of the cluster
#
variable "etcd_backup_enabled" {
  type = bool
}

#
# Access Key for the regular etcd backups (when stored in S3)
#
variable "etcd_s3_access_key" {
  type = string
}

#
# Secret Key for the regular etcd backups (when stored in S3)
#
variable "etcd_s3_secret_key" {
  type = string
}

#
# Name of the S3 Bucket for the regular etcd backups (when stored in S3)
#
variable "etcd_s3_bucket_name" {
  type = string
}

#
# The URL of the S3 endpoint for the regular etcd backups (when stored in S3)
#
variable "etcd_s3_endpoint" {
  type = string
}

#
# The S3 region name for the regular etcd backups (when stored in S3)
#
variable "etcd_s3_region" {
  type = string
}

#
# Whether Prometheus monitoring is allowed on the cluster
#
variable enable_cluster_monitoring {
  type = bool
  default = false
}

#
# Whether Prometheus alerting is allowed on the cluster
#
variable enable_cluster_alerting {
  type = bool
  default = false
}


#
# Server nodes that will be part of the Kubernetes cluster
#
variable "servers" {
  type = map(
    object({
      # Name of the node
      name               = string,
      # The private address of the node
      private_ip_address = string,
      # Hetzner server type
      server_type        = string,
      # Hetzner base OS image
      image              = string,
      # Datacenter location
      location           = string,
      # Whether backups are needed for it
      backups            = bool,
      # Cloud-Init script reference (see user_data_scripts map)
      user_data_script   = string,
      # Rancher/K8s node roles (e.g.: "--worker --etcd --controlplane)
      roles              = string
    })
  )
}


#
# The Kubernetes version you want to install on the nodes.
#
# It must be one of the supported versions of your Rancher/RKE server
#
variable "kubernetes_version" {
  default = "v1.15.11-rancher1-2"
}


variable "ansible_playbook_path" {}
variable "ansible_vault_password_path" {}
variable "ingress_provider" {}

#
# Whether the Rancher/RKE deployment should be run on the nodes
# Without this, the nodes will not start to deploy RKE and will not join
# the cluster
#
variable run_rancher_deploy {
  default = true
}


// -----------------------------------------------------------------------------
//
// VM initialization scripts (Cloud-Init) for different Hetzner instances
//
// Here, we ensure that the VMs are properly re-partitioned, so that we can
// use all available storage space for the Rook/Ceph distributed file-system
//
// Typically:
//
// First we disable the initial call to "growpart" as otherwise the first
// partition would consume all space on the disk and we want custom partitioning
//
// Then we create a custom partition layout, like this:
// # 0    0    - 15 GB - ext4 on /    (OS files)
// # 1   15 GB - 100%  - lvm (for Ceph)
//
// -----------------------------------------------------------------------------

variable "user_data_scripts" {

  type = map(string)

  default =  {

    //
    // Generic Cloud Init script for CentOS 7 VMs
    //
    // 15 GB is reserved for the OS and Docker images, all the rest goes to
    // the Rook/Ceph storage cluster in the form of the /dev/sda2 partition.
    //
    // sda2 is left without a filesystem because Ceph doesn't accept
    // if there was an fs on it
    centos7_generic = <<EOF
#cloud-config

growpart:
  mode: off

runcmd:
  # create a new partition, starting at 15GB
  - [ parted, "/dev/sda", mkpart, primary, ext2, "15GB", "100%" ]
  # set LVM flag on the new partition
  - [ parted, "/dev/sda", set, "2", lvm, on ]
  # grow first partition to fill all the allocated space
  - [ growpart, "/dev/sda", "1" ]
  # reload partition table
  - [ partx, --update, "/dev/sda" ]
  # resize filesystem to fill the first partition completely
  - [ resize2fs, /dev/sda1 ]
#  # create PV on /dev/sda2
#  - [ pvcreate, "/dev/sda2" ]
#  # create VG, adding PV /dev/sda2
#  - [ vgcreate, vg1, "/dev/sda2" ]

repo_update: true
repo_upgrade: all

packages:
  - lvm2  # missing in the Hetzner image

EOF

  }
}