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

module "vnet" {
  source = "../VnetModule"

  resource_group_name = "PrashanthMainRg"
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
    owner       = "your-name"
  }
}

output "vnet_ids" {
  value = module.vnet.vnet_ids
}

output "subnet_ids" {
  value = module.vnet.subnet_ids
}