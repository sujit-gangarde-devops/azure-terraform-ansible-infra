variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vm_count" {
  type = number
}

variable "vm_size" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "ssh_public_key" {
  description = "Contents of the SSH public key (e.g. ~/.ssh/id_rsa.pub)"
  type        = string
}

variable "backend_pool_id" {
  type = string
}

variable "ssh_nat_rule_ids" {
  description = "One LB NAT rule ID per VM, in the same order as the VMs"
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
