module "vpc" {
  source = "./modules/vpc"

  for_each = local.vpcs

  az_override      = local.az_override
  azs              = local.azs
  enable_igw       = each.value.enable_igw
  enable_natgw     = each.value.enable_natgw

  default_rtb_tags = each.value.default_rtb_tags
  vpc_name         = each.key
  vpc_cidr         = each.value.vpc_cidr
  vpc_tags         = each.value.vpc_tags
  types            = each.value.types
}

module "ec2" {
  depends_on = [ module.vpc, module.secrets_manager ]

  source = "./modules/ec2"

  for_each = local.ec2s

  vpc_id                = module.vpc[each.value.vpc_name].vpc_id
  subnet_id             = module.vpc[each.value.vpc_name].subnet_ids[each.value.subnet_name]
  name                  = each.key

  instance_type         = each.value.instance_type
  userdata              = each.value.userdata
  instance_tags         = each.value.instance_tags

  enable_public_ip      = each.value.enable_public_ip
  enable_eip            = each.value.enable_eip
  eip_tags              = each.value.eip_tags

  root_block_device     = each.value.root_block_device

  security_group_name   = each.value.security_group_name
  security_group_tags   = each.value.security_group_tags
  ingress_ports         = each.value.ingress_ports
  egress_ports          = each.value.egress_ports

  enable_create_keypair = each.value.enable_create_keypair
  keypair_name          = each.value.keypair_name
  keypair_file_path     = each.value.keypair_file_path

  enable_create_iam_role = each.value.enable_create_iam_role
  iam_role_name         = each.value.iam_role_name
  instance_profile_name = each.value.instance_profile_name
  iam_policies          = each.value.iam_policies
}

module "alb" {
  depends_on = [ module.vpc ]
  
  source = "./modules/alb"

  for_each = local.albs

  vpc_id                      = module.vpc[each.value.vpc_name].vpc_id
  subnet_ids                  = each.value.internal ? module.vpc[each.value.vpc_name].private_subnet_ids : module.vpc[each.value.vpc_name].public_subnet_ids

  name                        = each.key
  alb_tags                    = each.value.alb_tags
  internal                    = each.value.internal
  port                        = each.value.port
  protocol                    = each.value.protocol
  target_groups               = each.value.target_groups
  listener_target_groups      = each.value.listener_target_groups

  security_group_name         = each.value.security_group_name
  security_group_tags         = each.value.security_group_tags
  ingress_ports               = each.value.ingress_ports
  egress_ports                = each.value.egress_ports

  enable_attach_target        = each.value.enable_attach_target
  targets                     = each.value.targets
  ec2_info                    = each.value.enable_attach_target ? {for t in each.value.targets : t.target_name => module.ec2[t.target_name].ec2_instance_id} : {}
}

module "launch_template" {
  depends_on = [ module.vpc ]
  
  source = "./modules/launch_template"

  for_each = local.launch_templates

  vpc_id                 = module.vpc[each.value.vpc_name].vpc_id

  name                   = each.key
  tags                   = each.value.tags
  enable_monitoring      = each.value.enable_monitoring
  instance_type          = each.value.instance_type
  userdata               = each.value.userdata
  block_device_mappings  = each.value.block_device_mappings
  tag_specifications     = each.value.tag_specifications

  security_group_name    = each.value.security_group_name
  ingress_ports          = each.value.ingress_ports
  egress_ports           = each.value.egress_ports

  enable_create_keypair  = each.value.enable_create_keypair
  keypair_name           = each.value.keypair_name
  keypair_file_path      = each.value.keypair_file_path

  enable_create_iam_role = each.value.enable_create_iam_role
  iam_role_name          = each.value.iam_role_name
  instance_profile_name  = each.value.instance_profile_name
  iam_policies           = each.value.iam_policies
}

module "auto_scaling_group" {
  depends_on = [ module.vpc, module.launch_template, module.alb ]

  source = "./modules/auto_scaling_group"

  for_each = local.asgs
  
  subnet_ids                  = each.value.internal ? module.vpc[each.value.vpc_name].private_subnet_ids : module.vpc[each.value.vpc_name].public_subnet_ids

  name                        = each.key
  tags                        = each.value.tags
  launch_template_id          = module.launch_template[each.value.launch_template_name].launch_template_id
  tags_no_launch              = each.value.tags_no_launch
  desired_capacity            = each.value.desired_capacity
  min_size                    = each.value.min_size
  max_size                    = each.value.max_size
  health_check_type           = each.value.health_check_type
  health_check_grace_period   = each.value.health_check_grace_period
  timeout_delete_time         = each.value.timeout_delete_time
  enable_scaling_policy       = each.value.enable_scaling_policy
  scaling_policys             = each.value.scaling_policys
  enable_attach_elb           = each.value.enable_attach_elb
  elb_arn_suffix              = module.alb[each.value.elb_name].alb_arn_suffix
  elb_target_group_arn        = module.alb[each.value.elb_name].alb_target_group_arns[each.value.elb_target_group_name]
  elb_target_group_arn_suffix = module.alb[each.value.elb_name].alb_target_group_arn_suffixs[each.value.elb_target_group_name]
}

module "ecr" {
  source = "./modules/ecr"

