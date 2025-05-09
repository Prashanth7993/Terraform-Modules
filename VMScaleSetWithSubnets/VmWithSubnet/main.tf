# Network Security Groups (one per subnet)
resource "azurerm_network_security_group" "nsg" {
  for_each = toset([for vmss in var.vmss : vmss.subnet_name])

  name                = "${var.resource_group_name}-nsg-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Rules for public subnets
  dynamic "security_rule" {
    for_each = [for vmss in var.vmss : vmss if vmss.subnet_name == each.key && vmss.is_public]
    content {
      name                       = "Allow-SSH-${security_rule.value.name}"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = [for vmss in var.vmss : vmss if vmss.subnet_name == each.key && vmss.is_public]
    content {
      name                       = "Allow-HTTP-${security_rule.value.name}"
      priority                   = 101
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  # Rules for private subnets
  dynamic "security_rule" {
    for_each = [for vmss in var.vmss : vmss if vmss.subnet_name == each.key && !vmss.is_public]
    content {
      name                       = "Allow-Internal-${security_rule.value.name}"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = var.vnet_address_spaces[security_rule.value.vnet_key]
      destination_address_prefix = "*"
    }
  }

  tags = var.tags
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = toset([for vmss in var.vmss : vmss.subnet_name])

  subnet_id                 = var.subnet_ids[each.key]
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

# Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  for_each = var.vmss

  name                            = each.value.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  sku                             = each.value.size
  instances                       = each.value.instance_count
  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "${each.value.name}-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_ids[each.value.subnet_name]

      dynamic "public_ip_address" {
        for_each = each.value.is_public ? [1] : []
        content {
          name = "${each.value.name}-public-ip"
        }
      }
    }
  }

  tags = var.tags
}