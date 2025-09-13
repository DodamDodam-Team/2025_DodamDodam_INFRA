resource "aws_security_group" "rds" {
  name   = var.rds_security_group_name
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.rds_ingress_ports
    
    content {
      protocol    = var.rds_ingress_protocol[0]
      cidr_blocks = [var.rds_ingress_cidr_blocks[0]]
      from_port   = ingress.value
      to_port     = ingress.value
    }
  }

  dynamic "egress" {
    for_each = var.rds_egress_ports

    content {
      protocol    = var.rds_egress_protocol[0]
      cidr_blocks = [var.rds_egress_cidr_blocks[0]]
      from_port   = egress.value
      to_port     = egress.value
    }
  }

  tags = {
    Name = var.rds_security_group_name
  }
}

resource "aws_security_group" "rds-proxy" {
  name   = var.rds_proxy_security_group_name
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.rds_proxy_ingress_ports
    
    content {
      protocol    = var.rds_proxy_ingress_protocol[0]
      cidr_blocks = [var.rds_proxy_ingress_cidr_blocks[0]]
      from_port   = ingress.value
      to_port     = ingress.value
    }
  }

  dynamic "egress" {
    for_each = var.rds_proxy_egress_ports

    content {
      protocol    = var.rds_proxy_egress_protocol[0]
      cidr_blocks = [var.rds_proxy_egress_cidr_blocks[0]]
      from_port   = egress.value
      to_port     = egress.value
    }
  }

  tags = {
    Name = var.rds_proxy_security_group_name
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = var.rds_subnet_group_name
  subnet_ids = var.protect_subnet_ids

  tags = {
    Name = var.rds_subnet_group_name
  }
}

resource "aws_rds_cluster_parameter_group" "rds" {
  name        = var.rds_cluster_parmeter_group_name
  description = var.rds_cluster_parmeter_group_name
  family      = var.rds_cluster_parmeter_group_family

  parameter {
    name  = "time_zone"
    value = "Asia/Seoul"
  }

  tags = {
    Name = var.rds_cluster_parmeter_group_name
  }
}

resource "aws_db_parameter_group" "rds" {
  name        = var.rds_parameter_group_name
  description = var.rds_parameter_group_name
  family      = var.rds_parameter_group_family

  tags = {
    Name = var.rds_parameter_group_name
  }
}

resource "aws_rds_cluster" "rds" {
  cluster_identifier              = var.rds_cluster_name
  database_name                   = var.rds_cluster_db_name
  availability_zones              = var.azs
  db_subnet_group_name            = aws_db_subnet_group.rds.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.rds.name
  enabled_cloudwatch_logs_exports = var.rds_cluster_cw_logs_exports
  engine                          = var.rds_cluster_engine
  backtrack_window                = 14400
  master_username                 = var.rds_cluster_user_name
  master_password                 = var.rds_cluster_user_password
  skip_final_snapshot             = true
  storage_encrypted               = true
  port                            = var.rds_cluster_port

  tags = {
    Name = var.rds_cluster_name
  }
}

resource "aws_rds_cluster_instance" "rds" {
  count                   = var.rds_cluster_instance_count
  cluster_identifier      = aws_rds_cluster.rds.id
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  db_parameter_group_name = aws_db_parameter_group.rds.name
  instance_class          = var.rds_cluster_instance_class
  identifier              = var.rds_cluster_instance_name
  engine                  = var.rds_cluster_instance_engine

  tags = {
    Name = var.rds_cluster_instance_name
  }
}

resource "aws_db_proxy" "rds" {
  name                   = var.rds_proxy_name
  engine_family          = var.rds_proxy_engine
  role_arn               = aws_iam_role.rds.arn
  vpc_security_group_ids = [aws_security_group.rds-proxy.id]
  vpc_subnet_ids         = var.protect_subnet_ids

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = var.db_proxy_secrets_manager_arn
  }

  depends_on = [
    aws_rds_cluster.rds,
    aws_rds_cluster_instance.rds,
    aws_iam_role.rds,
  ]

  tags = {
    Name = var.rds_proxy_name
  }
}

resource "aws_db_proxy_default_target_group" "rds" {
  db_proxy_name = aws_db_proxy.rds.name

  connection_pool_config {
    connection_borrow_timeout    = 300
    max_connections_percent      = 100
    session_pinning_filters      = []
  }
}

resource "aws_db_proxy_target" "rds_proxy" {
  db_instance_identifier = aws_rds_cluster.rds.cluster_identifier
  db_proxy_name          = aws_db_proxy.rds.name
  target_group_name      = aws_db_proxy_default_target_group.rds.name
}

resource "aws_secretsmanager_secret_version" "db-proxy" {
  secret_id        = var.db_proxy_secrets_manager_id
  secret_string    = jsonencode({
    "username"     = aws_rds_cluster.rds.master_username,
    "password"     = aws_rds_cluster.rds.master_password
  })
}

resource "aws_iam_role" "rds" {
  name = var.rds_proxy_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds" {
  name   = var.rds_proxy_policy_name
  role   = aws_iam_role.rds.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect   = "Allow",
        Resource = "${var.db_proxy_secrets_manager_arn}"
      },
      {
        Action = [
          "rds-db:connect"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "kms:Decrypt"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}