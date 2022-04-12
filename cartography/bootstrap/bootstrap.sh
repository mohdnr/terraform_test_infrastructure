#!/bin/bash
set -euo pipefail
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

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ACCOUNT_ID="$(aws sts get-caller-identity | jq -r .Account)"
echo -e "\n\033[0;33m⚡\033[0m Onboard account \033[0;35m$ACCOUNT_ID\033[0m\n"

rm -rf "$SCRIPT_DIR"/terraform* "$SCRIPT_DIR"/.terraform*
terraform -chdir="$SCRIPT_DIR" init
terraform -chdir="$SCRIPT_DIR" apply
