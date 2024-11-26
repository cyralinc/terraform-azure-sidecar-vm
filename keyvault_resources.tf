locals {
  sidecar_secrets = {
    clientId                    = var.client_id
    clientSecret                = var.client_secret
    sidecarPublicIdpCertificate = replace(var.sidecar_public_idp_certificate, "\n", "\\n")
    sidecarPrivateIdpKey        = replace(var.sidecar_private_idp_key, "\n", "\\n")
    idpCertificate              = replace(var.idp_certificate, "\n", "\\n")
  }
  key_vault_name = var.key_vault_name == "" ? "${local.name_prefix}-kv" : var.key_vault_name
  secret_name    = length(var.secret_name) > 0 ? var.secret_name : "cyral-sidecars-${var.sidecar_id}-secrets"

  self_signed_cert_country               = "US"
  self_signed_cert_province              = "CA"
  self_signed_cert_locality              = "Redwood City"
  self_signed_cert_organization          = "Cyral Inc."
  self_signed_cert_validity_period_hours = 10 * 365 * 24
}

resource "azurerm_key_vault" "key_vault" {
  name                        = local.key_vault_name
  location                    = azurerm_resource_group.resource_group.location
  resource_group_name         = azurerm_resource_group.resource_group.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "Set",
      "Delete",
      "Purge",
    ]
  }

  access_policy {
    tenant_id = azurerm_user_assigned_identity.user_assigned_identity.tenant_id
    object_id = azurerm_user_assigned_identity.user_assigned_identity.principal_id

    secret_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_key_vault_secret" "sidecar_secrets" {
  name         = local.secret_name
  value        = jsonencode(local.sidecar_secrets)
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "tls_private_key" "tls" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "tls" {
  private_key_pem   = tls_private_key.tls.private_key_pem
  is_ca_certificate = false

  subject {
    country      = local.self_signed_cert_country
    province     = local.self_signed_cert_province
    locality     = local.self_signed_cert_locality
    organization = local.self_signed_cert_organization
    common_name  = local.sidecar_endpoint
  }

  validity_period_hours = local.self_signed_cert_validity_period_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true

  subject {
    country      = local.self_signed_cert_country
    province     = local.self_signed_cert_province
    locality     = local.self_signed_cert_locality
    organization = local.self_signed_cert_organization
    common_name  = local.sidecar_endpoint
  }

  validity_period_hours = local.self_signed_cert_validity_period_hours

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

resource "azurerm_key_vault_secret" "self_signed_ca" {
  key_vault_id = azurerm_key_vault.key_vault.id
  name         = "cyral-sidecars-${var.sidecar_id}-ca-certificate"
  value = jsonencode({
    key  = tls_private_key.ca.private_key_pem
    cert = tls_self_signed_cert.ca.cert_pem
  })
}

resource "azurerm_key_vault_secret" "self_signed_tls_cert" {
  key_vault_id = azurerm_key_vault.key_vault.id
  name         = "cyral-sidecars-${var.sidecar_id}-tls-certificate"
  value = jsonencode({
    key  = tls_private_key.tls.private_key_pem
    cert = tls_self_signed_cert.tls.cert_pem
  })
}
