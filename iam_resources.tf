resource "azurerm_resource_group_policy_assignment" "user_policies" {
  count                = length(var.iam_policies)
  name                 = "${local.name_prefix}-user-policies-${count.index}"
  resource_group_id    = azurerm_resource_group.resource_group.id
  policy_definition_id = var.iam_policies[count.index]
}
