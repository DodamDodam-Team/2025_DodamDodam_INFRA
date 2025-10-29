locals {
  parameter = "dodam"

  az_override  = ["a", "c"]

  azs = [
    for az in data.aws_availability_zones.az.names :
    az if contains(local.az_override, substr(az, -1, 1))
  ]
}

locals {
  vpcs = {
    "${local.parameter}-vpc" = {
      vpc_cidr         = "10.0.0.0/16"
      default_rtb_tags = {
        Name = "${local.parameter}-default-rtb"
      }

      vpc_tags = {
        Name        = "${local.parameter}-vpc"
      }

      enable_igw       = true
      enable_natgw     = true

      types = [
        {
          type         = "public"
          sn_cidrs     = ["10.0.0.0/24", "10.0.1.0/24"]
          sn_tags      = {
            Name = "${local.parameter}-public-$1"
          }

          rtb_tags     = {
            Name = "${local.parameter}-public-rtb"
          }

          igw_tags     = {
            Name = "${local.parameter}-igw"
          }
        },
        {
          type         = "private"
          sn_cidrs     = ["10.0.2.0/24", "10.0.3.0/24"]
          sn_tags      = {
            Name = "${local.parameter}-private-$1"
          }

          rtb_tags     = {
            Name       = "${local.parameter}-private-$1-rtb"
          }

          natgw_tags   = {
            Name = "${local.parameter}-natgw-$1"
          }
        },
        {
          type         = "protect"
          sn_cidrs     = ["10.0.4.0/24", "10.0.5.0/24"]
          sn_tags      = {
            Name = "${local.parameter}-protect-$1"
          }

          rtb_tags     = {
            Name = "${local.parameter}-protect-rtb"
          }
        },
      ]
    }
  }
}

locals {
  ec2s = {
    "${local.parameter}-bastion-ec2" = {
      vpc_name                = "${local.parameter}-vpc"
      subnet_name             = "${local.parameter}-public-a"

      instance_tags = {
        Name = "${local.parameter}-bastion-ec2"
      }
      
      security_group_name     = "${local.parameter}-bastion-sg"
      instance_type           = "t2.micro"
      userdata                = "/ec2/bastion/userdata.sh"
      
      enable_public_ip        = true
      enable_eip              = true
      eip_tags = {
        Name = "${local.parameter}-bastion-eip"
      }

      ingress_ports = [
        { from_port = 5202, to_port = 5202, protocol = "tcp", cidr_block = "0.0.0.0/0"},
      ]

      egress_ports = [
        { from_port = 22, to_port = 22, protocol = "tcp", cidr_block = "0.0.0.0/0"},
        { from_port = 80, to_port = 80, protocol = "tcp", cidr_block = "0.0.0.0/0"},
        { from_port = 443, to_port = 443, protocol = "tcp", cidr_block = "0.0.0.0/0"},
        { from_port = 13306, to_port = 13306, protocol = "tcp", cidr_block = "0.0.0.0/0"},
        { from_port = 16379, to_port = 16379, protocol = "tcp", cidr_block = "0.0.0.0/0"},
      ]
      
      enable_create_keypair = true
      keypair_name          = "${local.parameter}"
      keypair_file_path     = "${path.cwd}/${local.parameter}.pem"

      enable_create_iam_role = true
      iam_role_name         = "${local.parameter}-bastion-role"
      instance_profile_name = "${local.parameter}-bastion-profile"
      iam_policies          = ["arn:aws:iam::aws:policy/SecretsManagerReadWrite"]
    },
    "${local.parameter}-jenkins-ec2" = {
      vpc_name                = "${local.parameter}-vpc"
      subnet_name             = "${local.parameter}-private-a"

      instance_tags = {
        Name = "${local.parameter}-jenkins-ec2"
      }
      
      security_group_name     = "${local.parameter}-jenkins-sg"
      instance_type           = "t2.micro"
      userdata                = "/ec2/jenkins/userdata.sh"
      
      enable_public_ip        = false
      enable_eip              = false
      eip_tags = {
        Name = "${local.parameter}-jenkins-eip"
      }

      ingress_ports = [
        { from_port = 22, to_port = 22, protocol = "tcp", cidr_block = "0.0.0.0/0"},
        { from_port = 8080, to_port = 8080, protocol = "tcp", cidr_block = "0.0.0.0/0"},
      ]

      egress_ports = [
        { from_port = 80, to_port = 80, protocol = "tcp", cidr_block = "0.0.0.0/0"},
        { from_port = 443, to_port = 443, protocol = "tcp", cidr_block = "0.0.0.0/0"}
      ]
      
      enable_create_keypair = false
      keypair_name          = "${local.parameter}"
      keypair_file_path     = "${path.cwd}/${local.parameter}.pem"

      enable_create_iam_role = true
      iam_role_name         = "${local.parameter}-jenkins-role"
      instance_profile_name = "${local.parameter}-jenkins-profile"
      iam_policies          = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    },
  }
}

