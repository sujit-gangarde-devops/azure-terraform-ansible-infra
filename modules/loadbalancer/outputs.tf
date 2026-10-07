output "public_ip" {
  value = azurerm_public_ip.lb.ip_address
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.web.id
}

output "ssh_nat_rule_ids" {
  value = azurerm_lb_nat_rule.ssh[*].id
}

output "ssh_ports" {
  value = azurerm_lb_nat_rule.ssh[*].frontend_port
}
