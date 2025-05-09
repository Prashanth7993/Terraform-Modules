variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "location" {
  type        = string
  description = "The Azure region for resources."
  default     = "eastus"
}

variable "lb_backend_pool_ids" {
  type        = map(string)
  description = "Map of load balancer backend pool names to their IDs."
}

variable "associations" {
  type = map(object({
    resources = map(object({
      type              = string
      nic_id            = string
      vmss_name         = string
      vmss_sku          = string
      vmss_instance_count = number
      subnet_id         = string
    }))
  }))
  description = "Map of load balancer associations with VMs or VMSS."
  default     = {}
}