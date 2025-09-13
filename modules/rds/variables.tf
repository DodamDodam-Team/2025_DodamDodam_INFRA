variable "vpc_id" {
  type = string
}

variable "protect_subnet_ids" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

variable "rds_cluster_name" {
  type = string
}

variable "rds_subnet_group_name" {
  type = string
}

variable "rds_cluster_parmeter_group_name" {
  type = string
}

variable "rds_parameter_group_name" {
  type = string
}

variable "rds_cluster_instance_name" {
  type = string
}

variable "rds_cluster_parmeter_group_family" {
  type = string
}

variable "rds_parameter_group_family" {
  type = string
}

variable "rds_cluster_db_name" {
  type = string
}

variable "rds_cluster_cw_logs_exports" {
  type = list(string)
}

variable "rds_cluster_engine" {
  type = string
}

variable "rds_cluster_user_name" {
  type = string
}

variable "rds_cluster_user_password" {
  type = string
}

variable "rds_cluster_port" {
  type = number
}

variable "rds_cluster_instance_count" {
  type = number
}

variable "rds_cluster_instance_class" {
  type = string
}

variable "rds_cluster_instance_engine" {
  type = string
}

variable "rds_security_group_name" {
  type = string
}

variable "rds_ingress_protocol" {
  type = list(string)
}

variable "rds_egress_protocol" {
  type = list(string)
}

variable "rds_ingress_cidr_blocks" {
  type = list(string)
}

variable "rds_egress_cidr_blocks" {
  type = list(string)
}

variable "rds_ingress_ports" {
  type = list(string)
}

variable "rds_egress_ports" {
  type = list(string)
}

variable "rds_proxy_name" {
  type = string
}

variable "rds_proxy_engine" {
  type = string
}

variable "rds_proxy_security_group_name" {
  type = string
}

variable "rds_proxy_ingress_protocol" {
  type = list(string)
}

variable "rds_proxy_egress_protocol" {
  type = list(string)
}

variable "rds_proxy_ingress_cidr_blocks" {
  type = list(string)
}

variable "rds_proxy_egress_cidr_blocks" {
  type = list(string)
}

variable "rds_proxy_ingress_ports" {
  type = list(string)
}

variable "rds_proxy_egress_ports" {
  type = list(string)
}

variable "rds_proxy_role_name" {
  type = string
}

variable "rds_proxy_policy_name" {
  type = string
}

variable "db_proxy_secrets_manager_id" {
  type = string
}

variable "db_proxy_secrets_manager_arn" {
  type = string
}