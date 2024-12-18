data "azurerm_client_config" "current" {}

locals {
  sidecar_endpoint = var.public_load_balancer ? azurerm_public_ip.public_ip[0].fqdn : azurerm_lb.lb.private_ip_address

  curl        = var.tls_skip_verify ? "curl -k" : "curl"
  name_prefix = var.name_prefix == "" ? "cyral-${substr(lower(var.sidecar_id), -6, -1)}" : var.name_prefix

  templatevars = {
    ca_certificate_secret_id          = local.ca_certificate_secret_id
    container_registry                = var.container_registry
    controlplane_host                 = var.control_plane
    curl                              = "${local.curl} --connect-timeout ${var.curl_connect_timeout}"
    idp_sso_login_url                 = var.idp_sso_login_url
    name_prefix                       = local.name_prefix
    recycle_health_check_interval_sec = var.recycle_health_check_interval_sec
    repositories_supported            = join(",", var.repositories_supported)
    resource_group_name               = azurerm_resource_group.resource_group.name
    resource_group_location           = azurerm_resource_group.resource_group.location
    sidecar_endpoint                  = local.sidecar_endpoint
    sidecar_id                        = var.sidecar_id
    sidecar_secret_id                 = local.secret_id
    sidecar_version                   = var.sidecar_version
    tls_certificate_secret_id         = local.tls_certificate_secret_id
    tls_type                          = var.tls_skip_verify ? "tls-skip-verify" : "tls"
    vm_username                       = var.vm_username
  }

  cloud_init_func = templatefile("${path.module}/files/cloud-init-functions.sh.tmpl", local.templatevars)
  cloud_init_pre  = templatefile("${path.module}/files/cloud-init-pre.sh.tmpl", local.templatevars)
  cloud_init_post = templatefile("${path.module}/files/cloud-init-post.sh.tmpl", local.templatevars)
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

resource "azurerm_role_assignment" "role_assignment" {
  scope                = azurerm_linux_virtual_machine_scale_set.scale_set.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.user_assigned_identity.principal_id
}
