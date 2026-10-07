variable "project" {
  description = "Short project name used in resource names"
  type        = string
  default     = "webapp"

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.project))
    error_message = "project must be 3-10 lowercase letters or numbers (Key Vault names are limited to 24 characters)."
  }
}

variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "environment must be dev, uat or prod."
  }
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "owner" {
  description = "Owner tag value"
  type        = string
}

variable "vnet_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "web_subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "db_subnet_cidr" {
  type    = string
  default = "10.10.2.0/24"
}

variable "admin_source_cidrs" {
  description = "Public IPs allowed to SSH (your IP and the Jenkins server IP, as x.x.x.x/32)"
  type        = list(string)
}

variable "vm_count" {
  type    = number
  default = 2

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 5
    error_message = "vm_count must be between 1 and 5."
  }
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key" {
  description = "Contents of your SSH public key"
  type        = string
}

variable "mysql_sku" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "mysql_admin_username" {
  type    = string
  default = "mysqladmin"
}

variable "database_name" {
  type    = string
  default = "appdb"
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}
