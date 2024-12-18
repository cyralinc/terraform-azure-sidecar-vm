resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name == "" ? "${local.name_prefix}" : var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_user_assigned_identity" "user_assigned_identity" {
  location            = azurerm_resource_group.resource_group.location
  name                = "${local.name_prefix}-user-assigned_identity"
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_resource_group_policy_assignment" "user_policies" {
  count                = length(var.iam_policies)
  name                 = "${local.name_prefix}-user-policies-${count.index}"
  resource_group_id    = azurerm_resource_group.resource_group.id
  policy_definition_id = var.iam_policies[count.index]
}
