#!/bin/bash

yum update && yum install -y jq
curl -sqL -o aws_credentials.json http://169.254.170.2/$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI > aws_credentials.json

mkdir -p ~/.aws/

cat <<EOF >> /config/role_config
[default]
region = ca-central-1
output=json
aws_access_key_id=$(jq -r '.AccessKeyId' aws_credentials.json)
aws_secret_access_key=$(jq -r '.SecretAccessKey' aws_credentials.json)
aws_session_token=$(jq -r '.Token' aws_credentials.json)
EOF

cat /config/role_config
echo "AWS configuration complete"