data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "cyral_sidecar" {
  name     = var.resource_group_name == "" ? "${local.name_prefix}" : var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_log_analytics_workspace" "cyral_log_analytics_workspace" {
  name                = "${local.name_prefix}-log-analytics"
  location            = azurerm_resource_group.cyral_sidecar.location
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
  retention_in_days   = 30
}

resource "azurerm_virtual_network" "virtual-network" {
  name                = "${local.name_prefix}-virtual-network"
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
  location            = azurerm_resource_group.cyral_sidecar.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "internal-subnet" {
  name                 = "${local.name_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.cyral_sidecar.name
  virtual_network_name = azurerm_virtual_network.virtual-network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "public-ip" {
  count               = var.public_load_balance ? 1 : 0
  name                = "${local.name_prefix}-public-ip"
  location            = azurerm_resource_group.cyral_sidecar.location
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
  allocation_method   = "Static"
  domain_name_label   = local.name_prefix
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = "${local.name_prefix}-lb"
  location            = azurerm_resource_group.cyral_sidecar.location
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
  sku                 = "Standard"
  sku_tier            = "Regional"

  dynamic "frontend_ip_configuration" {
    for_each = var.public_load_balance ? [1] : []
    content {
      name                 = "PublicIPAddress"
      public_ip_address_id = azurerm_public_ip.public-ip[0].id
    }
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "${local.name_prefix}-lb-backend-address-pool"
  depends_on = [
    azurerm_lb.lb
  ]
}

resource "azurerm_lb_probe" "lb_probe" {
  count           = var.public_load_balance ? 1 : 0
  loadbalancer_id = azurerm_lb.lb.id
  name            = "${local.name_prefix}-lb-probe"
  port            = 22
}

resource "azurerm_lb_rule" "lbnatrule" {
  count           = var.public_load_balance ? 1 : 0
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "SSH"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.lb_probe[0].id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpepool.id]
}

resource "azurerm_lb_rule" "lbnatrule_port_db" {  
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "${local.name_prefix}-tg${element(var.sidecar_ports, count.index)}"
  protocol                       = "Tcp"
  frontend_port                  = element(var.sidecar_ports, count.index)
  backend_port                   = element(var.sidecar_ports, count.index)
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.lb_probe[0].id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpepool.id]
  count                          = var.public_load_balance ? length(var.sidecar_ports) : 0
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${local.name_prefix}-network-security-group"
  location            = azurerm_resource_group.cyral_sidecar.location
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
}

resource "azurerm_network_security_rule" "security_rule_ssh" {
  resource_group_name         = azurerm_resource_group.cyral_sidecar.name
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
  resource_group_name         = azurerm_resource_group.cyral_sidecar.name
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
  subnet_id                 = azurerm_subnet.internal-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_user_assigned_identity" "cyral_assigned_identity" {
  location            = azurerm_resource_group.cyral_sidecar.location
  name                = "${local.name_prefix}-user-assigned_identity"
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
}

resource "azurerm_role_assignment" "role_assignment" {
  scope                = azurerm_linux_virtual_machine_scale_set.cyral_sidecar_asg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.cyral_assigned_identity.principal_id
}

resource "azurerm_linux_virtual_machine_scale_set" "cyral_sidecar_asg" {
  name                            = "${local.name_prefix}-machine-scale-set"
  resource_group_name             = azurerm_resource_group.cyral_sidecar.name
  location                        = azurerm_resource_group.cyral_sidecar.location
  sku                             = var.instance_type
  instances                       = 1
  admin_username                  = var.username_vm
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.username_vm
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

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.internal-subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cyral_assigned_identity.id]
  }

  depends_on = [
    azurerm_virtual_network.virtual-network
  ]

}

resource "azurerm_monitor_autoscale_setting" "monitor_autoscale_setting" {
  count               = var.auto_scale_count
  name                = "${local.name_prefix}-monitor-autoscale-setting"
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
  location            = azurerm_resource_group.cyral_sidecar.location
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
