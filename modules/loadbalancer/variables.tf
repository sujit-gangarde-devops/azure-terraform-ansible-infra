variable "name_prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vm_count" {
  description = "Number of backend VMs; one SSH NAT rule is created per VM"
  type        = number
}

variable "ssh_nat_base_port" {
  description = "VM number n is reachable for SSH on <lb-ip>:<base + n>"
  type        = number
  default     = 50000
}

variable "tags" {
  type    = map(string)
  default = {}
}
