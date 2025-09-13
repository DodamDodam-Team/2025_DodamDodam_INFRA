variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_names" {
  type = list(string)
}

variable "private_subnet_names" {
  type = list(string)
}

variable "protect_subnet_names" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "protect_subnet_cidrs" {
  type = list(string)
}

variable "public_route_table_name" {
  type = string
}

variable "private_route_table_names" {
  type = list(string)
}

variable "protect_route_table_name" {
  type = string
}

variable "internet_gateway_name" {
  type = string
}

variable "nat_gateway_names" {
  type = list(string)
}