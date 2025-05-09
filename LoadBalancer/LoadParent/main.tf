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
  name     = "PrashanthMainRg"
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
  source = "../../Terraform-Modules/VMScaleSetWithSubnets/VmWithSubnet/"

  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus"
  vmss = {
    "vmss1" = {
      name          = "vmss-public-1"
      size          = "Standard_B1s"
      instance_count = 2
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
  ssh_public_key_path = "~/.ssh/my_new_key.pub"
  tags = {
    environment = "development"
    owner       = "prashanth"
  }
}


#Change Vms or Vmscaleset Configuration remove the public ip assignment for Vmscale set where load balancer will assign ip 
# Load Balancer Module
module "load_balancer" {
  source = "../LoadBalancerModule"

  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus"
  load_balancers = {
    "lb1" = {
      name = "lb-public-1"
    }
  }
  tags = {
    environment = "development"
    owner       = "prashanth"
  }
}

# Load Balancer Association Module
module "lb_association" {
  source = "../LoadBalancerAssociateModule/"

  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus"
  lb_backend_pool_ids = module.load_balancer.lb_backend_pool_ids
  associations = {
    "lb1" = {
      resources = {
        "vmss1" = {
          type              = "vmss"
          nic_id            = null
          vmss_name         = "vmss-public-1"
          vmss_sku          = "Standard_B1s"
          vmss_instance_count = 2
          subnet_id         = module.vnet.subnet_ids["public-subnet-1"]
        }
        # Example VM association (uncomment if VM module is used)
        # "vm1" = {
        #   type              = "vm"
        #   nic_id            = module.vm.vm_nic_ids["vm-public-1"]
        #   vmss_name         = null
        #   vmss_sku          = null
        #   vmss_instance_count = null
        #   subnet_id         = null
        # }
      }
    }
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

output "lb_ids" {
  value = module.load_balancer.lb_ids
}

output "lb_public_ips" {
  value = module.load_balancer.lb_public_ips
}

output "vm_association_ids" {
  value = module.lb_association.vm_association_ids
}

output "vmss_association_ids" {
  value = module.lb_association.vmss_association_ids
}