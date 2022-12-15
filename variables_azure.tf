variable "username_vm" {
  description = "Virtual machine user name"
  type        = string
  default     = "ubuntu"
}

variable "resource_group_name" {
  description = "Azure resource group name"
  default     = ""
}

variable "resource_group_location" {
  description = "Azure resource group location"
}

variable "auto_scale_count" {
  description = "Set to 1 to enable the auto scale setting, 0 to disable. Only for debugging."
  type        = number
  default     = 0
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
  description = "The maximum number of instances for this resource. Valid values are between 0 and 1000."
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "Azure virtual machine scale set instance type for the sidecar instances"
  type        = string
  default     = "Standard_F2"
}

variable "source_image_publisher" {
  description = "Specifies the publisher of the image used to create the virtual machines."
  type        = string
  default     = "Canonical"
}

variable "source_image_offer" {
  description = "Specifies the offer of the image used to create the virtual machines."
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "source_image_sku" {
  description = "Specifies the SKU of the image used to create the virtual machines."
  type        = string
  default     = "22_04-lts"
}

variable "source_image_version" {
  description = "Specifies the version of the image used to create the virtual machines."
  type        = string
  default     = "latest"
}

variable "instance_os_disk_storage_account_type" {
  description = "The Type of Storage Account which should back this Data Disk."
  type        = string
  default     = "Standard_LRS"
}

variable "load_balancer_tls_ports" {
  description = <<EOF
List of ports that will have TLS terminated at load balancer level
(snowflake support, for example). If assigned, 'load_balancer_certificate_arn' 
must also be provided. This parameter must be a subset of 'sidecar_ports'.
EOF
  type        = list(number)
  default     = []
}

variable "secrets_location" {
  description = "Location in AWS Secrets Manager to store client_id, client_secret and container_registry_key"
  type        = string
}

variable "admin_public_key" {
  description = "The Public Key which should be used for authentication, which needs to be at least 2048-bit and in ssh-rsa format."
  type        = string
}

variable "public_load_balance" {
  description = "Define if load balancer public IP should be created if the sidecar is actually public."
  type = bool
  default = true
}

# variable "cloudwatch_logs_retention" {
#   description = "Cloudwatch logs retention in days"
#   type        = number
#   default     = 14
#   #  validation {
#   #    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_logs_retention)
#   #    error_message = "Valid values are: [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653]."
#   #  }
# }
