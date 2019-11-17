#!/usr/bin/env bash


# After configure-shell

./tf --cluster andromeda init

#tf --cluster andromeda init \
#  -backend-config="bucket=<s3 bucket>" \
#  -backend-config="region=<s3 region>" \
#  -backend-config="endpoint=<s3 endpoint, not needed with Amazon S3" \
#  -backend-config="access_key=<s3 access key>" \
#  -backend-config="secret_key=<s3 secret key>" \
#  -backend-config="key=terraform/terraform.tfstate"