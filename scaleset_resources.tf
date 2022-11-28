data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "cyral_sidecar" {
  name     = "${local.name_prefix}-resource-group"
  location = "brazilsouth"
}

resource "azurerm_log_analytics_workspace" "cyral_log_analytics_workspace" {
  name                = "${local.name_prefix}log-analytics"
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
  name                = "${local.name_prefix}-public-ip"
  location            = azurerm_resource_group.cyral_sidecar.location
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
  allocation_method   = "Static"
  domain_name_label = "${local.name_prefix}"
  sku = "Standard"
}

resource "azurerm_lb" "vmss" {
  name                = "${local.name_prefix}-lb"
  location            = azurerm_resource_group.cyral_sidecar.location
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.public-ip.id
  }

  depends_on = [
    azurerm_public_ip.public-ip
  ]

}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id = azurerm_lb.vmss.id
  name            = "${local.name_prefix}-lb-backend-address-pool"
  depends_on = [
    azurerm_lb.vmss
  ]
}

resource "azurerm_lb_probe" "vmss" {
  loadbalancer_id = azurerm_lb.vmss.id
  name            = "${local.name_prefix}-lb-probe"
  port            = 22
}

resource "azurerm_lb_rule" "lbnatrule" {
  loadbalancer_id                = azurerm_lb.vmss.id
  name                           = "SSH"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.vmss.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpepool.id]
}

resource "azurerm_lb_rule" "lbnatrule-port-db" {
  loadbalancer_id                = azurerm_lb.vmss.id
  name                           = "${local.name_prefix}-tg${element(var.sidecar_ports, count.index)}"
  protocol                       = "Tcp"
  frontend_port                  = "${element(var.sidecar_ports, count.index)}"
  backend_port                   = "${element(var.sidecar_ports, count.index)}"
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.vmss.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpepool.id]
  count                          = "${length(var.sidecar_ports)}"
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
  destination_port_range      = "${element(var.sidecar_ports, count.index)}"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  count                          = "${length(var.sidecar_ports)}"
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
  scope                = azurerm_linux_virtual_machine_scale_set.cyral-sidecar-asg.id
  role_definition_name = "Owner"
  principal_id         = azurerm_user_assigned_identity.cyral_assigned_identity.principal_id
}

resource "azurerm_linux_virtual_machine_scale_set" "cyral-sidecar-asg" {
  name                = "${local.name_prefix}-machine-scale-set"
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
  location            = azurerm_resource_group.cyral_sidecar.location
  sku                 = "Standard_F2"
  instances           = 1
  #TODO temporary username and password
  admin_username = var.username_vm
  admin_password = var.password_vm

  disable_password_authentication = false

  #admin_ssh_key {
  #  username   = "adminuser"
  #  public_key = local.first_public_key
  #}

  custom_data = base64encode(<<-EOT
  #!/bin/bash -xe
  ${local.cloud_init_sh}  
  EOT
  )

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
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

resource "azurerm_monitor_autoscale_setting" "monitor-autoscale-setting" {
  name                = "${local.name_prefix}-monitor-autoscale-setting"
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
  location            = azurerm_resource_group.cyral_sidecar.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.cyral-sidecar-asg.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.cyral-sidecar-asg.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.cyral-sidecar-asg.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}