  for_each = local.ecrs

  name                     = each.key
  tags                     = each.value.tags
  image_tag_mutability     = each.value.image_tag_mutability
  force_delete             = each.value.force_delete
  scan_images_on_push      = each.value.scan_images_on_push

  encryption_configuration = each.value.enable_kms ? {
    encryption_type = each.value.encryption_type
    kms_key = null
  } : null
  image_tag_mutability_exclusion_filter = each.value.enable_image_tag_exclusion_filter ? each.value.image_tag_exclusion_filter : []
}

module "elaticache" {
  depends_on = [ module.vpc ]
  
  source = "./modules/elaticache"

  for_each = local.elaticaches

  vpc_id                        = module.vpc[each.value.vpc_name].vpc_id
  protect_subnet_ids            = module.vpc[each.value.vpc_name].protect_subnet_ids
  name                          = each.key

  node_type                     = each.value.node_type
  engine                        = each.value.engine
  engine_version                = each.value.engine_version
  port                          = each.value.port
  num_node_groups               = each.value.num_node_groups
  replicas_per_node_group       = each.value.replicas_per_node_group
  automatic_failover_enabled    = each.value.automatic_failover_enabled
  multi_az_enabled              = each.value.multi_az_enabled
  apply_immediately             = each.value.apply_immediately
  at_rest_encryption_enabled    = each.value.at_rest_encryption_enabled
  transit_encryption_enabled    = each.value.transit_encryption_enabled
  transit_encryption_mode       = each.value.transit_encryption_mode

  subnet_group_name             = each.value.subnet_group_name

  parameter_group_name          = each.value.parameter_group_name
  parameter_group_family        = each.value.parameter_group_family
  parameters                    = each.value.parameters

  security_group_name           = each.value.security_group_name
  ingress_ports                 = each.value.ingress_ports
  egress_ports                  = each.value.egress_ports
}

module "rds" {
  depends_on = [ module.vpc ]

  source = "./modules/rds"

  for_each = local.rdss

  vpc_id                         = module.vpc[each.value.vpc_name].vpc_id
  protect_subnet_ids             = module.vpc[each.value.vpc_name].protect_subnet_ids
  availability_zones             = local.azs
  name                           = each.key
  rds_cluster_tags               = each.value.rds_cluster_tags
  instance_name                  = each.value.instance_name
  instance_tags                  = each.value.instance_tags

  db_name                        = each.value.db_name
  cw_logs_exports                = each.value.cw_logs_exports
  engine                         = each.value.engine
  user_name                      = each.value.user_name
  user_password                  = each.value.user_password
  port                           = each.value.port
  backtrack_window               = each.value.backtrack_window
  skip_final_snapshot            = each.value.skip_final_snapshot
  storage_encrypted              = each.value.storage_encrypted
  performance_insights_enabled   = each.value.performance_insights_enabled

  instance_count                 = each.value.instance_count
  instance_class                 = each.value.instance_class
  instance_engine                = each.value.instance_engine

  subnet_group_name              = each.value.subnet_group_name
  subnet_group_tags              = each.value.subnet_group_tags

  cluster_parameter_group_name   = each.value.cluster_parameter_group_name
  cluster_parameter_group_family = each.value.cluster_parameter_group_family
  parameters                     = each.value.parameters
  cluster_parameter_group_tags   = each.value.cluster_parameter_group_tags

  parameter_group_name           = each.value.parameter_group_name
  parameter_group_family         = each.value.parameter_group_family
  parameter_group_tags           = each.value.parameter_group_tags

  security_group_name            = each.value.security_group_name
  security_group_tags            = each.value.security_group_tags
  ingress_ports                  = each.value.ingress_ports
  egress_ports                   = each.value.egress_ports
}

module "secrets_manager" {
  depends_on = [ module.rds, module.elaticache ]
  source = "./modules/secrets-manager"

  for_each = local.secrets_managers

  name = each.value.name

  secret_values = (
    each.value.enable_values ? {
      RDS_DB_USER     = module.rds[each.value.rds_name].rds_user_name
      RDS_DB_PASSWORD = module.rds[each.value.rds_name].rds_user_password
      RDS_DB_ADDRESS  = module.rds[each.value.rds_name].rds_address
      RDS_DB_PORT     = module.rds[each.value.rds_name].rds_port
      RDS_DB_NAME     = module.rds[each.value.rds_name].rds_db_name
      REDIS_ENDPOINT  = module.elaticache[each.value.elaticache_name].elaticache_address
      REDIS_PORT      = module.elaticache[each.value.elaticache_name].elaticache_port
    }
    : {}
  )
}

module "iam" {
  source = "./modules/iam"

  for_each = local.iams

  user_name             = each.key
  user_tags             = each.value.user_tags
  service_name          = each.value.service_name
  statements            = each.value.statements
  enable_inline_policy  = each.value.enable_inline_policy
  inline_policy_name    = each.value.inline_policy_name
  enable_custom_policy  = each.value.enable_custom_policy
  policy_name           = each.value.policy_name
  policy_tags           = each.value.policy_tags
  enable_managed_policy = each.value.enable_managed_policy
  managed_policy_arns   = each.value.managed_policy_arns
}