resource "azurerm_availability_set" "web" {
  name                         = "avail-${var.name_prefix}-web"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
  tags                         = var.tags
}

resource "azurerm_network_interface" "web" {
  count               = var.vm_count
  name                = "nic-${var.name_prefix}-web-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "web" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.web[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = var.backend_pool_id
}

resource "azurerm_network_interface_nat_rule_association" "ssh" {
  count                 = var.vm_count
  network_interface_id  = azurerm_network_interface.web[count.index].id
  ip_configuration_name = "ipconfig1"
  nat_rule_id           = var.ssh_nat_rule_ids[count.index]
}

resource "azurerm_linux_virtual_machine" "web" {
  count                           = var.vm_count
  name                            = "vm-${var.name_prefix}-web-${count.index + 1}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  availability_set_id             = azurerm_availability_set.web.id
  network_interface_ids           = [azurerm_network_interface.web[count.index].id]
  tags                            = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Managed identity lets the VM read secrets from Key Vault without stored credentials
  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {}
}
