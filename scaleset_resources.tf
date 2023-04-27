data "azurerm_client_config" "current" {}

locals {
  subnets_and_ports       = setproduct(var.subnets, var.sidecar_ports)
  frontend_ip_config_name = "lb-frontend-ip"
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name == "" ? "${local.name_prefix}" : var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "${local.name_prefix}-log-analytics"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  retention_in_days   = 30
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
      name                 = "${local.name_prefix}_${local.frontend_ip_config_name}"
      public_ip_address_id = azurerm_public_ip.public_ip[0].id
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.public_load_balancer ? [] : var.subnets
    content {
      name                          = format("${local.name_prefix}_${local.frontend_ip_config_name}_%s", index(var.subnets, frontend_ip_configuration.value))
      subnet_id                     = frontend_ip_configuration.value
      private_ip_address_allocation = "Dynamic"
      private_ip_address_version    = "IPv4"
    }
  }
}

resource "azurerm_lb_backend_address_pool" "lb_backend_address_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = format("${local.name_prefix}_-lb-backend-address-pool_%s", count.index)
  count           = var.public_load_balancer ? 1 : length(var.subnets)
}

resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "${local.name_prefix}-lb-probe"
  port                = 8888
  protocol            = "Tcp"
  probe_threshold     = 3
  interval_in_seconds = 5
}

resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = var.public_load_balancer ? "${local.name_prefix}-tg${element(var.sidecar_ports, count.index)}" : "${local.name_prefix}-tg${local.subnets_and_ports[count.index][1]}_${count.index}"
  protocol                       = "Tcp"
  frontend_port                  = var.public_load_balancer ? element(var.sidecar_ports, count.index) : local.subnets_and_ports[count.index][1]
  backend_port                   = var.public_load_balancer ? element(var.sidecar_ports, count.index) : local.subnets_and_ports[count.index][1]
  frontend_ip_configuration_name = var.public_load_balancer ? "${local.name_prefix}_${local.frontend_ip_config_name}" : format("${local.name_prefix}_${local.frontend_ip_config_name}_%s", index(var.subnets, local.subnets_and_ports[count.index][0]))
  probe_id                       = azurerm_lb_probe.lb_probe.id
  backend_address_pool_ids       = var.public_load_balancer ? [azurerm_lb_backend_address_pool.lb_backend_address_pool[0].id] : [azurerm_lb_backend_address_pool.lb_backend_address_pool[index(var.subnets, local.subnets_and_ports[count.index][0])].id]
  count                          = var.public_load_balancer ? length(var.sidecar_ports) : length(local.subnets_and_ports)
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${local.name_prefix}-network-security-group"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_network_security_rule" "security_rule_ssh" {
  resource_group_name         = azurerm_resource_group.resource_group.name
  name                        = "${local.name_prefix}-nsr-tg22"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  source_port_range           = "*"
  protocol                    = "Tcp"
  destination_port_range      = 22
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "security_rule_metrics" {
  count = length(var.metrics_source_address_prefixes) == 0 ? 0 : 1
  resource_group_name         = azurerm_resource_group.resource_group.name
  name                        = "${local.name_prefix}-nsr-metrics"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  source_port_range           = "*"
  protocol                    = "Tcp"
  destination_port_range      = var.metrics_port
  source_address_prefixes     = var.metrics_source_address_prefixes
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "security_rule_sidecar_inbound" {
  resource_group_name         = azurerm_resource_group.resource_group.name
  name                        = "${local.name_prefix}-nsr-tg${element(var.sidecar_ports, count.index)}"
  priority                    = 102 + count.index
  direction                   = "Inbound"
  access                      = "Allow"
  source_port_range           = "*"
  protocol                    = "Tcp"
  destination_port_range      = element(var.sidecar_ports, count.index)
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  count                       = length(var.sidecar_ports)
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  count                     = length(var.subnets)
  subnet_id                 = var.subnets[count.index]
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_user_assigned_identity" "user_assigned_identity" {
  location            = azurerm_resource_group.resource_group.location
  name                = "${local.name_prefix}-user-assigned_identity"
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_role_assignment" "role_assignment" {
  scope                = azurerm_linux_virtual_machine_scale_set.scale_set.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.user_assigned_identity.principal_id
}

resource "azurerm_linux_virtual_machine_scale_set" "scale_set" {
  name                = "${local.name_prefix}-machine-scale-set"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  tags = {
    "MetricsPort" : var.metrics_port
  }
  sku                             = var.instance_type
  admin_username                  = var.vm_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.vm_username
    public_key = var.admin_public_key
  }

  custom_data = base64encode(<<-EOT
  #!/bin/bash -xe
  ${lookup(var.custom_user_data, "pre")}
  ${local.cloud_init_sh}
  ${lookup(var.custom_user_data, "post")}
  EOT
  )

  source_image_reference {
    publisher = var.source_image_publisher
    offer     = var.source_image_offer
    sku       = var.source_image_sku
    version   = var.source_image_version
  }

  os_disk {
    storage_account_type = var.instance_os_disk_storage_account_type
    caching              = "ReadWrite"
  }

  dynamic "network_interface" {
    for_each = var.subnets
    content {
      name    = format("${local.name_prefix}-network-interface_%s", index(var.subnets, network_interface.value))
      primary = index(var.subnets, network_interface.value) == 0 ? true : false

      ip_configuration {
        name                                   = format("${local.name_prefix}_subnet_%s", index(var.subnets, network_interface.value))
        primary                                = index(var.subnets, network_interface.value) == 0 ? true : false
        subnet_id                              = network_interface.value
        load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_backend_address_pool[index(var.subnets, network_interface.value)].id]

        public_ip_address {
          name = "public_ip"
        }
      }
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.user_assigned_identity.id]
  }
}

resource "azurerm_monitor_autoscale_setting" "monitor_autoscale_setting" {
  name                = "${local.name_prefix}-monitor-autoscale-setting"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.scale_set.id
  enabled             = var.auto_scale_enabled

  profile {
    name = "defaultProfile"

    capacity {
      default = var.auto_scale_default
      minimum = var.auto_scale_min
      maximum = var.auto_scale_max
    }
  }
}
