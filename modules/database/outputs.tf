output "fqdn" {
  value = azurerm_mysql_flexible_server.this.fqdn
}

output "server_name" {
  value = azurerm_mysql_flexible_server.this.name
}

output "admin_username" {
  value = azurerm_mysql_flexible_server.this.administrator_login
}

output "admin_password" {
  value     = random_password.mysql_admin.result
  sensitive = true
}

output "database_name" {
  value = azurerm_mysql_flexible_database.app.name
}
