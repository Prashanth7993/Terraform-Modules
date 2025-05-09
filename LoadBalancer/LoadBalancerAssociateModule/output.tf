output "vm_association_ids" {
  value       = { for key, assoc in azurerm_network_interface_backend_address_pool_association.vm_association : key => assoc.id }
  description = "Map of VM association keys to their IDs."
}

output "vmss_association_ids" {
  value       = { for key, assoc in azurerm_virtual_machine_scale_set.vmss_association : key => assoc.id }
  description = "Map of VMSS association keys to their IDs."
}