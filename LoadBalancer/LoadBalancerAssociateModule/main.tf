# Associate VMs with Load Balancer Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "vm_association" {
  for_each = { for assoc in local.vm_associations : "${assoc.lb_key}-${assoc.resource_key}" => assoc }

  network_interface_id    = each.value.nic_id
  ip_configuration_name   = "internal"
  backend_address_pool_id = each.value.backend_pool_id
}

# Associate VMSS with Load Balancer Backend Pool
resource "azurerm_virtual_machine_scale_set" "vmss_association" {
  for_each = { for assoc in local.vmss_associations : "${assoc.lb_key}-${assoc.resource_key}" => assoc }

  # Minimal configuration to update existing VMSS with backend pool
  name                = each.value.vmss_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = each.value.vmss_sku
  instances           = each.value.vmss_instance_count

  network_interface {
    name    = "${each.value.vmss_name}-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = each.value.subnet_id
      load_balancer_backend_address_pool_ids = [each.value.backend_pool_id]
    }
  }

  # Required minimal blocks to avoid plan errors
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  lifecycle {
    ignore_changes = [
      instances,
      admin_username,
      admin_ssh_key,
      tags,
    ]
  }
}

# Locals to flatten associations
locals {
  vm_associations = flatten([
    for lb_key, assoc in var.associations : [
      for resource_key, resource in assoc.resources : {
        lb_key           = lb_key
        resource_key     = resource_key
        nic_id           = resource.type == "vm" ? resource.nic_id : null
        backend_pool_id  = var.lb_backend_pool_ids[lb_key]
      } if resource.type == "vm" && resource.nic_id != null
    ]
  ])

  vmss_associations = flatten([
    for lb_key, assoc in var.associations : [
      for resource_key, resource in assoc.resources : {
        lb_key              = lb_key
        resource_key        = resource_key
        vmss_name           = resource.type == "vmss" ? resource.vmss_name : null
        vmss_sku            = resource.type == "vmss" ? resource.vmss_sku : null
        vmss_instance_count = resource.type == "vmss" ? resource.vmss_instance_count : null
        subnet_id           = resource.type == "vmss" ? resource.subnet_id : null
        backend_pool_id     = var.lb_backend_pool_ids[lb_key]
      } if resource.type == "vmss" && resource.vmss_name != null
    ]
  ])
}