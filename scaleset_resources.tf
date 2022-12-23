data "azurerm_client_config" "current" {}

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
      name                 = "${local.name_prefix}_${var.frontend_ip_config_name}"
      public_ip_address_id = azurerm_public_ip.public_ip[0].id
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.public_load_balancer ? [] : var.subnets
    content {
      name                          = format("${local.name_prefix}_${var.frontend_ip_config_name}_%s", index(var.subnets, frontend_ip_configuration.value))
      subnet_id                     = frontend_ip_configuration.value
      private_ip_address_allocation = "Dynamic"
      private_ip_address_version    = "IPv4"
    }
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
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

locals {
  subnets_and_ports = setproduct(var.subnets, var.sidecar_ports)
}

resource "azurerm_lb_rule" "lbnatrule_port_db" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = var.public_load_balancer ? "${local.name_prefix}-tg${element(var.sidecar_ports, count.index)}" : "${local.name_prefix}-tg${local.subnets_and_ports[count.index][1]}_${count.index}"
  protocol                       = "Tcp"
  frontend_port                  = var.public_load_balancer ? element(var.sidecar_ports, count.index) : local.subnets_and_ports[count.index][1]
  backend_port                   = var.public_load_balancer ? element(var.sidecar_ports, count.index) : local.subnets_and_ports[count.index][1]
  frontend_ip_configuration_name = var.public_load_balancer ? "${local.name_prefix}_${var.frontend_ip_config_name}" : format("${local.name_prefix}_${var.frontend_ip_config_name}_%s", index(var.subnets, local.subnets_and_ports[count.index][0]))
  probe_id                       = azurerm_lb_probe.lb_probe.id
  backend_address_pool_ids       = var.public_load_balancer ? [azurerm_lb_backend_address_pool.bpepool[0].id] : [azurerm_lb_backend_address_pool.bpepool[index(var.subnets, local.subnets_and_ports[count.index][0])].id]
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

resource "azurerm_network_security_rule" "security_rule" {
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

resource "azurerm_subnet_network_security_group_association" "ngassociation" {
  count                     = length(var.subnets)
  subnet_id                 = var.subnets[count.index]
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_user_assigned_identity" "cyral_assigned_identity" {
  location            = azurerm_resource_group.resource_group.location
  name                = "${local.name_prefix}-user-assigned_identity"
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_role_assignment" "role_assignment" {
  scope                = azurerm_linux_virtual_machine_scale_set.cyral_sidecar_asg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.cyral_assigned_identity.principal_id
}

resource "azurerm_linux_virtual_machine_scale_set" "cyral_sidecar_asg" {
  name                            = "${local.name_prefix}-machine-scale-set"
  resource_group_name             = azurerm_resource_group.resource_group.name
  location                        = azurerm_resource_group.resource_group.location
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

  network_interface {
    name    = "${local.name_prefix}-network-interface"
    primary = true

    # dynamic "ip_configuration" {
    #   for_each = var.subnets
    #   content {
    #     name                                   = "subnet"
    #     primary                                = true
    #     subnet_id                              = ip_configuration.value
    #     load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
    #     public_ip_address {
    #       name = "public_ip"
    #     }
    #   }
    # }
    ip_configuration {
      name                                   = "subnet"
      primary                                = true
      subnet_id                              = var.subnets[0]
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool[0].id]
      public_ip_address {
        name = "public_ip"
      }
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cyral_assigned_identity.id]
  }
}

resource "azurerm_monitor_autoscale_setting" "monitor_autoscale_setting" {
  count               = var.auto_scale_count
  name                = "${local.name_prefix}-monitor-autoscale-setting"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.cyral_sidecar_asg.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.auto_scale_default
      minimum = var.auto_scale_min
      maximum = var.auto_scale_max
    }
  }
}
