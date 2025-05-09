variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "location" {
  type        = string
  description = "The Azure region for resources."
  default     = "eastus"
}

variable "vmss" {
  type = map(object({
    name          = string
    size          = string
    instance_count = number
    subnet_name   = string
    vnet_key      = string
    is_public     = bool
  }))
  description = "Map of VMSS configurations, including subnet and public/private status."
  default     = {}
}

variable "subnet_ids" {
  type        = map(string)
  description = "Map of subnet names to their IDs, from the VNET module."
}

variable "vnet_address_spaces" {
  type        = map(string)
  description = "Map of VNET keys to their address spaces, for NSG rules."
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VMSS instances."
  default     = "adminuser"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key file."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}