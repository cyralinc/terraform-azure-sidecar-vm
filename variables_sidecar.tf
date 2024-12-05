variable "ca_certificate_secret_id" {
  description = <<EOT
(Optional) Fully qualified Azure Key Vault Secret resource ID that
contains CA certificate to sign sidecar-generated certs.
EOT
  type        = string
  default     = ""
  validation {
    condition = can(regex(
      "^https://[a-zA-Z0-9-]+\\.vault\\.azure\\.net/secrets/[a-zA-Z0-9-]+/[a-zA-Z0-9]+$",
      var.ca_certificate_secret_id
    )) || var.ca_certificate_secret_id == ""
    error_message = <<EOT
The secret_id must be a fully qualified Azure Key Vault Secret ID in the format:
  https://{vault-name}.vault.azure.net/secrets/{secret-name}/{secret-version}
EOT
  }
}

variable "client_id" {
  description = <<EOT
(Optional) The client id assigned to the sidecar. If not provided, must
provide a secret containing the respective client id using `secret_id`."
EOT
  type        = string
  default     = ""
  validation {
    condition = (
      (length(var.client_id) > 0 && length(var.secret_id) > 0) ||
      (length(var.client_id) == 0 && length(var.secret_id) > 0) ||
      (length(var.client_id) > 0 && length(var.secret_id) == 0)
    )
    error_message = "Must be provided if `secret_id` is empty and must be empty if `secret_id` is provided."
  }
}

variable "client_secret" {
  description = <<EOT
(Optional) The client secret assigned to the sidecar. If not provided, must
provide a secret containing the respective client secret using `secret_id`."
EOT
  type        = string
  sensitive   = true
  default     = ""
  validation {
    condition = (
      (length(var.client_secret) > 0 && length(var.secret_id) > 0) ||
      (length(var.client_secret) == 0 && length(var.secret_id) > 0) ||
      (length(var.client_secret) > 0 && length(var.secret_id) == 0)
    )
    error_message = "Must be provided if `secret_id` is empty and must be empty if `secret_id` is provided."
  }
}

variable "container_registry" {
  description = "Address of the container registry where Cyral images are stored"
  type        = string
  default     = "public.ecr.aws/cyral"
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

variable "db_source_address_prefixes" {
  description = "Allowed CIDR blocks or IP addresses for database access to the sidecar."
  default     = ["0.0.0.0/0"]
  type        = set(string)
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
  description = <<EOT
Allowed CIDR blocks or IP addresses for health check and metric requests to the sidecar.
If restricting the access, consider setting to the Virtual Network CIDR or an equivalent
to cover the assigned subnets as the load balancer performs health checks on the VM instances.
EOT
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

variable "tls_certificate_secret_id" {
  description = <<EOT
(Optional) Fully qualified Azure Key Vault Secret resource ID that
contains a certificate to terminate TLS connections."
EOT
  type        = string
  default     = ""
  validation {
    condition = can(regex(
      "^https://[a-zA-Z0-9-]+\\.vault\\.azure\\.net/secrets/[a-zA-Z0-9-]+/[a-zA-Z0-9]+$",
      var.tls_certificate_secret_id
    )) || var.tls_certificate_secret_id == ""
    error_message = <<EOT
The secret_id must be a fully qualified Azure Key Vault Secret ID in the format:
  https://{vault-name}.vault.azure.net/secrets/{secret-name}/{secret-version}
EOT
  }
}

variable "tls_skip_verify" {
  description = "(Optional) Skip TLS verification for HTTPS communication with the control plane and during sidecar initialization"
  type        = bool
  default     = false
}
