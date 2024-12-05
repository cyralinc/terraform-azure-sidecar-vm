locals {
  frontend_ip_config_name = "${local.name_prefix}_lb-frontend-ip"
}
resource "azurerm_public_ip" "public_ip" {
  count               = var.public_load_balancer ? 1 : 0
  name                = "${local.name_prefix}-public-ip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  domain_name_label   = local.name_prefix
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = "${local.name_prefix}-lb"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"
  sku_tier            = "Regional"

  dynamic "frontend_ip_configuration" {
    for_each = var.public_load_balancer ? [1] : []
    content {
      name                 = local.frontend_ip_config_name
      public_ip_address_id = azurerm_public_ip.public_ip[0].id
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.public_load_balancer ? [] : var.subnets
    content {
      name                          = "${local.frontend_ip_config_name}_${frontend_ip_configuration.key}"
      subnet_id                     = frontend_ip_configuration.value
      private_ip_address_allocation = "Dynamic"
      private_ip_address_version    = "IPv4"
    }
  }
}

resource "azurerm_lb_backend_address_pool" "lb_backend_address_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "${local.name_prefix}_-lb-backend-address-pool_${count.index}"
  count           = var.public_load_balancer ? 1 : length(var.subnets)
}

resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "${local.name_prefix}-lb-probe"
  port                = 9000
  protocol            = "Http"
  request_path        = "/health"
  probe_threshold     = 3
  interval_in_seconds = 5
}

# Resources azurerm_lb_rule.lb_rule_public_lb and azurerm_lb_rule.lb_rule_private_lb
# used to be a single resource with multiple conditions. They were split in order to
# make the code easier to read.
#
resource "azurerm_lb_rule" "lb_rule_public_lb" {
  count = var.public_load_balancer ? length(var.sidecar_ports) : 0

  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool[0].id]
  backend_port                   = element(var.sidecar_ports, count.index)
  frontend_ip_configuration_name = local.frontend_ip_config_name
  frontend_port                  = element(var.sidecar_ports, count.index)
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "${local.name_prefix}-rule-${element(var.sidecar_ports, count.index)}"
  probe_id                       = azurerm_lb_probe.lb_probe.id
  protocol                       = "Tcp"
}

resource "azurerm_lb_rule" "lb_rule_private_lb" {
  for_each = local.subnets_and_ports

  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool[index(var.subnets, each.key)].id]
  backend_port                   = each.value
  frontend_ip_configuration_name = "${local.frontend_ip_config_name}_${index(var.subnets, each.key)}"
  frontend_port                  = each.value
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "${local.name_prefix}-rule-${each.value}_${each.key}"
  probe_id                       = azurerm_lb_probe.lb_probe.id
  protocol                       = "Tcp"
}
