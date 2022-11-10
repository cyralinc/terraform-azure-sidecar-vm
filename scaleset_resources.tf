#locals {
#  first_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+wWK73dCr+jgQOAxNsHAnNNNMEMWOHYEccp6wJm2gotpr9katuF/ZAdou5AaW1C61slRkHRkpRRX9FA9CYBiitZgvCCz+3nWNN7l/Up54Zps/pHWGZLHNJZRYyAB6j5yVLMVHIHriY49d/GZTZVNB8GoJv9Gakwc/fuEZYYl4YDFiGMBP///TzlI4jhiJzjKnEvqPFki5p2ZRJqcbCiF4pJrxUQR/RXqVFQdbRLZgYfJ8xGB878RENq3yQ39d8dVOkq4edbkzwcUmwwwkYVPIoDGsYLaRHnG+To7FvMeyO7xDVQkMKzopTQV8AuKpyvpqu0a9pWOMaiCyDytO7GGN you@me.com"
#}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "cyral_sidecar" {
  name     = "cyral_sidecar"
  location = "brazilsouth"
}

resource "azurerm_virtual_network" "virtual-network" {
  name                = "cyral-virtual-network"
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
  location            = azurerm_resource_group.cyral_sidecar.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "internal-subnet" {
  name                 = "cyral-internal-subnet"
  resource_group_name  = azurerm_resource_group.cyral_sidecar.name
  virtual_network_name = azurerm_virtual_network.virtual-network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "public-ip" {
  name                = "cyral-public-ip"
  location            = azurerm_resource_group.cyral_sidecar.location
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
  allocation_method   = "Static"
  # idle_timeout_in_minutes = 30
  sku = "Standard"
}

resource "azurerm_lb" "vmss" {
  name                = "vmss-lb"
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
  name            = "BackEndAddressPool"
  depends_on = [
    azurerm_lb.vmss
  ]
}

resource "azurerm_lb_probe" "vmss" {
  loadbalancer_id = azurerm_lb.vmss.id
  name            = "ssh-running-probe"
  port            = 22
}

resource "azurerm_lb_rule" "lbnatrule" {
  loadbalancer_id                = azurerm_lb.vmss.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.vmss.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpepool.id]
}

# resource "azurerm_network_interface" "nic" {
#   name = "cyral-nic"
#   location = azurerm_resource_group.cyral_sidecar.location
#   resource_group_name = azurerm_resource_group.cyral_sidecar.name
#   ip_configuration {
#     name = "cyral-ip-public"
#     subnet_id = azurerm_subnet.internal-subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id = azurerm_public_ip.public-ip.id
#   }

# }

resource "azurerm_network_security_group" "nsg" {
  name                = "cyral-nsg"
  location            = azurerm_resource_group.cyral_sidecar.location
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
}

variable "input_rules" {
  type = map(any)
  default = {
    101 = 80
    102 = 443
    103 = 3389
    104 = 22
  }
}

resource "azurerm_network_security_rule" "security_rule" {
  for_each                    = var.input_rules
  resource_group_name         = azurerm_resource_group.cyral_sidecar.name
  name                        = "port_in_${each.value}"
  priority                    = each.key
  direction                   = "Inbound"
  access                      = "Allow"
  source_port_range           = "*"
  protocol                    = "Tcp"
  destination_port_range      = each.value
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "ngassociation" {
  subnet_id                 = azurerm_subnet.internal-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_user_assigned_identity" "cyral_assigned_identity" {
  location            = azurerm_resource_group.cyral_sidecar.location
  name                = "${local.name_prefix}-assigned_identity"
  resource_group_name = azurerm_resource_group.cyral_sidecar.name
}

resource "azurerm_role_assignment" "example" {
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
  admin_username = "adminuser"
  admin_password = ""

  disable_password_authentication = false

  #admin_ssh_key {
  #  username   = "adminuser"
  #  public_key = local.first_public_key
  #}

  #custom_data = filebase64("${path.module}/files/cloud-init-azure.sh")

  custom_data = base64encode(<<-EOT
  #!/bin/sh  
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
    name    = "example"
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

# resource "azurerm_storage_account" "appstore" {
#   name = "appstore123"
#   resource_group_name = azurerm_resource_group.cyral_sidecar.name
#   location = azurerm_resource_group.cyral_sidecar.location
#   account_tier = "Standard"
#   account_replication_type = "LRS"
#   #allow_blob_public_access = true
# }

# resource "azurerm_storage_container" "data" {
#   name = "data"
#   storage_account_name = "appstore123"
#   container_access_type = "blob"
#   depends_on = [
#     azurerm_storage_account.appstore
#   ]
# }

# resource "azurerm_storage_blob" "init-shell" {
#   name = "cloud-init-azure-post.sh.tmpl"
#   storage_account_name = "appstore123"
#   storage_container_name = "data"
#   type = "Block"
#   source = "cloud-init-azure-post.sh.tmpl"
#   depends_on = [
#     azurerm_storage_container.data
#   ]
# }

# resource "azurerm_virtual_machine_scale_set_extension" "example" {
#   name                         = "example"
#   virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.cyral-sidecar-asg.id
#   publisher                    = "Microsoft.Azure.Extensions"
#   type                         = "CustomScript"
#   type_handler_version         = "2.0"

#   # settings = <<SETTINGS
#   # {
#   #   "fileUris": ["https://${azurerm_storage_account.appstore.name}"]
#   # }
#   # SETTINGS

#   settings = jsonencode({
#     "commandToExecute" = "sudo mkdir -p /etc/apt/testeCleber"
#   })

# }
