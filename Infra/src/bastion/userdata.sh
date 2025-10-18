#!/bin/bash
yum update -y
yum install --allowerasing -y jq curl wget unzip
dnf install google-authenticator -y
dnf install -y mariadb105
dnf install -y redis7

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

sudo sed -i '40i\PermitRootLogin yes' /etc/ssh/sshd_config
sudo sed -i '41i\RSAAuthentication yes' /etc/ssh/sshd_config
sudo sed -i '8i\auth required pam_google_authenticator.so nullok' /etc/pam.d/sshd
sudo sed -i '10i\ChallengeResponseAuthentication yes' /etc/ssh/sshd_config.d/50-redhat.conf
sudo sed -i '22i\AuthenticationMethods publickey,keyboard-interactive' /etc/ssh/sshd_config.d/50-redhat.conf
sudo -u ec2-user bash -c "google-authenticator -t -f -d -w 17 -r 3 -R 30 -Q UTF8 -q"

sed -i 's|PasswordAuthentication no|PasswordAuthentication yes|' /etc/ssh/sshd_config
echo 'Port 5202' >> /etc/ssh/sshd_config
systemctl restart sshd
echo 'Null25##' | passwd --stdin ec2-user
echo 'Null25##' | passwd --stdin root

AUTH_FILE="/home/ec2-user/.google_authenticator"
MFA_KEY=$(grep -m 1 "^[A-Z2-7]*$" "$AUTH_FILE")
SECRET_NAME="bastion-mfa-key"
SECRET_JSON="{\"MFAKey\":\"$MFA_KEY\"}"
REGION_CODE="ap-northeast-2"

aws secretsmanager put-secret-value --secret-id "$SECRET_NAME" --secret-string "$SECRET_JSON" --region "$REGION_CODE"

# rm -f "$AUTH_FILE"