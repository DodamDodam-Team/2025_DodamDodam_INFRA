variable "parameter" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_a_id" {
  type = string
}

variable "bastion_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "security_group_name" {
  type = string
}

variable "ingress_protocol" {
  type = list(string)
}

variable "egress_protocol" {
  type = list(string)
}

variable "ingress_cidr_blocks" {
  type = list(string)
}

variable "egress_cidr_blocks" {
  type = list(string)
}

variable "ingress_ports" {
  type = list(string)
}

variable "egress_ports" {
  type = list(string)
}