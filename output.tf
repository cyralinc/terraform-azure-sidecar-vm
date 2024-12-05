output "ca_certificate_secret_id" {
  value       = local.ca_certificate_secret_id
  description = "ID of the CA certificate secret used sidecar"
}

output "load_balancer_dns" {
  value       = local.sidecar_endpoint
  description = "Sidecar load balancer DNS endpoint."
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.id
  description = "Azure Log Analytics workspace ID."
}

output "log_analytics_workspace_primary_shared_key" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.primary_shared_key
  description = "Azure Log Analytics primary shared key."
}

output "log_analytics_workspace_secondary_shared_key" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.secondary_shared_key
  description = "Azure Log Analytics secondary shared key."
}

output "resource_group_name" {
  value       = azurerm_resource_group.resource_group.name
  description = "Azure resource group name."
}

output "secret_id" {
  value       = local.secret_id
  description = "ID of the secret with the credentials used by the sidecar"
}

output "tls_certificate_secret_id" {
  value       = local.tls_certificate_secret_id
  description = "ID of the TLS certificate secret used sidecar"
}
