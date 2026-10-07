variable "name" {
  description = "Key Vault name: 3-24 characters, globally unique"
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}

variable "reader_object_ids" {
  description = "Object IDs (e.g. VM managed identities) allowed to read secrets"
  type        = list(string)
  default     = []
}

variable "purge_protection_enabled" {
  description = "Keep false for labs so the vault can be destroyed; set true in production"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
