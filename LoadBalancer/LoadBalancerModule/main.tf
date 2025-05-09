# Public IP for Load Balancer
resource "azurerm_public_ip" "lb_public_ip" {
  for_each = var.load_balancers

  name                = "${each.value.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# Load Balancer
resource "azurerm_lb" "lb" {
  for_each = var.load_balancers

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_public_ip[each.key].id
  }

  tags = var.tags
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "lb_backend" {
  for_each = var.load_balancers

  loadbalancer_id = azurerm_lb.lb[each.key].id
  name            = "${each.value.name}-backend"
}

# Health Probe
resource "azurerm_lb_probe" "lb_probe" {
  for_each = var.load_balancers

  loadbalancer_id = azurerm_lb.lb[each.key].id
  name            = "${each.value.name}-probe"
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# Load Balancing Rule
resource "azurerm_lb_rule" "lb_rule" {
  for_each = var.load_balancers

  loadbalancer_id                = azurerm_lb.lb[each.key].id
  name                           = "${each.value.name}-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend[each.key].id]
  probe_id                       = azurerm_lb_probe.lb_probe[each.key].id
}