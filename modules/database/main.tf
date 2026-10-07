resource "random_password" "mysql_admin" {
  length           = 24
  special          = true
  override_special = "_%@#"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

# Private DNS so the VMs resolve the server's FQDN to its private IP inside the VNet
resource "azurerm_private_dns_zone" "mysql" {
  name                = "${var.name_prefix}.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "link-${var.name_prefix}-mysql"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

resource "azurerm_mysql_flexible_server" "this" {
  name                         = "mysql-${var.name_prefix}-${var.name_suffix}"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  sku_name                     = var.sku_name
  version                      = "8.0.21"
  administrator_login          = var.admin_username
  administrator_password       = random_password.mysql_admin.result
  delegated_subnet_id          = var.delegated_subnet_id
  private_dns_zone_id          = azurerm_private_dns_zone.mysql.id
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = false
  tags                         = var.tags

  storage {
    size_gb           = 20
    auto_grow_enabled = true
  }

  # Azure picks the availability zone; don't fight it on later plans
  lifecycle {
    ignore_changes = [zone]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]
}

resource "azurerm_mysql_flexible_database" "app" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
