resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "${local.name_prefix}-log-analytics"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  retention_in_days   = 30
}
