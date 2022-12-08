locals {
  sidecar_endpoint = azurerm_public_ip.public-ip.fqdn

  protocol    = var.external_tls_type == "no-tls" ? "http" : "https"
  curl        = var.external_tls_type == "tls-skip-verify" ? "curl -k" : "curl"
  name_prefix = var.name_prefix == "" ? "cyral-${substr(lower(var.sidecar_id), -6, -1)}" : var.name_prefix

  templatevars = {
    sidecar_id                    = var.sidecar_id
    name_prefix                   = local.name_prefix
    controlplane_host             = var.control_plane
    container_registry            = var.container_registry
    container_registry_username   = var.container_registry_username
    log_integration               = var.log_integration
    secrets_location              = var.secrets_location
    key_vault_name                = azurerm_key_vault.cyral-sidecar-secret.name
    metrics_integration           = var.metrics_integration
    hc_vault_integration_id       = var.hc_vault_integration_id
    curl                          = local.curl
    sidecar_version               = var.sidecar_version
    repositories_supported        = join(",", var.repositories_supported)
    protocol                      = local.protocol
    sidecar_endpoint              = local.sidecar_endpoint
    mongodb_port_alloc_range_low  = var.mongodb_port_alloc_range_low
    mongodb_port_alloc_range_high = var.mongodb_port_alloc_range_high
    mysql_multiplexed_port        = var.mysql_multiplexed_port
    load_balancer_tls_ports       = join(",", var.load_balancer_tls_ports)
    secret_manager_type           = var.secret_manager_type
    dd_api_key                    = var.dd_api_key
    splunk_index                  = var.splunk_index
    splunk_host                   = var.splunk_host
    splunk_port                   = var.splunk_port
    splunk_tls                    = var.splunk_tls
    splunk_token                  = var.splunk_token
    sumologic_host                = var.sumologic_host
    sumologic_uri                 = var.sumologic_uri
    elk_address                   = var.elk_address
    elk_username                  = var.elk_username
    elk_password                  = var.elk_password

    username_vm = var.username_vm
    password_vm = var.password_vm
  }

  cloud_init_sh = templatefile("${path.module}/files/cloud-init-azure.sh.tmpl", local.templatevars)
}
