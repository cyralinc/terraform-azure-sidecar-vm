# Cyral Sidecar Azure module for Terraform

## Usage

### Minimal configuration

```hcl
provider "azurerm" {
  # This feature is to immediately destroy secrets when `terraform destroy`
  # is executed. We advise you to remove it for production sidecars.
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

module "cyral_sidecar" {
  source = "cyralinc/sidecar-vm/azure"
  version = "~> 0.0" # terraform module version
  
  sidecar_version = ""
  sidecar_id      = ""

  control_plane   = ""

  sidecar_ports = [443, 3306, 5432]
  # If `repositories_supported` is ommitted, all repositories will be supported,
  # though you have to open the desired ports using `sidecar_ports`.

  subnets = []

  container_registry          = ""

  client_id         = ""
  client_secret     = ""

  resource_group_location     = ""  
  admin_public_key            = ""
}
```

**Note:**

- `name_prefix` is defined automatically. If you wish to define a custom
  `name_prefix`, please keep in mind that its length must be **at most 24
  characters**.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=3.29.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=3.29.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_secret.sidecar_secrets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_lb.lb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) | resource |
| [azurerm_lb_backend_address_pool.lb_backend_address_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_probe.lb_probe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_rule.lb_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_linux_virtual_machine_scale_set.scale_set](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine_scale_set) | resource |
| [azurerm_log_analytics_workspace.log_analytics_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_autoscale_setting.monitor_autoscale_setting](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting) | resource |
| [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.security_rule_metrics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.security_rule_sidecar_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.security_rule_ssh](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_public_ip.public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_resource_group_policy_assignment.user_policies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_role_assignment.role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_definition.role_definition](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azurerm_subnet_network_security_group_association.subnet_nsg_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_user_assigned_identity.user_assigned_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_public_key"></a> [admin\_public\_key](#input\_admin\_public\_key) | The Public Key which should be used for authentication, which needs to be at least 2048-bit and in ssh-rsa format | `string` | n/a | yes |
| <a name="input_auto_scale_default"></a> [auto\_scale\_default](#input\_auto\_scale\_default) | The number of instances that are available for scaling if metrics are not available for evaluation. The default is only used if the current instance count is lower than the default. Valid values are between 0 and 1000 | `number` | `1` | no |
| <a name="input_auto_scale_enabled"></a> [auto\_scale\_enabled](#input\_auto\_scale\_enabled) | Set true to enable the auto scale setting, false to disable. Only for debugging | `bool` | `true` | no |
| <a name="input_auto_scale_max"></a> [auto\_scale\_max](#input\_auto\_scale\_max) | The maximum number of instances for this resource. Valid values are between 0 and 1000 | `number` | `2` | no |
| <a name="input_auto_scale_min"></a> [auto\_scale\_min](#input\_auto\_scale\_min) | The minimum number of instances for this resource. Valid values are between 0 and 1000 | `number` | `1` | no |
| <a name="input_client_id"></a> [client\_id](#input\_client\_id) | The client id assigned to the sidecar | `string` | n/a | yes |
| <a name="input_client_secret"></a> [client\_secret](#input\_client\_secret) | The client secret assigned to the sidecar | `string` | n/a | yes |
| <a name="input_container_registry"></a> [container\_registry](#input\_container\_registry) | Address of the container registry where Cyral images are stored | `string` | n/a | yes |
| <a name="input_control_plane"></a> [control\_plane](#input\_control\_plane) | Address of the control plane - <tenant>.app.cyral.com | `string` | n/a | yes |
| <a name="input_custom_user_data"></a> [custom\_user\_data](#input\_custom\_user\_data) | Ancillary consumer supplied user-data script. Bash scripts must be added to a map as a value of the key `pre` and/or `post` denoting execution order with respect to sidecar installation. (Approx Input Size = 19KB) | `map(any)` | <pre>{<br>  "post": "",<br>  "pre": ""<br>}</pre> | no |
| <a name="input_external_tls_type"></a> [external\_tls\_type](#input\_external\_tls\_type) | TLS mode for the control plane - tls, tls-skip-verify, no-tls | `string` | `"tls"` | no |
| <a name="input_hc_vault_integration_id"></a> [hc\_vault\_integration\_id](#input\_hc\_vault\_integration\_id) | HashiCorp Vault integration ID | `string` | `""` | no |
| <a name="input_iam_actions_role_permissions"></a> [iam\_actions\_role\_permissions](#input\_iam\_actions\_role\_permissions) | (Optional) List of IAM role actions permissions that will be attached to the sidecar IAM role | `list(string)` | `[]` | no |
| <a name="input_iam_no_actions_role_permissions"></a> [iam\_no\_actions\_role\_permissions](#input\_iam\_no\_actions\_role\_permissions) | (Optional) List of IAM role disallowed actions permissions that will be attached to the sidecar IAM role | `list(string)` | `[]` | no |
| <a name="input_iam_policies"></a> [iam\_policies](#input\_iam\_policies) | (Optional) List of IAM policies that will be attached to the sidecar IAM role | `list(string)` | `[]` | no |
| <a name="input_instance_os_disk_storage_account_type"></a> [instance\_os\_disk\_storage\_account\_type](#input\_instance\_os\_disk\_storage\_account\_type) | The Type of Storage Account which should back this Data Disk | `string` | `"Standard_LRS"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Azure virtual machine scale set instance type for the sidecar instances | `string` | `"Standard_F2"` | no |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Location in Azure Key Vault to store secrets | `string` | `""` | no |
| <a name="input_log_integration"></a> [log\_integration](#input\_log\_integration) | Logs destination | `string` | `"azure-log-analytics"` | no |
| <a name="input_metrics_integration"></a> [metrics\_integration](#input\_metrics\_integration) | Metrics destination | `string` | `""` | no |
| <a name="input_metrics_source_address_prefixes"></a> [metrics\_source\_address\_prefixes](#input\_metrics\_source\_address\_prefixes) | Source address prefixes that will be able to reach the metrics port | `set(string)` | `[]` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for names of created resources. Maximum length is 24 characters | `string` | `""` | no |
| <a name="input_public_load_balancer"></a> [public\_load\_balancer](#input\_public\_load\_balancer) | Set true to add a public IP to the load balancer | `bool` | `false` | no |
| <a name="input_repositories_supported"></a> [repositories\_supported](#input\_repositories\_supported) | List of all repositories that will be supported by the sidecar (lower case only) | `list(string)` | <pre>[<br>  "denodo",<br>  "dremio",<br>  "dynamodb",<br>  "mongodb",<br>  "mysql",<br>  "oracle",<br>  "postgresql",<br>  "redshift",<br>  "snowflake",<br>  "sqlserver",<br>  "s3"<br>]</pre> | no |
| <a name="input_resource_group_location"></a> [resource\_group\_location](#input\_resource\_group\_location) | Azure resource group location | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Azure resource group name | `string` | `""` | no |
| <a name="input_secret_manager_type"></a> [secret\_manager\_type](#input\_secret\_manager\_type) | Define secret manager type for sidecar\_client\_id and sidecar\_client\_secret | `string` | `"azure-key-vault"` | no |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | Location in Azure Key Vault to store client\_id, client\_secret and container\_registry\_key | `string` | `""` | no |
| <a name="input_sidecar_id"></a> [sidecar\_id](#input\_sidecar\_id) | Sidecar identifier | `string` | n/a | yes |
| <a name="input_sidecar_ports"></a> [sidecar\_ports](#input\_sidecar\_ports) | List of ports allowed to connect to the sidecar | `list(number)` | n/a | yes |
| <a name="input_sidecar_version"></a> [sidecar\_version](#input\_sidecar\_version) | Version of the sidecar | `string` | n/a | yes |
| <a name="input_source_image_offer"></a> [source\_image\_offer](#input\_source\_image\_offer) | Specifies the offer of the image used to create the virtual machines | `string` | `"0001-com-ubuntu-server-jammy"` | no |
| <a name="input_source_image_publisher"></a> [source\_image\_publisher](#input\_source\_image\_publisher) | Specifies the publisher of the image used to create the virtual machines | `string` | `"Canonical"` | no |
| <a name="input_source_image_sku"></a> [source\_image\_sku](#input\_source\_image\_sku) | Specifies the SKU of the image used to create the virtual machines | `string` | `"24_04-lts"` | no |
| <a name="input_source_image_version"></a> [source\_image\_version](#input\_source\_image\_version) | Specifies the version of the image used to create the virtual machines | `string` | `"latest"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnets to add sidecar to (list of string) | `list(string)` | n/a | yes |
| <a name="input_vm_username"></a> [vm\_username](#input\_vm\_username) | Virtual machine user name | `string` | `"ubuntu"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sidecar_load_balancer_dns"></a> [sidecar\_load\_balancer\_dns](#output\_sidecar\_load\_balancer\_dns) | Sidecar load balancer DNS endpoint. |
<!-- END_TF_DOCS -->
