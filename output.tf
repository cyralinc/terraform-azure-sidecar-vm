output "load_balancer_dns" {
  value       = local.sidecar_endpoint
  description = "Sidecar load balancer DNS endpoint."
}

output "resource_group_name" {
  value       = azurerm_resource_group.resource_group.name
  description = "Azure resource group name."
}


output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.id
  description = "Azure Log Analytics workspace ID."
}

output "secret_id" {
  value       = azurerm_key_vault_secret.sidecar_secrets.id
  description = "ID of the secret with the credentials used by the sidecar"
}

output "ca_certificate_secret_id" {
  value       = azurerm_key_vault_secret.self_signed_ca.id
  description = "ID of the CA certificate secret used sidecar"
}

output "tls_certificate_secret_id" {
  value       = azurerm_key_vault_secret.self_signed_tls_cert.id
  description = "ID of the TLS certificate secret used sidecar"
}
