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

RDS_DB_ADDRESS=$(aws secretsmanager get-secret-value --secret-id dodam-db-secrets --query SecretString --output text | jq -r .RDS_DB_ADDRESS)
RDS_DB_NAME=$(aws secretsmanager get-secret-value --secret-id dodam-db-secrets --query SecretString --output text | jq -r .RDS_DB_NAME)
RDS_DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id dodam-db-secrets --query SecretString --output text | jq -r .RDS_DB_PASSWORD)
RDS_DB_PORT=$(aws secretsmanager get-secret-value --secret-id dodam-db-secrets --query SecretString --output text | jq -r .RDS_DB_PORT)
RDS_DB_USER=$(aws secretsmanager get-secret-value --secret-id dodam-db-secrets --query SecretString --output text | jq -r .RDS_DB_USER)
JWT_SECRET_KEY=$(aws secretsmanager get-secret-value --secret-id dodam-jwt-secrets --query SecretString --output text | jq -r .JWT_SECRET_KEY)

aws ecr get-login-password --region $REGION_CODE | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION_CODE.amazonaws.com
LATEST_DOCKER_IMAGE=$(aws ecr describe-images --repository-name $ECR_NAME --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' --output text --region $REGION_CODE)
docker pull $ACCOUNT_ID.dkr.ecr.$REGION_CODE.amazonaws.com/$ECR_NAME:$LATEST_DOCKER_IMAGE
docker run -d \
  -p 8080:8080 \
  --name dodam-cnt \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SPRING_DATASOURCE_URL="jdbc:mysql://${RDS_DB_ADDRESS}:${RDS_DB_PORT}/${RDS_DB_NAME}?useSSL=false&serverTimezone=UTC&useUnicode=true&characterEncoding=UTF-8" \
  -e SPRING_DATASOURCE_USERNAME="${RDS_DB_USER}" \
  -e SPRING_DATASOURCE_PASSWORD="${RDS_DB_PASSWORD}" \
  -e JWT_SECRET_KEY="${JWT_SECRET_KEY}" \
  -e JWT_SECRET="${JWT_SECRET_KEY}" \
  -e JWT_SECRETKEY="${JWT_SECRET_KEY}" \
  -e SPRING_APPLICATION_JSON="{\"jwt\":{\"secretKey\":\"${JWT_SECRET_KEY}\"}}" \
  $ACCOUNT_ID.dkr.ecr.$REGION_CODE.amazonaws.com/$ECR_NAME:$LATEST_DOCKER_IMAGE