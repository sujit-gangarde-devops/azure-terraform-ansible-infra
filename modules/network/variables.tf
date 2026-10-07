variable "name_prefix" {
  description = "Prefix used in resource names, e.g. webapp-dev"
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_cidr" {
  type = string
}

variable "web_subnet_cidr" {
  type = string
}

variable "db_subnet_cidr" {
  type = string
}

variable "admin_source_cidrs" {
  description = "Public IP ranges allowed to SSH into the web VMs (your IP, Jenkins server IP)"
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
