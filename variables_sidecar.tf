variable "container_registry" {
  description = "Address of the container registry where Cyral images are stored"
  type        = string
}

variable "container_registry_username" {
  description = "Username provided by Cyral for authenticating on Cyral's container registry"
  type        = string
  default     = ""
}

variable "client_id" {
  description = "The client id assigned to the sidecar"
  type        = string
}

variable "client_secret" {
  description = "The client secret assigned to the sidecar"
  type        = string
  # Only compatible with Terraform >=0.14
  #sensitive   = true
}

variable "container_registry_key" {
  description = "Key provided by Cyral for authenticating on Cyral's container registry"
  type        = string
  default     = ""
  # Only compatible with Terraform >=0.14
  #sensitive   = true
}

variable "name_prefix" {
  description = "Prefix for names of created resources in AWS. Maximum length is 24 characters."
  type        = string
  default     = ""
}

variable "sidecar_id" {
  description = "Sidecar identifier"
  type        = string
}

