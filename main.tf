module "vpc" {
  source = "./modules/vpc"

  vpc_name                       = local.vpc.vpc.name
  vpc_cidr                       = local.vpc.vpc.cidr

  public_subnet_names            = local.vpc.public.subnet.names
  public_subnet_cidrs            = local.vpc.public.subnet.cidrs
  public_route_table_name        = local.vpc.public.route_table.name
  
  private_subnet_names           = local.vpc.private.subnet.names
  private_subnet_cidrs           = local.vpc.private.subnet.cidrs
  private_route_table_names      = local.vpc.private.route_table.names

  protect_subnet_names           = local.vpc.protect.subnet.names
  protect_subnet_cidrs           = local.vpc.protect.subnet.cidrs
  protect_route_table_name       = local.vpc.protect.route_table.name
  
  internet_gateway_name          = local.vpc.internet_gateway_name
  nat_gateway_names              = local.vpc.nat_gateway_names
}

module "ec2" {
  source = "./modules/ec2"
  for_each = local.ec2

  parameter                      = local.parameter

  vpc_id                         = module.vpc.vpc_id
  public_a_id                    = module.vpc.public_subnet_ids[0]
  
  bastion_name                   = each.value.name
  instance_type                  = each.value.instance_type
  
  security_group_name            = each.value.security_group_name
  ingress_protocol               = each.value.ingress_protocol
  egress_protocol                = each.value.egress_protocol
  ingress_cidr_blocks            = each.value.ingress_cidr_blocks
  egress_cidr_blocks             = each.value.egress_cidr_blocks
  ingress_ports                  = each.value.ingress_ports
  egress_ports                   = each.value.egress_ports

  depends_on = [ module.vpc ]
}

module "rds" {
  source = "./modules/rds"

  vpc_id                            = module.vpc.vpc_id
  protect_subnet_ids                = module.vpc.protect_subnet_ids
  azs                               = local.azs

  rds_cluster_name                  = local.rds.rds_cluster_name
  rds_cluster_db_name               = local.rds.rds_cluster_db_name
  rds_cluster_cw_logs_exports       = local.rds.rds_cluster_cw_logs_exports
  rds_cluster_engine                = local.rds.rds_cluster_engine
  rds_cluster_user_name             = local.rds.rds_cluster_user_name
  rds_cluster_user_password         = local.rds.rds_cluster_user_password
  rds_cluster_port                  = local.rds.rds_cluster_port
  
  rds_cluster_instance_name         = local.rds.rds_cluster_instance_name
  rds_cluster_instance_count        = local.rds.rds_cluster_instance_count
  rds_cluster_instance_class        = local.rds.rds_cluster_instance_class
  rds_cluster_instance_engine       = local.rds.rds_cluster_instance_engine
  
  rds_subnet_group_name             = local.rds.rds_subnet_group_name
  
  rds_cluster_parmeter_group_name   = local.rds.rds_cluster_parmeter_group_name
  rds_cluster_parmeter_group_family = local.rds.rds_cluster_parmeter_group_family
  
  rds_parameter_group_name          = local.rds.rds_parameter_group_name
  rds_parameter_group_family        = local.rds.rds_parameter_group_family

  rds_security_group_name           = local.rds.security_group_name
  rds_ingress_protocol              = local.rds.ingress_protocol
  rds_egress_protocol               = local.rds.egress_protocol
  rds_ingress_cidr_blocks           = local.rds.ingress_cidr_blocks
  rds_egress_cidr_blocks            = local.rds.egress_cidr_blocks
  rds_ingress_ports                 = local.rds.ingress_ports
  rds_egress_ports                  = local.rds.egress_ports

  rds_proxy_name                    = local.rds_proxy.name
  rds_proxy_engine                  = local.rds_proxy.engine

  rds_proxy_role_name               = local.rds_proxy.role_name
  rds_proxy_policy_name             = local.rds_proxy.policy_name

  rds_proxy_security_group_name     = local.rds_proxy.security_group_name
  rds_proxy_ingress_protocol        = local.rds_proxy.ingress_protocol
  rds_proxy_egress_protocol         = local.rds_proxy.egress_protocol
  rds_proxy_ingress_cidr_blocks     = local.rds_proxy.ingress_cidr_blocks
  rds_proxy_egress_cidr_blocks      = local.rds_proxy.egress_cidr_blocks
  rds_proxy_ingress_ports           = local.rds_proxy.ingress_ports
  rds_proxy_egress_ports            = local.rds_proxy.egress_ports

  db_proxy_secrets_manager_id       = module.secrets_manager.db_proxy_secrets_manager_id
  db_proxy_secrets_manager_arn      = module.secrets_manager.db_proxy_secrets_manager_arn

  depends_on = [ module.vpc, module.secrets_manager ]
}

module "secrets_manager" {
  source = "./modules/secrets-manager"

  secrets_manager_name = local.secrets_manager.rds_proxy.name
}

module "ecr" {
  source = "./modules/ecr"

  ecr_name = local.ecr.name
}

module "iam" {
  source = "./modules/iam"
  
  github_iam_user_name = local.iam.github.name
  ecr_name             = module.ecr.aws_ecr_repository_name

  depends_on = [ module.ecr ]
}