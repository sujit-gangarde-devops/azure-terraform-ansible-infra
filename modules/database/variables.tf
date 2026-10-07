variable "name_prefix" {
  type = string
}

variable "name_suffix" {
  description = "Random suffix; MySQL server names must be globally unique"
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "delegated_subnet_id" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "admin_username" {
  type = string
}

variable "database_name" {
  type = string
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
