variable "admin_ssh_key" {
  description = "The public Key which should be used for authentication, which needs to be at least 2048-bit and in ssh-rsa format"
  type        = string
  default     = ""
  validation {
    condition = (length(var.admin_ssh_key) > 0 && length(var.vm_username) > 0)
    error_message = "`admin_ssh_key` and `vm_username` must be specified."
  }
}

variable "auto_scale_enabled" {
  description = "Set true to enable the auto scale setting, false to disable. Only for debugging"
  type        = bool
  default     = true
}

variable "auto_scale_min" {
  description = "The minimum number of instances for this resource. Valid values are between 0 and 1000"
  type        = number
  default     = 1
}

variable "auto_scale_default" {
  description = "The number of instances that are available for scaling if metrics are not available for evaluation. The default is only used if the current instance count is lower than the default. Valid values are between 0 and 1000"
  type        = number
  default     = 1
}

variable "auto_scale_max" {
  description = "The maximum number of instances for this resource. Valid values are between 0 and 1000"
  type        = number
  default     = 2
}

variable "instance_os_disk_storage_account_type" {
  description = "The Type of Storage Account which should back this Data Disk"
  type        = string
  default     = "Standard_LRS"
}

variable "instance_type" {
  description = "Azure virtual machine scale set instance type for the sidecar instances"
  type        = string
  default     = "standard_ds2_v2"
}

variable "public_load_balancer" {
  description = "Set true to add a public IP to the load balancer"
  type        = bool
  default     = false
}

variable "resource_group_location" {
  description = "Azure resource group location"
  type        = string
}

variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = ""
}

variable "secret_id" {
  description = <<EOT
(Optional) Fully qualified Azure Key Vault Secret resource ID where
`clientId` and `clientSecret` are stored. If not provided, will
automatically create a secret storing the values in variables
`client_id` and `client_secret`.
EOT
  type        = string
  default     = ""
  validation {
    condition = can(regex(
      "^https://[a-zA-Z0-9-]+\\.vault\\.azure\\.net/secrets/[a-zA-Z0-9-]+/[a-zA-Z0-9]+$",
      var.secret_id
    )) || var.secret_id == ""
    error_message = <<EOT
The secret_id must be a fully qualified Azure Key Vault Secret ID in the format:
  https://{vault-name}.vault.azure.net/secrets/{secret-name}/{secret-version}
EOT
  }
}

variable "source_image_offer" {
  description = "Specifies the offer of the image used to create the virtual machines"
  type        = string
  default     = "ubuntu-24_04-lts"
}

variable "source_image_publisher" {
  description = "Specifies the publisher of the image used to create the virtual machines"
  type        = string
  default     = "Canonical"
}

variable "source_image_sku" {
  description = "Specifies the SKU of the image used to create the virtual machines"
  type        = string
  default     = "server"
}

variable "source_image_version" {
  description = "Specifies the version of the image used to create the virtual machines"
  type        = string
  default     = "latest"
}

variable "subnets" {
  description = "Subnets to add sidecar to (list of string)"
  type        = list(string)
}

variable "vm_username" {
  description = "Virtual machine user name"
  type        = string
  default     = "ubuntu"
}