locals {
  albs = {
    "${local.parameter}-app-alb" = {
      vpc_name                = "${local.parameter}-vpc"

      alb_tags = {
        Name = "${local.parameter}-app-alb"
      }
      internal                  = true
      port                      = 80
      protocol                  = "HTTP"
      listener_target_groups    = ["${local.parameter}-app-alb-tg"]

      target_groups = [
        {
          name                  = "${local.parameter}-app-alb-tg"
          port                  = 80
          protocol              = "HTTP"
          target_type           = "instance"
          deregistration_delay  = 30
          tags = {
            Name = "${local.parameter}-app-alb-tg"
          }

          health_check = {
            protocol            = "HTTP"
            path                = "/"
            port                = 8080
            interval            = 5
            timeout             = 2
            healthy_threshold   = 2
            unhealthy_threshold = 2
            matcher             = "200-399"
          }
        }
      ]

      enable_attach_target      = false
      targets = [
        {
          type                  = "ec2"
          target_group_name     = "${local.parameter}-app-alb-tg"
          target_name           = "${local.parameter}-app-ec2"
          target_port           = 80
        },
      ]

      security_group_name     = "${local.parameter}-app-alb-sg"
      security_group_tags = {
        Name = "${local.parameter}-app-alb-sg"
      }

      ingress_ports = [
        { from_port = 80, to_port = 80, protocol = "tcp", cidr_block = "0.0.0.0/0"},
      ]

      egress_ports = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_block = "0.0.0.0/0"},
      ]
    },
    "${local.parameter}-jenkins-alb" = {
      vpc_name                = "${local.parameter}-vpc"

      alb_tags = {
        Name = "${local.parameter}-jenkins-alb"
      }
      internal                  = true
      port                      = 80
      protocol                  = "HTTP"
      listener_target_groups    = ["${local.parameter}-jenkins-alb-tg"]

      target_groups = [
        {
          name                  = "${local.parameter}-jenkins-alb-tg"
          port                  = 80
          protocol              = "HTTP"
          target_type           = "instance"
          deregistration_delay  = 30
          tags = {
            Name = "${local.parameter}-alb-tg"
          }

          health_check = {
            protocol            = "HTTP"
            path                = "/"
            port                = 80
            interval            = 5
            timeout             = 2
            healthy_threshold   = 2
            unhealthy_threshold = 2
            matcher             = "200-399"
          }
        }
      ]

      enable_attach_target      = true
      targets = [
        {
          type                  = "ec2"
          target_group_name     = "${local.parameter}-jenkins-alb-tg"
          target_name           = "${local.parameter}-jenkins-ec2"
          target_port           = 80
        },
      ]

      security_group_name     = "${local.parameter}-jenkins-alb-sg"
      security_group_tags = {
        Name = "${local.parameter}-jenkins-alb-sg"
      }

      ingress_ports = [
        { from_port = 80, to_port = 80, protocol = "tcp", cidr_block = "0.0.0.0/0"},
      ]

      egress_ports = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_block = "0.0.0.0/0"},
      ]
    }
  }
}

