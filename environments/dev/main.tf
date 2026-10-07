locals {
  name_prefix = "${var.project}-${var.environment}"

  tags = merge({
    project     = var.project
    environment = var.environment
    owner       = var.owner
    managed_by  = "terraform"
  }, var.extra_tags)
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "../../modules/network"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  vnet_cidr           = var.vnet_cidr
  web_subnet_cidr     = var.web_subnet_cidr
  db_subnet_cidr      = var.db_subnet_cidr
  admin_source_cidrs  = var.admin_source_cidrs
  tags                = local.tags
}

module "loadbalancer" {
  source = "../../modules/loadbalancer"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  vm_count            = var.vm_count
  tags                = local.tags
}

module "compute" {
  source = "../../modules/compute"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network.web_subnet_id
  vm_count            = var.vm_count
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key
  backend_pool_id     = module.loadbalancer.backend_pool_id
  ssh_nat_rule_ids    = module.loadbalancer.ssh_nat_rule_ids
  tags                = local.tags
}

module "database" {
  source = "../../modules/database"

  name_prefix         = local.name_prefix
  name_suffix         = random_string.suffix.result
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  vnet_id             = module.network.vnet_id
  delegated_subnet_id = module.network.db_subnet_id
  sku_name            = var.mysql_sku
  admin_username      = var.mysql_admin_username
  database_name       = var.database_name
  tags                = local.tags
}

module "keyvault" {
  source = "../../modules/keyvault"

  name                 = "kv-${local.name_prefix}-${random_string.suffix.result}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  mysql_admin_password = module.database.admin_password
  reader_object_ids    = module.compute.principal_ids
  tags                 = local.tags
}

# Hand the new infrastructure to Ansible
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../../ansible/inventory/${var.environment}.ini"
  file_permission = "0644"
  content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    vm_names       = module.compute.vm_names
    lb_public_ip   = module.loadbalancer.public_ip
    ssh_ports      = module.loadbalancer.ssh_ports
    admin_username = var.admin_username
    mysql_fqdn     = module.database.fqdn
    mysql_database = module.database.database_name
    mysql_user     = module.database.admin_username
    key_vault_name = module.keyvault.name
  })
}
