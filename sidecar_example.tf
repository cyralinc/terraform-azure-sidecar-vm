provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "cyral_sidecar" {
  name     = "cyral_sidecar"
  location = "brazilsouth"
}
