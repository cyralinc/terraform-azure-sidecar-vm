locals {
  sidecar_secrets = {
    clientId             = var.client_id
    clientSecret         = var.client_secret
    containerRegistryKey = var.container_registry_key
    workspaceId          = azurerm_log_analytics_workspace.cyral_log_analytics_workspace.workspace_id
    sharedPrimaryKey     = azurerm_log_analytics_workspace.cyral_log_analytics_workspace.primary_shared_key
  }
  depends_on = [
    azurerm_log_analytics_workspace.cyral_log_analytics_workspace
  ]
}

resource "azurerm_key_vault" "key_vault" {
  name                        = "${local.name_prefix}-kv"
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
      "Set",
      "Get",
      "Delete",
      "Purge",
      "List",
      "Recover",
    ]
  }

  access_policy {
    tenant_id = azurerm_user_assigned_identity.cyral_assigned_identity.tenant_id
    object_id = azurerm_user_assigned_identity.cyral_assigned_identity.principal_id

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

resource "azurerm_key_vault_secret" "key_vault_secret" {
  name         = "cyral-sidecars-${var.sidecar_id}-self-signed-certificate"
  value        = jsonencode(local.sidecar_secrets)
  key_vault_id = azurerm_key_vault.key_vault.id
}

