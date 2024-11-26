variable "client_id" {
  description = "(Optional) The client id assigned to the sidecar. If not provided, must provide a secret containing the respective client id using `secret_name`."
  type        = string
  default     = ""
  validation {
    condition = (
      (length(var.client_id) > 0 && length(var.secret_name) > 0) ||
      (length(var.client_id) == 0 && length(var.secret_name) > 0) ||
      (length(var.client_id) > 0 && length(var.secret_name) == 0)
    )
    error_message = "Must be provided if `secret_name` is empty and must be empty if `secret_name` is provided."
  }
}

variable "client_secret" {
  description = "(Optional) The client secret assigned to the sidecar. If not provided, must provide a secret containing the respective client secret using `secret_name`."
  type        = string
  sensitive   = true
  default     = ""
  validation {
    condition = (
      (length(var.client_secret) > 0 && length(var.secret_name) > 0) ||
      (length(var.client_secret) == 0 && length(var.secret_name) > 0) ||
      (length(var.client_secret) > 0 && length(var.secret_name) == 0)
    )
    error_message = "Must be provided if `secret_name` is empty and must be empty if `secret_name` is provided."
  }
}

variable "container_registry" {
  description = "Address of the container registry where Cyral images are stored"
  type        = string
}

variable "control_plane" {
  description = "Address of the control plane - <tenant>.app.cyral.com"
  type        = string
}

variable "curl_connect_timeout" {
  description = "(Optional) The maximum time in seconds that curl connections are allowed to take."
  type        = number
  default     = 60
}

variable "custom_user_data" {
  description = "Ancillary consumer supplied user-data script. Bash scripts must be added to a map as a value of the key `pre`, `pre_sidecar_start`, `post` denoting execution order with respect to sidecar installation. (Approx Input Size = 19KB)"
  type        = map(any)
  default     = { "pre" = "", "pre_sidecar_start" = "", "post" = "" }
}

variable "iam_policies" {
  description = "(Optional) List of IAM policies that will be attached to the sidecar IAM role"
  type        = list(string)
  default     = []
}

variable "iam_actions_role_permissions" {
  description = "(Optional) List of IAM role actions permissions that will be attached to the sidecar IAM role"
  type        = list(string)
  default     = []
}

variable "iam_no_actions_role_permissions" {
  description = "(Optional) List of IAM role disallowed actions permissions that will be attached to the sidecar IAM role"
  type        = list(string)
  default     = []
}

variable "monitoring_source_address_prefixes" {
  description = <<EOF
Allowed CIDR blocks or IP addresses for health check and metric requests to the sidecar.
If restricting the access, consider setting to the Virtual Network CIDR or an equivalent
to cover the assigned subnets as the load balancer performs health checks on the VM instances.
EOF
  default     = ["0.0.0.0/0"]
  type        = set(string)
}

variable "name_prefix" {
  description = "Prefix for names of created resources. Maximum length is 24 characters"
  type        = string
  default     = ""
}

variable "sidecar_id" {
  description = "Sidecar identifier"
  type        = string
}

variable "sidecar_ports" {
  description = "List of ports allowed to connect to the sidecar"
  type        = list(number)
}

variable "sidecar_version" {
  description = "Version of the sidecar"
  type        = string
  default     = ""
}

variable "repositories_supported" {
  description = "List of all repositories that will be supported by the sidecar (lower case only)"
  type        = list(string)
  default     = ["denodo", "dremio", "dynamodb", "mongodb", "mysql", "oracle", "postgresql", "redshift", "snowflake", "sqlserver", "s3"]
}

variable "recycle_health_check_interval_sec" {
  description = "(Optional) The interval (in seconds) in which the sidecar instance checks whether it has been marked or recycling."
  type        = number
  default     = 30
}

variable "ssh_source_address_prefixes" {
  description = "Source address prefixes that will be able to reach the instances using SSH"
  default     = ["0.0.0.0/0"]
  type        = set(string)
}

variable "tls_skip_verify" {
  description = "(Optional) Skip TLS verification for HTTPS communication with the control plane and during sidecar initialization"
  type        = bool
  default     = false
}
