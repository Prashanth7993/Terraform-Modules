output "vmss_ids" {
  value       = { for key, vmss in azurerm_linux_virtual_machine_scale_set.vmss : vmss.name => vmss.id }
  description = "Map of VMSS names to their IDs."
}

output "nsg_ids" {
  value       = { for key, nsg in azurerm_network_security_group.nsg : nsg.name => nsg.id }
  description = "Map of NSG names to their IDs."
}
