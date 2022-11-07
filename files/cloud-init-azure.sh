#!/bin/sh
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

export PUBLIC_REPO=artifacts.cyralpublic.appspot.com
export GCS_API_ENDPOINT=https://storage.googleapis.com
export DOCKER_COMPOSE_VERSION=1.29.2
export JQ_VERSION=1.6
export BASTION_BOOTSTRAP_VERSION=0.1.1

# Install docker-compose
wget $GCS_API_ENDPOINT/$PUBLIC_REPO/sidecar/docker-compose/$DOCKER_COMPOSE_VERSION/docker-compose-Linux-x86_64
sudo mv docker-compose-`uname -s`-`uname -m` /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version

# Configure fd limit for ec2 instance and containers
sudo bash -c 'cat > /etc/security/limits.d/fdlimit.conf' << EOF
*       soft  nofile  65535
*       hard  nofile  65535
EOF
#sudo bash -c 'cat > /etc/sysconfig/docker' << EOF
#DAEMON_MAXFILES=65535
#OPTIONS="--default-ulimit nofile=65535:65535"
#DAEMON_PIDFILE_TIMEOUT=10
#EOF
sudo systemctl restart docker

# Install JQ
wget -q $GCS_API_ENDPOINT/$PUBLIC_REPO/sidecar/jq/$JQ_VERSION/jq-linux64
sudo mv jq-linux64 /usr/local/bin/jq
sudo chmod a+x /usr/local/bin/jq
sudo ln -s /usr/local/bin/jq /usr/bin/jq
export PATH=$PATH:/usr/local/bin
jq --version

# wget $GCS_API_ENDPOINT/$PUBLIC_REPO/sidecar/quickstart-linux-bastion/$BASTION_BOOTSTRAP_VERSION/bastion_bootstrap.sh -O /home/adminuser/bootstrap.sh
# chmod a+x /home/adminuser/bootstrap.sh
# function bootstrap () { /home/adminuser/bootstrap.sh  --tcp-forwarding true --public-gcp-repo $PUBLIC_REPO --gcs-api-endpoint $GCS_API_ENDPOINT; }
# retry bootstrap
# sudo service sshd restart

# Configure cloudwatch
# TODO define logs

# echo "Fetching public hostname..."
export STATUS_CODE=$(curl -o instance-id.txt -w "%%{http_code}\n" -s http://169.254.169.254/latest/meta-data/instance-id -m 10)
if [ $STATUS_CODE -eq 200 ]; then
  export INSTANCE_ID=$(cat instance-id.txt)
else
  export INSTANCE_ID=$HOSTNAME
fi
echo "Setting INSTANCE_ID to '$INSTANCE_ID'"

export NGINX_RESOLVER=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
echo "Setting NGINX_RESOLVER to '$NGINX_RESOLVER'"

echo "Fetching secrets..."
mkdir -p /home/adminuser/cyral/

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg -y
# curl -sL https://packages.microsoft.com/keys/microsoft.asc |
#     gpg --dearmor |
#     sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
# AZ_REPO=$(lsb_release -cs)
# echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
#     sudo tee /etc/apt/sources.list.d/azure-cli.list
# sudo apt-get update -y
# sudo apt-get install azure-cli -y


echo "Initializing environment variables..."

# cat > /home/ec2-user/.env << EOF
# SIDECAR_ID=${sidecar_id}
# CONTROLPLANE_HOST=${controlplane_host}
# CONTAINER_REGISTRY=${container_registry}
# SECRETS_LOCATION=${secrets_location}
# ELK_ADDRESS=${elk_address}
# ELK_USERNAME=${elk_username}
# ELK_PASSWORD=${elk_password}
# SIDECAR_ENDPOINT=${sidecar_endpoint}
# AWS_REGION=${aws_region}
# INSTANCE_ID=$INSTANCE_ID
# DD_API_KEY=${dd_api_key}
# LOG_GROUP_NAME=${log_group_name}

# LOG_INTEGRATION=${log_integration}
# METRICS_INTEGRATION=${metrics_integration}

# NGINX_RESOLVER=$NGINX_RESOLVER
# SSO_LOGIN_URL=${idp_sso_login_url}
# IDP_CERTIFICATE=${idp_certificate}

# SPLUNK_INDEX=${splunk_index}
# SPLUNK_HOST=${splunk_host}
# SPLUNK_PORT=${splunk_port}
# SPLUNK_TLS=${splunk_tls}
# SPLUNK_TOKEN=${splunk_token}

# SUMOLOGIC_HOST=${sumologic_host}
# SUMOLOGIC_URI=${sumologic_uri}

# HCVAULT_INTEGRATION_ID=${hc_vault_integration_id}

# MONGODB_PORT_ALLOC_RANGE_LOW=${mongodb_port_alloc_range_low}
# MONGODB_PORT_ALLOC_RANGE_HIGH=${mongodb_port_alloc_range_high}

# MYSQL_MULTIPLEXED_PORT=${mysql_multiplexed_port}

# LOAD_BALANCER_TLS_PORTS=${load_balancer_tls_ports}

# CYRAL_CERTIFICATE_MANAGER_SELFSIGNED_SECRET_ID=${sidecar_created_certificate_secret_id}
# CYRAL_CERTIFICATE_MANAGER_SELFSIGNED_SECRET_TYPE=aws
# EOF


