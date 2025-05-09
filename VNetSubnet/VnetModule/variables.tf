variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "location" {
  type        = string
  description = "The Azure region for resources."
  default     = "eastus"
}

variable "vnets" {
  type = map(object({
    name          = string
    address_space = string
    subnets = map(object({
      name = string
    }))
  }))
  description = "Map of VNETs with their subnets."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}