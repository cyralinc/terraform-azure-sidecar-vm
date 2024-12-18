# Cyral sidecar module for Azure VM

Use this Terraform module to deploy a sidecar on Azure VM instances.

Refer to the [quickstart guide](https://github.com/cyral-quickstart/quickstart-sidecar-terraform-azure-vm#readme)
for more information on how to use this module or upgrade your sidecar.

## Architecture

![Deployment architecture](https://raw.githubusercontent.com/cyralinc/terraform-azure-sidecar-vm/main/images/azure_architecture.png)

The elements shown in the architecture diagram above are deployed by this module.
The module requires existing VPC and subnets in order to create the necessary
components for the sidecar to run. In a high-level, these are the resources deployed:

* VM
    * Scale set (responsible for managing VM instances)
    * Network load balancer (optional)
    * Security group
* Key Vault
    * Sidecar credentials
    * Sidecar CA certificate
    * Sidecar self-signed certificate
* IAM
    * Sidecar role
* Azure Analytics
    * Log group (optional)

## Usage

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
  version = "~> 1.0" # terraform module version
  
  sidecar_id    = ""
  control_plane = ""
  client_id     = ""
  client_secret = ""

  # Leave empty if you prefer to perform upgrades directly
  # from the control plane.
  sidecar_version = ""

  # Considering MongoDB ports are from the range 27017 to 27019
  sidecar_ports = [443, 3306, 5432, 27017, 27018, 27019]

  # Subnets to use to deploy VMs
  subnets = [""]
  
  # Source address prefixes for SSH into the VM instances
  ssh_source_address_prefixes = ["0.0.0.0/0"]
  # Source address prefixes to access ports defined in `sidecar_ports`
  db_source_address_prefixes = ["0.0.0.0/0"]
  # Source address prefixes to monitor the VM instances (port 9000)
  monitoring_source_address_prefixes = ["0.0.0.0/0"]

  # Location that will be used to deploy the resource group
  # containing the sidecar resources
  resource_group_location = ""

  # Path to the public key that will be used to SSH into the VMs
  admin_ssh_key = file("/Users/me/.ssh/id_rsa.pub")
}
```
**Note:**

- `name_prefix` is defined automatically. If you wish to define a custom
  `name_prefix`, please keep in mind that its length must be **at most 24
  characters**.

## Upgrade

### Sidecar upgrade

This module supports [1-click upgrade](https://cyral.com/docs/sidecars/manage/upgrade#1-click-upgrade).

To enable the 1-click upgrade feature, leave the variable `sidecar_version` empty and upgrade
the sidecar from Cyral control plane.

If you prefer to block upgrades from the Cyral control plane and use a **static version**, assign
the desired sidecar version to `sidecar_version`. To upgrade your sidecar, update this parameter
with the target version and run `terraform apply`.

Learn more in the [sidecar upgrade procedures](https://cyral.com/docs/sidecars/manage/upgrade) page.

## Advanced

Instructions for advanced deployment configurations are available for the following topics:

* [Bring your own secret](https://github.com/cyralinc/terraform-azure-sidecar-vm/blob/main/docs/byos.md)
* [Customer initialization scripts](https://github.com/cyralinc/terraform-azure-sidecar-vm/blob/main/docs/custom-user-data.md)
* [Memory limits](https://github.com/cyralinc/terraform-azure-sidecar-vm/blob/main/docs/memlim.md)
* [Sidecar certificates](https://github.com/cyralinc/terraform-azure-sidecar-vm/blob/main/docs/certificates.md)
* [Sidecar instance metrics](https://github.com/cyralinc/terraform-azure-sidecar-vm/blob/main/docs/metrics.md)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_secret.self_signed_ca](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.self_signed_tls_cert](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.sidecar_secrets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_lb.lb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) | resource |
| [azurerm_lb_backend_address_pool.lb_backend_address_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_probe.lb_probe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_rule.lb_rule_private_lb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_lb_rule.lb_rule_public_lb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_linux_virtual_machine_scale_set.scale_set](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine_scale_set) | resource |
| [azurerm_log_analytics_workspace.log_analytics_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_autoscale_setting.monitor_autoscale_setting](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting) | resource |
| [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.security_rule_monitoring](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.security_rule_sidecar_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.security_rule_ssh](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_public_ip.public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_resource_group_policy_assignment.user_policies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_role_assignment.role_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_subnet_network_security_group_association.subnet_nsg_association](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_user_assigned_identity.user_assigned_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [tls_private_key.ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.tls](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [tls_self_signed_cert.tls](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_ssh_key"></a> [admin\_ssh\_key](#input\_admin\_ssh\_key) | The public Key which should be used for authentication, which needs to be at least 2048-bit and in ssh-rsa format | `string` | `""` | no |
| <a name="input_auto_scale_default"></a> [auto\_scale\_default](#input\_auto\_scale\_default) | The number of instances that are available for scaling if metrics are not available for evaluation. The default is only used if the current instance count is lower than the default. Valid values are between 0 and 1000 | `number` | `1` | no |
| <a name="input_auto_scale_enabled"></a> [auto\_scale\_enabled](#input\_auto\_scale\_enabled) | Set true to enable the auto scale setting, false to disable. Only for debugging | `bool` | `true` | no |
| <a name="input_auto_scale_max"></a> [auto\_scale\_max](#input\_auto\_scale\_max) | The maximum number of instances for this resource. Valid values are between 0 and 1000 | `number` | `2` | no |
| <a name="input_auto_scale_min"></a> [auto\_scale\_min](#input\_auto\_scale\_min) | The minimum number of instances for this resource. Valid values are between 0 and 1000 | `number` | `1` | no |
| <a name="input_ca_certificate_secret_id"></a> [ca\_certificate\_secret\_id](#input\_ca\_certificate\_secret\_id) | (Optional) Fully qualified Azure Key Vault Secret resource ID that<br/>contains CA certificate to sign sidecar-generated certs. | `string` | `""` | no |
| <a name="input_client_id"></a> [client\_id](#input\_client\_id) | (Optional) The client id assigned to the sidecar. If not provided, must<br/>provide a secret containing the respective client id using `secret_id`." | `string` | `""` | no |
| <a name="input_client_secret"></a> [client\_secret](#input\_client\_secret) | (Optional) The client secret assigned to the sidecar. If not provided, must<br/>provide a secret containing the respective client secret using `secret_id`." | `string` | `""` | no |
| <a name="input_container_registry"></a> [container\_registry](#input\_container\_registry) | Address of the container registry where Cyral images are stored | `string` | `"public.ecr.aws/cyral"` | no |
| <a name="input_control_plane"></a> [control\_plane](#input\_control\_plane) | Address of the control plane - <tenant>.app.cyral.com | `string` | n/a | yes |
| <a name="input_curl_connect_timeout"></a> [curl\_connect\_timeout](#input\_curl\_connect\_timeout) | (Optional) The maximum time in seconds that curl connections are allowed to take. | `number` | `60` | no |
| <a name="input_custom_user_data"></a> [custom\_user\_data](#input\_custom\_user\_data) | Ancillary consumer supplied user-data script. Bash scripts must be added to a map as a value of the key `pre`, `pre_sidecar_start`, `post` denoting execution order with respect to sidecar installation. (Approx Input Size = 19KB) | `map(any)` | <pre>{<br/>  "post": "",<br/>  "pre": "",<br/>  "pre_sidecar_start": ""<br/>}</pre> | no |
| <a name="input_db_source_address_prefixes"></a> [db\_source\_address\_prefixes](#input\_db\_source\_address\_prefixes) | Allowed CIDR blocks or IP addresses for database access to the sidecar. | `set(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_iam_actions_role_permissions"></a> [iam\_actions\_role\_permissions](#input\_iam\_actions\_role\_permissions) | (Optional) List of IAM role actions permissions that will be attached to the sidecar IAM role | `list(string)` | `[]` | no |
| <a name="input_iam_no_actions_role_permissions"></a> [iam\_no\_actions\_role\_permissions](#input\_iam\_no\_actions\_role\_permissions) | (Optional) List of IAM role disallowed actions permissions that will be attached to the sidecar IAM role | `list(string)` | `[]` | no |
| <a name="input_iam_policies"></a> [iam\_policies](#input\_iam\_policies) | (Optional) List of IAM policies that will be attached to the sidecar IAM role | `list(string)` | `[]` | no |
| <a name="input_idp_certificate"></a> [idp\_certificate](#input\_idp\_certificate) | (Optional) The certificate used to verify SAML assertions from the IdP being used with Snowflake. Enter this value as a one-line string with literal new line characters (\n) specifying the line breaks. | `string` | `""` | no |
| <a name="input_idp_sso_login_url"></a> [idp\_sso\_login\_url](#input\_idp\_sso\_login\_url) | (Optional) The IdP SSO URL for the IdP being used with Snowflake. | `string` | `""` | no |
| <a name="input_instance_os_disk_storage_account_type"></a> [instance\_os\_disk\_storage\_account\_type](#input\_instance\_os\_disk\_storage\_account\_type) | The Type of Storage Account which should back this Data Disk | `string` | `"Standard_LRS"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Azure virtual machine scale set instance type for the sidecar instances | `string` | `"standard_ds2_v2"` | no |
| <a name="input_monitoring_source_address_prefixes"></a> [monitoring\_source\_address\_prefixes](#input\_monitoring\_source\_address\_prefixes) | Allowed CIDR blocks or IP addresses for health check and metric requests to the sidecar.<br/>If restricting the access, consider setting to the Virtual Network CIDR or an equivalent<br/>to cover the assigned subnets as the load balancer performs health checks on the VM instances. | `set(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for names of created resources. Maximum length is 24 characters | `string` | `""` | no |
| <a name="input_public_load_balancer"></a> [public\_load\_balancer](#input\_public\_load\_balancer) | Set true to add a public IP to the load balancer | `bool` | `false` | no |
| <a name="input_recycle_health_check_interval_sec"></a> [recycle\_health\_check\_interval\_sec](#input\_recycle\_health\_check\_interval\_sec) | (Optional) The interval (in seconds) in which the sidecar instance checks whether it has been marked or recycling. | `number` | `30` | no |
| <a name="input_repositories_supported"></a> [repositories\_supported](#input\_repositories\_supported) | List of all repositories that will be supported by the sidecar (lower case only) | `list(string)` | <pre>[<br/>  "denodo",<br/>  "dremio",<br/>  "dynamodb",<br/>  "mongodb",<br/>  "mysql",<br/>  "oracle",<br/>  "postgresql",<br/>  "redshift",<br/>  "snowflake",<br/>  "sqlserver",<br/>  "s3"<br/>]</pre> | no |
| <a name="input_resource_group_location"></a> [resource\_group\_location](#input\_resource\_group\_location) | Azure resource group location | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Azure resource group name | `string` | `""` | no |
| <a name="input_secret_id"></a> [secret\_id](#input\_secret\_id) | (Optional) Fully qualified Azure Key Vault Secret resource ID where<br/>`clientId` and `clientSecret` are stored. If not provided, will<br/>automatically create a secret storing the values in variables<br/>`client_id` and `client_secret`. | `string` | `""` | no |
| <a name="input_sidecar_id"></a> [sidecar\_id](#input\_sidecar\_id) | Sidecar identifier | `string` | n/a | yes |
| <a name="input_sidecar_ports"></a> [sidecar\_ports](#input\_sidecar\_ports) | List of ports allowed to connect to the sidecar | `list(number)` | n/a | yes |
| <a name="input_sidecar_private_idp_key"></a> [sidecar\_private\_idp\_key](#input\_sidecar\_private\_idp\_key) | (Optional) The private key used to sign SAML Assertions generated by the sidecar. Enter this value as a one-line string with literal new line characters (<br/>) specifying the line breaks. | `string` | `""` | no |
| <a name="input_sidecar_public_idp_certificate"></a> [sidecar\_public\_idp\_certificate](#input\_sidecar\_public\_idp\_certificate) | (Optional) The public certificate used to verify signatures for SAML Assertions generated by the sidecar. Enter this value as a one-line string with literal new line characters (<br/>) specifying the line breaks. | `string` | `""` | no |
| <a name="input_sidecar_version"></a> [sidecar\_version](#input\_sidecar\_version) | Version of the sidecar | `string` | `""` | no |
| <a name="input_source_image_offer"></a> [source\_image\_offer](#input\_source\_image\_offer) | Specifies the offer of the image used to create the virtual machines | `string` | `"ubuntu-24_04-lts"` | no |
| <a name="input_source_image_publisher"></a> [source\_image\_publisher](#input\_source\_image\_publisher) | Specifies the publisher of the image used to create the virtual machines | `string` | `"Canonical"` | no |
| <a name="input_source_image_sku"></a> [source\_image\_sku](#input\_source\_image\_sku) | Specifies the SKU of the image used to create the virtual machines | `string` | `"server"` | no |
| <a name="input_source_image_version"></a> [source\_image\_version](#input\_source\_image\_version) | Specifies the version of the image used to create the virtual machines | `string` | `"latest"` | no |
| <a name="input_ssh_source_address_prefixes"></a> [ssh\_source\_address\_prefixes](#input\_ssh\_source\_address\_prefixes) | Source address prefixes that will be able to reach the instances using SSH | `set(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnets to add sidecar to (list of string) | `list(string)` | n/a | yes |
| <a name="input_tls_certificate_secret_id"></a> [tls\_certificate\_secret\_id](#input\_tls\_certificate\_secret\_id) | (Optional) Fully qualified Azure Key Vault Secret resource ID that<br/>contains a certificate to terminate TLS connections." | `string` | `""` | no |
| <a name="input_tls_skip_verify"></a> [tls\_skip\_verify](#input\_tls\_skip\_verify) | (Optional) Skip TLS verification for HTTPS communication with the control plane and during sidecar initialization | `bool` | `false` | no |
| <a name="input_vm_username"></a> [vm\_username](#input\_vm\_username) | Virtual machine user name | `string` | `"ubuntu"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ca_certificate_secret_id"></a> [ca\_certificate\_secret\_id](#output\_ca\_certificate\_secret\_id) | ID of the CA certificate secret used sidecar. |
| <a name="output_load_balancer_dns"></a> [load\_balancer\_dns](#output\_load\_balancer\_dns) | Sidecar load balancer DNS endpoint. |
| <a name="output_load_balancer_id"></a> [load\_balancer\_id](#output\_load\_balancer\_id) | ID of the load balancer. |
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | Azure Log Analytics workspace ID. |
| <a name="output_log_analytics_workspace_primary_shared_key"></a> [log\_analytics\_workspace\_primary\_shared\_key](#output\_log\_analytics\_workspace\_primary\_shared\_key) | Azure Log Analytics primary shared key. |
| <a name="output_log_analytics_workspace_secondary_shared_key"></a> [log\_analytics\_workspace\_secondary\_shared\_key](#output\_log\_analytics\_workspace\_secondary\_shared\_key) | Azure Log Analytics secondary shared key. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Azure resource group name that the sidecar belongs to. |
| <a name="output_secret_id"></a> [secret\_id](#output\_secret\_id) | ID of the secret with the credentials used by the sidecar |
| <a name="output_tls_certificate_secret_id"></a> [tls\_certificate\_secret\_id](#output\_tls\_certificate\_secret\_id) | ID of the TLS certificate secret used by the sidecar |
| <a name="output_user_assigned_identity_name"></a> [user\_assigned\_identity\_name](#output\_user\_assigned\_identity\_name) | Name of the User Assigned Identity used by the sidecar |
<!-- END_TF_DOCS -->
