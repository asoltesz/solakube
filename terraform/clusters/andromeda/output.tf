output "server_ips" {
  value = module.hcloud.server_ips
}

output "floating_ip" {
  value = module.hcloud.floating_ip
}


output "rancher_cluster_id" {
  value = module.rancher.cluster_id
}

//
// Activate these when debugging is needed
//

//output "rancher_node_command" {
//  value = module.rancher.node_command
//}

//output "kube_config" {
//  value = module.rancher.kube_config
//}

