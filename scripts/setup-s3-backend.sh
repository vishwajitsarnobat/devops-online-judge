#!/usr/bin/env bash
# ============================================================================
# setup-s3-backend.sh — Run this ONCE before the first `terraform init`
# Creates the S3 bucket that stores Terraform state.
# ============================================================================
set -euo pipefail

BUCKET="online-judge-tfstate"
REGION="ap-south-1"

echo "Creating S3 bucket: ${BUCKET} in ${REGION}..."

aws s3api create-bucket \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

# Enable versioning so you can recover previous state files if something
# goes wrong during a Terraform apply.
aws s3api put-bucket-versioning \
  --bucket "${BUCKET}" \
  --versioning-configuration Status=Enabled

echo ""
echo "✅ S3 bucket '${BUCKET}' created with versioning enabled."
echo "   You can now run: cd terraform && terraform init"
