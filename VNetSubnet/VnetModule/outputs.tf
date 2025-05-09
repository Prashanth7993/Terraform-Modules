output "vnet_ids" {
  value       = { for key, vnet in azurerm_virtual_network.vnet : vnet.name => vnet.id }
  description = "Map of VNET names to their IDs."
}

output "subnet_ids" {
  value       = { for key, subnet in azurerm_subnet.subnet : subnet.name => subnet.id }
  description = "Map of subnet names to their IDs."
}