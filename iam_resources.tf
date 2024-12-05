# resource "azurerm_role_definition" "role_definition" {
#   name        = "${local.name_prefix}-sidecar-role"
#   scope       = azurerm_resource_group.resource_group.id
#   description = "Sidecar custom role created via Terraform"

#   permissions {
#     actions     = var.iam_actions_role_permissions
#     not_actions = var.iam_no_actions_role_permissions
#   }

#   assignable_scopes = [
#     azurerm_resource_group.resource_group.id,
#   ]
# }

resource "azurerm_resource_group_policy_assignment" "user_policies" {
  count                = length(var.iam_policies)
  name                 = "${local.name_prefix}-user-policies-${count.index}"
  resource_group_id    = azurerm_resource_group.resource_group.id
  policy_definition_id = var.iam_policies[count.index]
}
