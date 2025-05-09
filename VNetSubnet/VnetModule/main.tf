# VNETs
resource "azurerm_virtual_network" "vnet" {
  for_each = var.vnets

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [each.value.address_space]
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "subnet" {
  for_each = local.subnet_configs

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  address_prefixes     = [each.value.address_prefix]
}

# Local variable to flatten subnet configurations
locals {
  subnet_configs = merge([
    for vnet_key, vnet in var.vnets : {
      for subnet_key, subnet in vnet.subnets : "${vnet_key}-${subnet_key}" => {
        vnet_key       = vnet_key
        name           = subnet.name
        address_prefix = cidrsubnet(vnet.address_space, 8, index(keys(vnet.subnets), subnet_key) + 1)
      }
    }
  ]...)
}