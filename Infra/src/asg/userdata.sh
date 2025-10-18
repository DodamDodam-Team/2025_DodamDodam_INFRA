#!/bin/bash
yum update -y
yum install --allowerasing -y jq curl wget unzip
dnf install -y mariadb105
dnf install -y redis7

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

yum install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user
usermod -aG docker root
chmod 666 /var/run/docker.sock