#!/bin/bash

mkdir -p /workspaces/scratch/clamav_api_ecs/image/app/clamav_defs

aws s3api get-object --region ca-central-1 --bucket mnur-clamav-test-speed-clamav-defs --key clamav_defs/bytecode.cvd /workspaces/scratch/clamav_api_ecs/image/app/clamav_defs/bytecode.cvd > /dev/null 2>&1
aws s3api get-object --region ca-central-1 --bucket mnur-clamav-test-speed-clamav-defs --key clamav_defs/daily.cld /workspaces/scratch/clamav_api_ecs/image/app/clamav_defs/daily.cld > /dev/null 2>&1
aws s3api get-object --region ca-central-1 --bucket mnur-clamav-test-speed-clamav-defs --key clamav_defs/daily.cvd /workspaces/scratch/clamav_api_ecs/image/app/clamav_defs/daily.cvd > /dev/null 2>&1
aws s3api get-object --region ca-central-1 --bucket mnur-clamav-test-speed-clamav-defs --key clamav_defs/main.cvd /workspaces/scratch/clamav_api_ecs/image/app/clamav_defs/main.cvd > /dev/null 2>&1

cp -r /workspaces/scratch/clamav_api_ecs/image/app/clamav_defs/* /tmp/clamav