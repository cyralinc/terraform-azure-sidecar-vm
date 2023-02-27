variable "container_registry" {
  description = "Address of the container registry where Cyral images are stored"
  type        = string
}

variable "container_registry_username" {
  description = "Username provided by Cyral for authenticating on Cyral's container registry"
  type        = string
  default     = ""
}

variable "container_registry_key" {
  description = "Key provided by Cyral for authenticating on Cyral's container registry"
  type        = string
  default     = ""
  sensitive   = true
}

variable "client_id" {
  description = "The client id assigned to the sidecar"
  type        = string
}

variable "client_secret" {
  description = "The client secret assigned to the sidecar"
  type        = string
  sensitive   = true
}

variable "control_plane" {
  description = "Address of the control plane - <tenant>.app.cyral.com"
  type        = string
}

variable "external_tls_type" {
  description = "TLS mode for the control plane - tls, tls-skip-verify, no-tls"
  type        = string
  default     = "tls"
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

variable "secret_manager_type" {
  description = "Define secret manager type for sidecar_client_id and sidecar_client_secret"
  type        = string
  default     = "azure-key-vault"
}

variable "metrics_integration" {
  description = "Metrics destination"
  type        = string
  default     = ""
}

variable "metrics_port" {
  description = "Port which will expose sidecar metrics"
  default     = 8080
  type        = number
}

variable "metrics_source_address_prefixes" {
  description = "Source address prefixes that will be able to reach the metrics port"
  default     = {}
  type        = set(string)
}

variable "log_integration" {
  description = "Logs destination"
  type        = string
  default     = "azure-log-analytics"
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
}

variable "repositories_supported" {
  description = "List of all repositories that will be supported by the sidecar (lower case only)"
  type        = list(string)
  default     = ["denodo", "dremio", "dynamodb", "mongodb", "mysql", "oracle", "postgresql", "redshift", "snowflake", "sqlserver", "s3"]
}

variable "custom_user_data" {
  description = "Ancillary consumer supplied user-data script. Bash scripts must be added to a map as a value of the key `pre` and/or `post` denoting execution order with respect to sidecar installation. (Approx Input Size = 19KB)"
  type        = map(any)
  default     = { "pre" = "", "post" = "" }
}
