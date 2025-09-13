resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "keypair" {
  key_name = "${var.parameter}"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "keypair" {
  content = tls_private_key.rsa.private_key_pem
  filename = "./${var.parameter}.pem"
}

resource "aws_instance" "bastion" {
  ami = data.aws_ssm_parameter.latest_ami.value
  subnet_id = var.public_a_id
  instance_type = var.instance_type
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install --allowerasing -y jq curl wget unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
  EOF
  
  tags = {
    Name = var.bastion_name
  }
}

resource "aws_security_group" "bastion" {
  name   = var.security_group_name
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_ports
    
    content {
      protocol    = var.ingress_protocol[0]
      cidr_blocks = [var.ingress_cidr_blocks[0]]
      from_port   = ingress.value
      to_port     = ingress.value
    }
  }

  dynamic "egress" {
    for_each = var.egress_ports

    content {
      protocol    = var.egress_protocol[0]
      cidr_blocks = [var.egress_cidr_blocks[0]]
      from_port   = egress.value
      to_port     = egress.value
    }
  }

  tags = {
    Name = var.security_group_name
  }
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  associate_with_private_ip = aws_instance.bastion.private_ip
}