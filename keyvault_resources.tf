locals {
  sidecar_secrets = {
    clientId             = var.client_id
    clientSecret         = var.client_secret
    containerRegistryKey = var.container_registry_key
  }
  #create_sidecar_custom_certificate_secret = var.sidecar_custom_certificate_account_id != ""
}

resource "azurerm_key_vault" "cyral-sidecar-secret" {
  name                        = "cyral-sidecar-key"
  location                    = azurerm_resource_group.cyral_sidecar.location
  resource_group_name         = azurerm_resource_group.cyral_sidecar.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Get",
      "List",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "List",
      "Recover",
    ]
  }
}

resource "azurerm_key_vault_secret" "cyral-sidecar-secret-version" {
  name         = "cyral-sidecars-${var.sidecar_id}-self-signed-certificate"
  value        = jsonencode(local.sidecar_secrets)
  key_vault_id = azurerm_key_vault.cyral-sidecar-secret.id
}

