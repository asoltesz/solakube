output "server_ips" {
  value = module.hcloud.server_ips
}

output "floating_ip" {
  value = module.hcloud.floating_ip
}

output "kube_config" {
  value = module.rancher.kube_config
}
