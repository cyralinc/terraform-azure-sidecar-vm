locals {
  sidecar_endpoint = var.public_load_balancer ? azurerm_public_ip.public_ip[0].fqdn : ""

  protocol       = var.external_tls_type == "no-tls" ? "http" : "https"
  curl           = var.external_tls_type == "tls-skip-verify" ? "curl -k" : "curl"
  name_prefix    = var.name_prefix == "" ? "cyral-${substr(lower(var.sidecar_id), -6, -1)}" : var.name_prefix
  secret_name    = var.secret_name == "" ? "cyral-sidecars-${var.sidecar_id}-secrets" : var.secret_name
  key_vault_name = var.key_vault_name == "" ? "${local.name_prefix}-kv" : var.key_vault_name

  templatevars = {
    sidecar_id                  = var.sidecar_id
    name_prefix                 = local.name_prefix
    controlplane_host           = var.control_plane
    container_registry          = var.container_registry
    container_registry_username = var.container_registry_username
    log_integration             = var.log_integration
    key_vault_name              = local.key_vault_name
    secret_name                 = local.secret_name
    metrics_integration         = var.metrics_integration
    hc_vault_integration_id     = var.hc_vault_integration_id
    curl                        = local.curl
    sidecar_version             = var.sidecar_version
    repositories_supported      = join(",", var.repositories_supported)
    protocol                    = local.protocol
    sidecar_endpoint            = local.sidecar_endpoint
    secret_manager_type         = var.secret_manager_type
    dd_api_key                  = var.dd_api_key
    splunk_index                = var.splunk_index
    splunk_host                 = var.splunk_host
    splunk_port                 = var.splunk_port
    splunk_tls                  = var.splunk_tls
    splunk_token                = var.splunk_token
    sumologic_host              = var.sumologic_host
    sumologic_uri               = var.sumologic_uri
    elk_address                 = var.elk_address
    elk_username                = var.elk_username
    elk_password                = var.elk_password
    vm_username                 = var.vm_username
  }

  cloud_init_sh = templatefile("${path.module}/files/cloud-init-azure.sh.tmpl", local.templatevars)
}