locals {
  launch_templates = {
    "${local.parameter}-app-lt" = {
      vpc_name = "${local.parameter}-vpc"
      tags = {
        Name = "${local.parameter}-app-lt"
        type = "app"
      }

      enable_monitoring = true

      instance_type = "t2.micro"
      userdata      = "/ec2/asg/userdata.sh"

      block_device_mappings = [
        {
          device_name = "/dev/xvda" # /dev/sdh or /dev/xvda
          ebs = {
            volume_size           = 10
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      ]

      tag_specifications = [
        {
          resource_type = "instance"
          tags = {
            Name = "${local.parameter}-app-ec2"
          }
        }
      ]

      security_group_name = "${local.parameter}-asg-sg"

      ingress_ports = [
        { from_port = 22, to_port = 22, protocol = "tcp", cidr_block = "0.0.0.0/0"},
        { from_port = 8080, to_port = 8080, protocol = "tcp", cidr_block = "0.0.0.0/0"},
      ]

      egress_ports = [
        { from_port = 80, to_port = 80, protocol = "tcp", cidr_block = "0.0.0.0/0"},
        { from_port = 443, to_port = 443, protocol = "tcp", cidr_block = "0.0.0.0/0"},
        { from_port = 13306, to_port = 13306, protocol = "tcp", cidr_block = "0.0.0.0/0"},
        { from_port = 16379, to_port = 16379, protocol = "tcp", cidr_block = "0.0.0.0/0"}
      ]
      
      enable_create_keypair = false
      keypair_name          = "${local.parameter}"
      keypair_file_path     = "${path.cwd}/${local.parameter}.pem"

      enable_create_iam_role = true
      iam_role_name         = "${local.parameter}-asg-role"
      instance_profile_name = "${local.parameter}-asg-profile"
      iam_policies          = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]
    },
  }
}

locals {
  asgs = {
    "${local.parameter}-app-asg" = {
      vpc_name                 = "${local.parameter}-vpc"
      internal                 = true

      tags = {
        Name = "${local.parameter}-app-asg"
      }
      tags_no_launch            = false

      desired_capacity          = 2
      min_size                  = 1
      max_size                  = 6

      desired_capacity_type     = "units"
      health_check_type         = "ELB" # EC2
      health_check_grace_period = 300
      timeout_delete_time       = "10m"

      tags = [
        {
          key   = "Name"
          value = "${local.parameter}-app-asg"
        },
      ]

      launch_template_name       = "${local.parameter}-app-lt"
      
      enable_attach_elb          = true
      elb_name                   = "${local.parameter}-app-alb"
      elb_target_group_name      = "${local.parameter}-app-alb-tg"
      
      enable_scaling_policy      = true
      scaling_policys = [
        {
          name = "${local.parameter}-cpu-target-policy"
          policy_type = "TargetTrackingScaling"
          target_tracking_configuration = {
            predefined_metric_specification = {
              predefined_metric_type = "ASGAverageCPUUtilization"
            }
            target_value       = 50.0
            disable_scale_in   = false
          }
        },
        {
          name = "${local.parameter}-alb-request-policy"
          policy_type = "TargetTrackingScaling"
          target_tracking_configuration = {
            predefined_metric_specification = {
              predefined_metric_type = "ALBRequestCountPerTarget"
            }
            target_value       = 50.0
            disable_scale_in   = false
          }
        },
      ]
    },
  }
}

locals {
  ecrs = {
    "${local.parameter}-ecr" = {
      tags = {
        Name = "${local.parameter}-ecr"
      }

      image_tag_mutability              = "MUTABLE"
      force_delete                      = true
      scan_images_on_push               = true

      enable_kms                        = false
      kms_key_name                      = "${local.parameter}/ecr/kms"
      encryption_type                   = "KMS"

      enable_image_tag_exclusion_filter = false
      image_tag_exclusion_filter = [
        {filter = "latest", filter_type = "WILDCARD"},
      ]
    }
  }
}

locals {
  elaticaches = {
    "${local.parameter}-redis-cluster" = {
      vpc_name                        = "${local.parameter}-vpc"

      node_type                       = "cache.t4g.small"
      engine                          = "redis"
      engine_version                  = "7.1"
      port                            = 16379
      num_node_groups                 = 2
      replicas_per_node_group         = 1
  
      automatic_failover_enabled      = true
      multi_az_enabled                = true
      apply_immediately               = true
      at_rest_encryption_enabled      = true
      transit_encryption_enabled      = true
      transit_encryption_mode         = "preferred" # required

      subnet_group_name               = "${local.parameter}-redis-sg"
      parameter_group_name            = "${local.parameter}-redis-pg"
      parameter_group_family          = "redis7"
      parameters = [
        {
          name  = "latency-tracking"
          value = "yes"
        },
      ]

      security_group_name             = "${local.parameter}-redis-sg"

      ingress_ports = [
        { from_port = 16379, to_port = 16379, protocol = "tcp", cidr_block = "0.0.0.0/0"},
      ]

      egress_ports = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_block = "0.0.0.0/0"},
      ]
    }
  }
}

