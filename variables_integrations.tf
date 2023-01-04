# ################################
# #           Datadog
# ################################

variable "dd_api_key" {
  description = "API key to connect to DataDog."
  type        = string
  default     = ""
}

# ################################
# #             ELK
# ################################

variable "elk_address" {
  description = "Address to ship logs to ELK."
  type        = string
  default     = ""
}

variable "elk_username" {
  description = "(Optional) Username to use to ship logs to ELK."
  type        = string
  default     = ""
}

variable "elk_password" {
  description = "(Optional) Password to use to ship logs to ELK."
  type        = string
  default     = ""
  sensitive   = true
}

# ################################
# #           Splunk
# ################################

variable "splunk_index" {
  description = "Splunk index."
  type        = string
  default     = ""
}

variable "splunk_host" {
  description = "Splunk host."
  type        = string
  default     = ""
}

variable "splunk_port" {
  description = "Splunk port."
  type        = number
  default     = 0
}

variable "splunk_tls" {
  description = "Splunk TLS."
  type        = bool
  default     = false
}

variable "splunk_token" {
  description = "Splunk token."
  type        = string
  default     = ""
  sensitive   = true
}

# ################################
# #           Sumologic
# ################################

variable "sumologic_host" {
  description = "Sumologic host."
  type        = string
  default     = ""
}

variable "sumologic_uri" {
  description = "Sumologic uri."
  type        = string
  default     = ""
}

################################
#       HashiCorp Vault
################################

variable "hc_vault_integration_id" {
  description = "HashiCorp Vault integration ID."
  type        = string
  default     = ""
}
