locals {
  frontend_name = "frontend-public"
}

resource "azurerm_public_ip" "lb" {
  name                = "pip-lb-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_lb" "this" {
  name                = "lb-${var.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = local.frontend_name
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  name            = "bepool-web"
  loadbalancer_id = azurerm_lb.this.id
}

# The probe goes through Nginx to Tomcat, so a VM whose app is down is taken out of rotation
resource "azurerm_lb_probe" "http" {
  name                = "probe-http-health"
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = "Http"
  port                = 80
  request_path        = "/health"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "http" {
  name                           = "rule-http"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = local.frontend_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.http.id
  disable_outbound_snat          = true
}

# Explicit outbound rule so the private VMs can reach the internet (apt, downloads)
resource "azurerm_lb_outbound_rule" "web" {
  name                    = "outbound-web"
  loadbalancer_id         = azurerm_lb.this.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id

  frontend_ip_configuration {
    name = local.frontend_name
  }
}

# VMs have no public IPs; SSH goes through per-VM NAT ports on the LB (restricted by the NSG)
resource "azurerm_lb_nat_rule" "ssh" {
  count                          = var.vm_count
  name                           = "nat-ssh-vm-${count.index + 1}"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = var.ssh_nat_base_port + count.index + 1
  backend_port                   = 22
  frontend_ip_configuration_name = local.frontend_name
}
