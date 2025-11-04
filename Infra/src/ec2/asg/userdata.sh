#!/bin/bash
ECR_NAME="dodam-ecr"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION_CODE="ap-northeast-2"

yum update -y
yum install --allowerasing -y jq curl wget unzip
dnf install -y mariadb105
dnf install -y redis7

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

sed -i 's|PasswordAuthentication no|PasswordAuthentication yes|g' /etc/ssh/sshd_config
systemctl restart sshd
echo 'Null25##' | passwd --stdin ec2-user
echo 'Null25##' | passwd --stdin root

yum install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user
usermod -aG docker root
chmod 666 /var/run/docker.sock

aws ecr get-login-password --region $REGION_CODE | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION_CODE.amazonaws.com
LATEST_DOCKER_IMAGE=$(aws ecr describe-images --repository-name $ECR_NAME --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' --output text --region $REGION_CODE)
docker pull $ACCOUNT_ID.dkr.ecr.$REGION_CODE.amazonaws.com/$ECR_NAME:$LATEST_DOCKER_IMAGE
docker run -d -p 8080:8080 --name dodam-cnt $ACCOUNT_ID.dkr.ecr.$REGION_CODE.amazonaws.com/$ECR_NAME:$LATEST_DOCKER_IMAGE