locals {
  rdss = {
    "${local.parameter}-db-cluster" = {
      vpc_name                        = "${local.parameter}-vpc"

      rds_cluster_tags = {
        Name = "${local.parameter}-db-cluster"
      }

      db_name                         = "${local.parameter}"
      cw_logs_exports                 = ["audit", "error", "general", "slowquery"]
      engine                          = "aurora-mysql"
      user_name                       = "admin"
      user_password                   = "Null25##"
      port                            = 13306
      backtrack_window                = 14400
      skip_final_snapshot             = true
      storage_encrypted               = true
      performance_insights_enabled    = false

      instance_name                   = "${local.parameter}-db-instance"
      instance_count                  = 2
      instance_class                  = "db.t3.medium"
      instance_engine                 = "aurora-mysql"
      instance_tags = {
        Name = "${local.parameter}-db-instance"
      }

      subnet_group_name               = "${local.parameter}-db-sg"
      subnet_group_tags = {
        Name = "${local.parameter}-db-sg"
      }

      cluster_parameter_group_name     = "${local.parameter}-db-cpg"
      cluster_parameter_group_family   = "aurora-mysql8.0"
      parameters = [
      {
          name  = "time_zone"
          value = "Asia/Seoul"
        }
      ]
      cluster_parameter_group_tags = {
        Name = "${local.parameter}-db-cpg"
      }

      parameter_group_name            = "${local.parameter}-db-pg"
      parameter_group_family          = "aurora-mysql8.0"
      parameter_group_tags = {
        Name = "${local.parameter}-db-pg"
      }

      security_group_name             = "${local.parameter}-rds-sg"
      security_group_tags = {
        Name = "${local.parameter}-rds-sg"
      }

      ingress_ports = [
        { from_port = 13306, to_port = 13306, protocol = "tcp", cidr_block = "0.0.0.0/0"},
      ]

      egress_ports = [
        { from_port = 0, to_port = 0, protocol = "-1", cidr_block = "0.0.0.0/0"},
      ]
    }
  }
}

locals {
  secrets_managers = {
    db = {
      enable_values = true
      name          = "${local.parameter}-db-secrets"
      rds_name      = "${local.parameter}-db-cluster"
      elaticache_name = "${local.parameter}-redis-cluster"
    }
    mfa = {
      enable_values = false
      name          = "${local.parameter}-bastion-mfa-key"
    }
  }
}