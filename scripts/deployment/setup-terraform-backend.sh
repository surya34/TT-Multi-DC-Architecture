#!/bin/bash
set -euo pipefail

# Enterprise Terraform Backend Setup
# Purpose: Creates S3 backend and DynamoDB table for Terraform state management

echo "======================================="
echo "Enterprise Terraform Backend Setup"
echo "======================================="

# Accept AWS profile from argument or environment variable
AWS_PROFILE="${1:-${AWS_PROFILE:-default}}"

echo "Using AWS profile: $AWS_PROFILE"

# Configuration
ACCOUNT_ID=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)
BUCKET_NAME="terraform-state-${ACCOUNT_ID}-management"
TABLE_NAME="terraform-state-locks"
REGION="us-east-1"
ENVIRONMENT="production"

echo "Configuration:"
echo "  AWS Account: ${ACCOUNT_ID}"
echo "  S3 Bucket: ${BUCKET_NAME}"
echo "  DynamoDB Table: ${TABLE_NAME}"
echo "  Region: ${REGION}"
echo ""

# Create S3 bucket with enterprise features
echo "Creating S3 bucket for Terraform state..."
aws s3api create-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${REGION}" \
  --acl private \
  --profile "$AWS_PROFILE" 2>/dev/null || echo "Bucket exists, continuing..."

# Enable versioning
echo "Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled \
  --profile "$AWS_PROFILE"

# Enable encryption
echo "Configuring encryption..."
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }' \
  --profile "$AWS_PROFILE"

# Configure lifecycle policy
echo "Setting lifecycle policy..."
aws s3api put-bucket-lifecycle-configuration \
  --bucket "${BUCKET_NAME}" \
  --lifecycle-configuration '{
    "Rules": [
      {
        "ID": "DeleteOldVersions",
        "Filter": {
          "Prefix": ""
        },
        "Status": "Enabled",
        "NoncurrentVersionExpiration": {
          "NoncurrentDays": 90
        }
      }
    ]
  }'


# Block public access
echo "Configuring security settings..."
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile "$AWS_PROFILE"

# Add bucket tagging
echo "Adding resource tags..."
aws s3api put-bucket-tagging \
  --bucket "${BUCKET_NAME}" \
  --tagging '{
    "TagSet": [
      {"Key": "Environment", "Value": "production"},
      {"Key": "Purpose", "Value": "terraform-state"},
      {"Key": "ManagedBy", "Value": "terraform"},
      {"Key": "CostCenter", "Value": "platform-engineering"}
    ]
  }' \
  --profile "$AWS_PROFILE"

# Create DynamoDB table for state locking
echo "Creating DynamoDB table for state locking..."
aws dynamodb create-table \
  --table-name "${TABLE_NAME}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${REGION}" \
  --tags \
    Key=Environment,Value=production \
    Key=Purpose,Value=terraform-locks \
    Key=ManagedBy,Value=terraform \
  --profile "$AWS_PROFILE" \
  2>/dev/null || echo "Table exists, continuing..."

# Enable point-in-time recovery
echo "Enabling point-in-time recovery..."
aws dynamodb update-continuous-backups \
  --table-name "${TABLE_NAME}" \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
  --region "${REGION}" \
  --profile "$AWS_PROFILE" \
  2>/dev/null || true

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "Terraform backend configuration:"
echo "================================"
echo "bucket         = \"${BUCKET_NAME}\""
echo "region         = \"${REGION}\""
echo "dynamodb_table = \"${TABLE_NAME}\""
echo ""

# Save configuration for later use
echo "${BUCKET_NAME}" > .terraform-backend-bucket
echo "${TABLE_NAME}" > .terraform-backend-table

