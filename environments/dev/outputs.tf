output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "app_url" {
  value = "http://${module.loadbalancer.public_ip}"
}

output "lb_public_ip" {
  value = module.loadbalancer.public_ip
}

output "ssh_commands" {
  value = [for port in module.loadbalancer.ssh_ports : "ssh -p ${port} ${var.admin_username}@${module.loadbalancer.public_ip}"]
}

output "web_private_ips" {
  value = module.compute.private_ips
}

output "mysql_fqdn" {
  value = module.database.fqdn
}

output "key_vault_name" {
  value = module.keyvault.name
}
