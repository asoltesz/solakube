terraform {

//
//  We will use a local Terraform state storage backend for tests.
//  For production, S3 or similarly safe equivalent will be needed
//
//  backend "s3" {
//    skip_requesting_account_id  = true
//    skip_credentials_validation = true
//    skip_get_ec2_platforms      = true
//    skip_metadata_api_check     = true
//  }

}

provider "rancher2" {
  api_url   = var.rancher_api_url
  token_key = var.rancher_api_token
}

module "rancher" {

  source = "github.com/asoltesz/terraform-rancher?ref=v0.6"

  cluster_name        = var.cluster_name

  kubernetes_version  = var.kubernetes_version

  etcd_backup_enabled = var.etcd_backup_enabled
  etcd_s3_access_key  = var.etcd_s3_access_key
  etcd_s3_secret_key  = var.etcd_s3_secret_key
  etcd_s3_region      = var.etcd_s3_region
  etcd_s3_endpoint    = var.etcd_s3_endpoint
  etcd_s3_bucket_name = var.etcd_s3_bucket_name

  ingress_provider = var.ingress_provider

  enable_cluster_alerting = var.enable_cluster_alerting
  enable_cluster_monitoring = var.enable_cluster_monitoring
}


provider "hcloud" {
  token = var.hcloud_token
}

module "hcloud" {

  source = "github.com/asoltesz/terraform-hcloud?ref=v0.6"

  servers                     = var.servers
  user_data_scripts           = var.user_data_scripts
  cluster_name                = var.cluster_name
  ssh_private_key             = var.ssh_private_key
  ssh_public_key              = var.ssh_public_key
  ansible_playbook_path       = var.ansible_playbook_path
  ansible_vault_password_path = var.ansible_vault_password_path

  run_rancher_deploy          = var.run_rancher_deploy
  rancher_node_command        = module.rancher.node_command
}
