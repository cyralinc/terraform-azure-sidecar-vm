data "azurerm_client_config" "current" {}

locals {
  frontend_ip_config_name = "${local.name_prefix}_lb-frontend-ip"
  sidecar_endpoint        = var.public_load_balancer ? azurerm_public_ip.public_ip[0].fqdn : azurerm_lb.lb.private_ip_address
  subnets_and_ports       = var.public_load_balancer ? toset([]) : toset(setproduct(var.subnets, var.sidecar_ports))

  curl        = var.tls_skip_verify ? "curl -k" : "curl"
  name_prefix = var.name_prefix == "" ? "cyral-${substr(lower(var.sidecar_id), -6, -1)}" : var.name_prefix

  templatevars = {
    ca_certificate_secret_name        = azurerm_key_vault_secret.self_signed_ca.name
    container_registry                = var.container_registry
    controlplane_host                 = var.control_plane
    curl                              = "${local.curl} --connect-timeout ${var.curl_connect_timeout}"
    idp_sso_login_url                 = var.idp_sso_login_url
    key_vault_name                    = local.key_vault_name
    name_prefix                       = local.name_prefix
    recycle_health_check_interval_sec = var.recycle_health_check_interval_sec
    repositories_supported            = join(",", var.repositories_supported)
    resource_group_name               = azurerm_resource_group.resource_group.name
    resource_group_location           = azurerm_resource_group.resource_group.location
    sidecar_endpoint                  = local.sidecar_endpoint
    sidecar_id                        = var.sidecar_id
    sidecar_secret_name               = local.secret_name
    sidecar_version                   = var.sidecar_version
    tls_certificate_secret_name       = azurerm_key_vault_secret.self_signed_tls_cert.name
    tls_type                          = var.tls_skip_verify ? "tls-skip-verify" : "tls"
    vm_username                       = var.vm_username
  }

  cloud_init_func = templatefile("${path.module}/files/cloud-init-functions.sh.tmpl", local.templatevars)
  cloud_init_pre  = templatefile("${path.module}/files/cloud-init-pre.sh.tmpl", local.templatevars)
  cloud_init_post = templatefile("${path.module}/files/cloud-init-post.sh.tmpl", local.templatevars)
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

resource "azurerm_network_security_group" "nsg" {
  name                = "${local.name_prefix}-network-security-group"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_network_security_rule" "security_rule_ssh" {
  count = length(var.ssh_source_address_prefixes) == 0 ? 0 : 1

  resource_group_name         = azurerm_resource_group.resource_group.name
  name                        = "${local.name_prefix}-nsr-ssh"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  source_port_range           = "*"
  protocol                    = "Tcp"
  destination_port_range      = 22
  source_address_prefixes     = var.ssh_source_address_prefixes
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "security_rule_monitoring" {
  count = length(var.monitoring_source_address_prefixes) == 0 ? 0 : 1

  resource_group_name         = azurerm_resource_group.resource_group.name
  name                        = "${local.name_prefix}-nsr-monitoring"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  source_port_range           = "*"
  protocol                    = "Tcp"
  destination_port_range      = 9000
  source_address_prefixes     = var.monitoring_source_address_prefixes
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "security_rule_sidecar_inbound" {
  count = length(var.sidecar_ports)

  resource_group_name         = azurerm_resource_group.resource_group.name
  name                        = "${local.name_prefix}-nsr-${element(var.sidecar_ports, count.index)}"
  priority                    = 102 + count.index
  direction                   = "Inbound"
  access                      = "Allow"
  source_port_range           = "*"
  protocol                    = "Tcp"
  destination_port_range      = element(var.sidecar_ports, count.index)
  source_address_prefixes     = var.db_source_address_prefixes
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
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
    "MetricsPort" : 9000
  }
  sku                             = var.instance_type
  admin_username                  = var.vm_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.vm_username
    public_key = var.admin_ssh_key
  }

  custom_data = base64encode(<<-EOT
  #!/bin/bash -e
  ${local.cloud_init_func}
  ${try(lookup(var.custom_user_data, "pre"), "")}
  ${local.cloud_init_pre}
  ${try(lookup(var.custom_user_data, "pre_sidecar_start"), "")}
  ${local.cloud_init_post}
  ${try(lookup(var.custom_user_data, "post"), "")}
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
      name    = "${local.name_prefix}-network-interface_${network_interface.key}"
      primary = network_interface.key == 0

      ip_configuration {
        name                                   = "${local.name_prefix}_subnet_${network_interface.key}"
        primary                                = network_interface.key == 0
        subnet_id                              = network_interface.value
        load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_backend_address_pool[network_interface.key].id]

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

resource "azurerm_lb_nat_rule" "ssh_nat_rule" {
  count               = 1 # Assuming 2 instances in the scale set
  name                = "ssh-rule-${count.index + 1}"
  resource_group_name = azurerm_resource_group.resource_group.name
  loadbalancer_id     = azurerm_lb.lb.id

  frontend_ip_configuration_name = local.frontend_ip_config_name

  protocol                = "Tcp"
  frontend_port           = 5000 + count.index + 1 # e.g., 5001, 5002
  backend_port            = 22
  idle_timeout_in_minutes = 4
}