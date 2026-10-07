output "vm_names" {
  value = azurerm_linux_virtual_machine.web[*].name
}

output "private_ips" {
  value = azurerm_network_interface.web[*].private_ip_address
}

output "principal_ids" {
  description = "Managed identity object IDs of the VMs"
  value       = [for vm in azurerm_linux_virtual_machine.web : vm.identity[0].principal_id]
}
