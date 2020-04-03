variable "cluster_name" {}
variable "hcloud_token" {}
variable "ssh_private_key" {}
variable "ssh_public_key" {}
variable "rancher_api_url" {}
variable "rancher_api_token" {}
variable "etcd_backup_enabled" {}
variable "etcd_s3_access_key" {}
variable "etcd_s3_secret_key" {}
variable "etcd_s3_bucket_name" {}
variable "etcd_s3_endpoint" {}
variable "etcd_s3_region" {}
variable "servers" {}
variable "ansible_playbook_path" {}
variable "ansible_vault_password_path" {}
variable "ingress_provider" {}



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
// # 0    0    - 10 GB - ext4 on /    (OS files)
// # 1   10 GB - 100%  - lvm (for Ceph)
//
// -----------------------------------------------------------------------------

variable "user_data_scripts" {

  type = map(string)

  default =  {

    //
    // Generic Cloud Init script for CentOS 7 VMs
    //
    // 10 GB is reserved for the OS and Docker images, all the rest goes to
    // the Rook/Ceph storage cluster in the form of the /dev/sda2 partition.
    //
    centos7_generic = <<EOF
#cloud-config

growpart:
  mode: off

runcmd:
  - [ parted, "/dev/sda", mkpart, primary, ext2, "10GB", "100%" ]  # create a new partition, starting at 10GB
  - [ parted, "/dev/sda", set, "2", lvm, on ]  # set LVM flag
  - [ growpart, "/dev/sda", "1" ]  # grow first partition to 10GB
  - [ partx, --update, "/dev/sda" ] # reload partition table
  - [ resize2fs, /dev/sda1 ] # resize first partition (/) to 10GB
  - [ pvcreate, "/dev/sda2" ] # create PV on /dev/sda2 (100%-10GB)
  - [ vgcreate, vg1, "/dev/sda2" ] # create VG, adding PV /dev/sda2

repo_update: true
repo_upgrade: all

packages:
  - lvm2  # missing in the Hetzner image

EOF
  }
}