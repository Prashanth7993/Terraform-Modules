terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables for the deployment
variable "resource_group_name" {
  default = "ThreeTierApp"
}

variable "location" {
  default = "eastus2" # Changed from "eastus" to "eastus2"
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Call the VNet module to create VNet and subnets dynamically
module "vnet" {
  source = "../VNetSubnet/VnetModule"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnets = {
    "vnet1" = {
      name          = "ThreeTierVNet"
      address_space = "10.0.0.0/16"
      subnets = {
        "web_subnet_1" = {
          name           = "WebSubnet1"
          address_prefix = "10.0.5.0/24"
        }
        "web_subnet_2" = {
          name           = "WebSubnet2"
          address_prefix = "10.0.6.0/24"
        }
        "app_subnet_1" = {
          name           = "AppSubnet1"
          address_prefix = "10.0.1.0/24"
        }
        "app_subnet_2" = {
          name           = "AppSubnet2"
          address_prefix = "10.0.2.0/24"
        }
        "db_subnet_1" = {
          name           = "DBSubnet1"
          address_prefix = "10.0.3.0/24"
        }
        "db_subnet_2" = {
          name           = "DBSubnet2"
          address_prefix = "10.0.4.0/24"
        }
      }
    }
  }
  tags = {
    environment = "development"
    owner       = "prashanth"
  }
}

locals {
  vnets = {
    "vnet1" = {
      name          = "ThreeTierVNet"
      address_space = "10.0.0.0/16"
      subnets = {
        "web_subnet_1" = { name = "WebSubnet1", address_prefix = "10.0.5.0/24" }
        "web_subnet_2" = { name = "WebSubnet2", address_prefix = "10.0.6.0/24" }
        "app_subnet_1" = { name = "AppSubnet1", address_prefix = "10.0.1.0/24" }
        "app_subnet_2" = { name = "AppSubnet2", address_prefix = "10.0.2.0/24" }
        "db_subnet_1"  = { name = "DBSubnet1", address_prefix = "10.0.3.0/24" }
        "db_subnet_2"  = { name = "DBSubnet2", address_prefix = "10.0.4.0/24" }
      }
    }
  }
  vnet_address_spaces = { for key, vnet in local.vnets : key => vnet.address_space }
  flattened_subnet_ids = module.vnet.subnet_ids
}

# VMSS Module for Web Tier
module "web_vmss" {
  source = "../VMScaleSetWithSubnets/VmWithSubnet/"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vmss = {
    "web_vmss" = {
      name          = "WebVMSS"
      size          = "Standard_B1s"
      instance_count = 2
      subnet_name   = "web_subnet_1"
      vnet_key      = "vnet1"
      is_public     = true
      custom_data   = <<-EOF
                  #!/bin/bash
                  sudo apt update
                  sudo apt install -y nginx
                  sudo systemctl start nginx
                  EOF
    }
  }
  subnet_ids = local.flattened_subnet_ids
  vnet_address_spaces = local.vnet_address_spaces
  admin_username      = "adminuser"
  ssh_public_key_path = "~/.ssh/id_rsa.pub"
  tags = {
    environment = "development"
    owner       = "prashanth"
  }
}

# VMSS Module for Application Tier
module "app_vmss" {
  source = "../VMScaleSetWithSubnets/VmWithSubnet/"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vmss = {
    "app_vmss" = {
      name          = "AppVMSS"
      size          = "Standard_B1s"
      instance_count = 2
      subnet_name   = "app_subnet_1"
      vnet_key      = "vnet1"
      is_public     = false
      custom_data   = <<-EOF
                  #!/bin/bash
                  sudo apt update
                  sudo apt install -y nodejs npm
                  npm install -g express
                  echo "const express = require('express'); const app = express(); app.get('/', (req, res) => res.send('Hello from App Tier')); app.listen(3000);" > app.js
                  node app.js &
                  EOF
    }
  }
  subnet_ids = local.flattened_subnet_ids
  vnet_address_spaces = local.vnet_address_spaces
  admin_username      = "adminuser"
  ssh_public_key_path = "~/.ssh/id_rsa.pub"
  tags = {
    environment = "development"
    owner       = "prashanth"
  }
}

# Load Balancer for Web Tier
module "web_loadbalancer" {
  source              = "../LoadBalancer/LoadBalancerModule"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  load_balancers = {
    "web_lb" = {
      name          = "WebLoadBalancer"
      lb_type       = "public"
      frontend_port = 80
      backend_port  = 80
      protocol      = "Tcp"
      subnet_id     = module.vnet.subnet_ids["vnet1-web_subnet_1"]
      vmss_id       = module.web_vmss.vmss_ids["web_vmss"]
    }
  }
  tags = {
    environment = "development"
    owner       = "prashanth"
  }
}

# Load Balancer for Application Tier
module "app_loadbalancer" {
  source              = "../LoadBalancer/LoadBalancerModule"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  load_balancers = {
    "app_lb" = {
      name          = "AppLoadBalancer"
      lb_type       = "private"
      frontend_port = 3000
      backend_port  = 3000
      protocol      = "Tcp"
      subnet_id     = module.vnet.subnet_ids["vnet1-app_subnet_1"]
      vmss_id       = module.app_vmss.vmss_ids["app_vmss"]
    }
  }
  tags = {
    environment = "development"
    owner       = "prashanth"
  }
}

# Database Tier: Azure Database for MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "db" {
  name                   = "threetierdb"
  resource_group_name    = azurerm_resource_group.main.name
  location               = var.location
  administrator_login    = "mysqladmin"
  administrator_password = "SecurePassword123!"
  sku_name               = "B_Standard_B1s"
  version                = "8.0.21"
  storage {
    size_gb = 20
  }
  backup_retention_days = 7
}

resource "azurerm_mysql_flexible_database" "app_db" {
  name                = "appdb"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.db.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}

# Network Security Groups (NSGs) for each tier
resource "azurerm_network_security_group" "web_nsg" {
  name                = "WebNSG"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "AppNSG"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  security_rule {
    name                       = "AllowAppTraffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "db_nsg" {
  name                = "DBNSG"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  security_rule {
    name                       = "AllowMySQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "10.0.128.0/17"
    destination_address_prefix = "*"
  }
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "web_nsg_assoc_1" {
  subnet_id                 = module.vnet.subnet_ids["vnet1-web_subnet_1"]
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "web_nsg_assoc_2" {
  subnet_id                 = module.vnet.subnet_ids["vnet1-web_subnet_2"]
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_assoc_1" {
  subnet_id                 = module.vnet.subnet_ids["vnet1-app_subnet_1"]
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_assoc_2" {
  subnet_id                 = module.vnet.subnet_ids["vnet1-app_subnet_2"]
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "db_nsg_assoc_1" {
  subnet_id                 = module.vnet.subnet_ids["vnet1-db_subnet_1"]
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "db_nsg_assoc_2" {
  subnet_id                 = module.vnet.subnet_ids["vnet1-db_subnet_2"]
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# Outputs
output "subnet_ids" {
  value = module.vnet.subnet_ids
}

output "vmss_ids" {
  value = {
    web_vmss = module.web_vmss.vmss_ids
    app_vmss = module.app_vmss.vmss_ids
  }
}

output "web_loadbalancer_public_ip" {
  value = module.web_loadbalancer.public_ip_address
}