output "lb_ids" {
  value       = { for key, lb in azurerm_lb.lb : lb.name => lb.id }
  description = "Map of load balancer names to their IDs."
}

output "lb_backend_pool_ids" {
  value       = { for key, pool in azurerm_lb_backend_address_pool.lb_backend : pool.name => pool.id }
  description = "Map of backend pool names to their IDs."
}

output "lb_public_ips" {
  value       = { for key, pip in azurerm_public_ip.lb_public_ip : pip.name => pip.ip_address }
  description = "Map of load balancer public IP names to their IP addresses."
}