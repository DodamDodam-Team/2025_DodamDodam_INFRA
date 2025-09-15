locals {
  parameter = "dodam"

  az = ["a", "c"]

  azs = compact([
    for az in data.aws_availability_zones.az.names :
    az if contains(local.az, substr(az, -1, 1))
  ])

  vpc = {

    vpc = {
      name                              = "${local.parameter}-vpc"
      cidr                              = "10.0.0.0/16"
    }

    public = {
      subnet = {
        names                           = [for az in local.az : "${local.parameter}-public-${az}"]
        cidrs                           = ["10.0.0.0/24", "10.0.1.0/24"]
      }

      route_table = {
        name                            = "${local.parameter}-public-rtb"
      }
    }


    private = {
      subnet = {
        names                           = [for az in local.az : "${local.parameter}-private-${az}"]
        cidrs                           = ["10.0.2.0/24", "10.0.3.0/24"]
      }

      route_table = {
        names                           = [for az in local.az : "${local.parameter}-private-${az}-rtb"]
      }
    }

    protect = {
      subnet = {
        names                           = [for az in local.az : "${local.parameter}-protect-${az}"]
        cidrs                           = ["10.0.4.0/24", "10.0.5.0/24"]
      }
      
      route_table = {
        name                            = "${local.parameter}-protect-rtb"
      }
    }
    
    internet_gateway_name               = "${local.parameter}-igw"
    nat_gateway_names                   = [for az in local.azs : "${local.parameter}-ngw-${az}"]
  }

  ec2 = {
    bastion = {
      name                              = "${local.parameter}-bastion"
      instance_type                     = "t2.micro"

      security_group_name               = "${local.parameter}-bastion-sg"
      ingress_protocol                  = ["TCP", "UDP"]
      egress_protocol                   = ["TCP", "UDP"]
      ingress_cidr_blocks               = ["0.0.0.0/0"]
      egress_cidr_blocks                = ["0.0.0.0/0"]
      ingress_ports                     = [22]
      egress_ports                      = [80, 443, 3306]
    }
  }
  
  rds = {
    rds_cluster_name                  = "${local.parameter}-db-cluster"
    rds_cluster_db_name               = "${local.parameter}"
    rds_cluster_cw_logs_exports       = ["audit", "error", "general", "slowquery"]
    rds_cluster_engine                = "aurora-mysql"
    rds_cluster_user_name             = "admin"
    rds_cluster_user_password         = "Skill53##"
    rds_cluster_port                  = 3306

    rds_cluster_instance_name         = "${local.parameter}-db-instance"
    rds_cluster_instance_count        = 1
    rds_cluster_instance_class        = "db.t3.medium"
    rds_cluster_instance_engine       = "aurora-mysql"

    rds_subnet_group_name             = "${local.parameter}-db-sg"

    rds_cluster_parmeter_group_name   = "${local.parameter}-db-cpg"
    rds_cluster_parmeter_group_family = "aurora-mysql8.0"

    rds_parameter_group_name          = "${local.parameter}-db-pg"
    rds_parameter_group_family        = "aurora-mysql8.0"

    security_group_name               = "${local.parameter}-rds-sg"
    ingress_protocol                  = ["TCP", "UDP"]
    egress_protocol                   = ["TCP", "UDP"]
    ingress_cidr_blocks               = ["0.0.0.0/0"]
    egress_cidr_blocks                = ["0.0.0.0/0"]
    ingress_ports                     = [3306]
    egress_ports                      = [-1]
  }

  rds_proxy = {
    name                              = "${local.parameter}-db-proxy"
    engine                            = "MYSQL"

    role_name                         = "${local.parameter}-db-proxy-role"
    policy_name                       = "${local.parameter}-db-proxy-polcy"

    security_group_name               = "${local.parameter}-rds-proxy-sg"
    ingress_protocol                  = ["TCP", "UDP"]
    egress_protocol                   = ["TCP", "UDP"]
    ingress_cidr_blocks               = ["0.0.0.0/0"]
    egress_cidr_blocks                = ["0.0.0.0/0"]
    ingress_ports                     = [3306]
    egress_ports                      = [-1]
  }

  secrets_manager = {
    rds_proxy = {
      name = "${local.parameter}-rds-credentials-secrets"
    }
  }

  iam = {
    github = {
      name = "github-user"
    }
  }

  ecr = {
    name = "${local.parameter}-ecr"
  }
}