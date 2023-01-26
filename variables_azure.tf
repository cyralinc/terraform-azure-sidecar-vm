variable "vm_username" {
  description = "Virtual machine user name"
  type        = string
  default     = "ubuntu"
}

variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = ""
}

variable "resource_group_location" {
  description = "Azure resource group location"
  type        = string
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

variable "instance_type" {
  description = "Azure virtual machine scale set instance type for the sidecar instances"
  type        = string
  default     = "Standard_F2"
}

variable "source_image_publisher" {
  description = "Specifies the publisher of the image used to create the virtual machines"
  type        = string
  default     = "Canonical"
}

variable "source_image_offer" {
  description = "Specifies the offer of the image used to create the virtual machines"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "source_image_sku" {
  description = "Specifies the SKU of the image used to create the virtual machines"
  type        = string
  default     = "22_04-lts"
}

variable "source_image_version" {
  description = "Specifies the version of the image used to create the virtual machines"
  type        = string
  default     = "latest"
}

variable "instance_os_disk_storage_account_type" {
  description = "The Type of Storage Account which should back this Data Disk"
  type        = string
  default     = "Standard_LRS"
}

variable "key_vault_name" {
  description = "Location in Azure Key Vault to store secrets"
  type        = string
  default     = ""
}

variable "secret_name" {
  description = "Location in Azure Key Vault to store client_id, client_secret and container_registry_key"
  type        = string
  default     = ""
}

variable "admin_public_key" {
  description = "The Public Key which should be used for authentication, which needs to be at least 2048-bit and in ssh-rsa format"
  type        = string
}

variable "public_load_balancer" {
  description = "Set true to add a public IP to the load balancer"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "Subnets to add sidecar to (list of string)"
  type        = list(string)
}
