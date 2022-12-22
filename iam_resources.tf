resource "azurerm_role_definition" "cyral-role_definition" {
  name        = "${local.name_prefix}-sidecar_role"
  scope       = azurerm_resource_group.resource_group.id
  description = "Sidecar custom role created via Terraform"

  assignable_scopes = [
    azurerm_resource_group.resource_group.id,
  ]
}

resource "azurerm_resource_group_policy_assignment" "user_policies" {
  count                = length(var.iam_policies)
  name                 = "${local.name_prefix}-user_policies_${count.index}"
  resource_group_id    = azurerm_resource_group.resource_group.id
  policy_definition_id = var.iam_policies[count.index]
}
