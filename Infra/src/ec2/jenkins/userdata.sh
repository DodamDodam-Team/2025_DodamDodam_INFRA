#!/bin/bash
yum update -y
yum install --allowerasing -y jq curl wget unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

sed -i 's|PasswordAuthentication no|PasswordAuthentication yes|' /etc/ssh/sshd_config
systemctl restart sshd
echo 'Null25##' | passwd --stdin ec2-user
echo 'Null25##' | passwd --stdin root

yum install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user
usermod -aG docker root
usermod -aG docker jenkins
chmod 666 /var/run/docker.sock

sudo dnf install -y java-17-amazon-corretto
sudo yum install -y java-17-amazon-corretto-devel
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf install -y jenkins
sudo systemctl enable --now jenkins

JENKINS_DEFAULT_ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
JENKINS_URL="http://localhost:8080"
USER_ID="admin"

wget $JENKINS_URL/jnlpJars/jenkins-cli.jar

java -jar jenkins-cli.jar -s "${JENKINS_URL}" -auth "$USER_ID:$JENKINS_DEFAULT_ADMIN_PASSWORD" groovy = <<EOF
import jenkins.model.*
import hudson.model.User
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder

def user = hudson.model.User.get('admin')
user.addProperty(hudson.security.HudsonPrivateSecurityRealm.Details.fromPlainPassword('Null25##'))
println "Password for 'admin' reset to 'Null25##'"
EOF