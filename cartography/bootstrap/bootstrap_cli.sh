#!/bin/bash
IFS=$'\n\t'

#
# PURPOSE:
# Bootstraps a given account's IAM roles for onboarding to retrieve asset inventory.
# This is based on the AWS access key and secret that
# is currently exported.
#
# USE:
# ./bootstrap.sh 
#

# Setup profiles for all accounts that you have access to
aws-sso-util configure populate --region ca-central-1

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ACCOUNT_LIST="$(aws configure list-profiles)"
SECURITY_AUDIT_ROLE_NAME="AssetInventorySecurityAuditRole"

while IFS= read -r AWS_PROFILE
do
  if [[ "$AWS_PROFILE" == *".AdministratorAccess"* ]] && [[ "$AWS_PROFILE" == *"scratch"* ]]; then
    echo -e "\033[0;33m⚡\033[0m Onboard account \033[0;35m$AWS_PROFILE\033[0m"
    ASSUMED_ROLE="$(aws --profile $AWS_PROFILE sts get-caller-identity | jq -r '.Arn')"
    echo -e "\033[0;33m✔\033[0m Assumed role via SSO: $ASSUMED_ROLE"
    ROLE_EXISTS="$(aws --profile $AWS_PROFILE iam get-role --role-name $SECURITY_AUDIT_ROLE_NAME --output text 2>&1)"
    if [[ "$ROLE_EXISTS" == *"NoSuchEntity"* ]]; then
      echo -e "\033[0;33m✔\033[0m $SECURITY_AUDIT_ROLE_NAME doesn't exist, creating"
      aws --profile $AWS_PROFILE iam create-role --role-name $SECURITY_AUDIT_ROLE_NAME --assume-role-policy-document file://trust-policy.json > /dev/null 2>&1
      aws --profile $AWS_PROFILE iam wait role-exists --role-name $SECURITY_AUDIT_ROLE_NAME
    fi
    echo -e "\033[0;33m✔\033[0m Attaching policies to $SECURITY_AUDIT_ROLE_NAME"
    aws --profile $AWS_PROFILE iam update-assume-role-policy --role-name $SECURITY_AUDIT_ROLE_NAME --policy-document file://trust-policy.json > /dev/null 2>&1
    aws --profile $AWS_PROFILE iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/SecurityAudit --role-name $SECURITY_AUDIT_ROLE_NAME
    sleep 1
  fi
   
done < <(printf '%s\n' "$ACCOUNT_LIST")