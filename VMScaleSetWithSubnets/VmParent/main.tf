provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.27.0"
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "Module-test"
  location = "eastus"
}

# VNET Module
module "vnet" {
  source = "../../Terraform-Modules/VNetSubnet/VnetModule/"

  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus"
  vnets = {
    "vnet1" = {
      name          = "vnet-1"
      address_space = "10.0.0.0/16"
      subnets = {
        "public1"  = { name = "public-subnet-1" }
        "private1" = { name = "private-subnet-1" }
      }
    }
    # "vnet2" = {
    #   name          = "vnet-2"
    #   address_space = "10.1.0.0/16"
    #   subnets = {
    #     "public2"  = { name = "public-subnet-2" }
    #     "private2" = { name = "private-subnet-2" }
    #     "private3" = { name = "private-subnet-3" }
    #   }
    # }
  }
  tags = {
    environment = "development"
    owner       = "prashanth"
  }
}

# VMSS Module
module "vmss" {
  source = "../VmWithSubnet"

  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus"
  vmss = {
    "vmss1" = {
      name          = "vmss-public-1"
      size          = "Standard_B1s"
      instance_count = 10
      subnet_name   = "public-subnet-1"
      vnet_key      = "vnet1"
      is_public     = true
    }
    # "vmss2" = {
    #   name          = "vmss-private-1"
    #   size          = "Standard_B1s"
    #   instance_count = 2
    #   subnet_name   = "private-subnet-1"
    #   vnet_key      = "vnet1"
    #   is_public     = false
    # }
  }
  subnet_ids = module.vnet.subnet_ids
  vnet_address_spaces = { for key, vnet in local.vnets : key => vnet.address_space }
  admin_username      = "adminuser"
  ssh_public_key_path = "~/.ssh/id_rsa.pub"
  tags = {
    environment = "development"
    owner       = "prashanth"
  }
}

# Local variable to access vnets for vnet_address_spaces
locals {
  vnets = {
    "vnet1" = {
      name          = "vnet-1"
      address_space = "10.0.0.0/16"
      subnets = {
        "public1"  = { name = "public-subnet-1" }
        "private1" = { name = "private-subnet-1" }
      }
    }
    # "vnet2" = {
    #   name          = "vnet-2"
    #   address_space = "10.1.0.0/16"
    #   subnets = {
    #     "public2"  = { name = "public-subnet-2" }
    #     "private2" = { name = "private-subnet-2" }
    #     "private3" = { name = "private-subnet-3" }
    #   }
    # }
  }
}

output "vnet_ids" {
  value = module.vnet.vnet_ids
}

output "subnet_ids" {
  value = module.vnet.subnet_ids
}

output "vmss_ids" {
  value = module.vmss.vmss_ids
}