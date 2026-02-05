#!/bin/bash
set -e

# Configuration
PROJECT_NAME="fastapi-microservices"
ENVIRONMENT="prod"
REGION=$(aws configure get region)
# Default to eu-north-1 if aws configure is empty
if [ -z "$REGION" ]; then
    REGION="eu-north-1"
fi

BUCKET_NAME="${PROJECT_NAME}-${ENVIRONMENT}-terraform-state"
DYNAMODB_TABLE="${PROJECT_NAME}-${ENVIRONMENT}-terraform-locks"

echo "Using Region: $REGION"
echo "Creating S3 bucket: $BUCKET_NAME"
echo "Creating DynamoDB table: $DYNAMODB_TABLE"

# Check if bucket exists
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket $BUCKET_NAME already exists."
else
    echo "Creating bucket..."
    # Create bucket (us-east-1 does not explicitly require LocationConstraint)
    if [ "$REGION" == "us-east-1" ]; then
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
    else
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
    fi
    echo "Bucket created."
fi

# Enable Versioning
echo "Enabling versioning..."
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled

# Enable Encryption
echo "Enabling encryption..."
aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

echo "Creating DynamoDB table: $DYNAMODB_TABLE..."

# Check if table exists
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" >/dev/null 2>&1; then
    echo "Table $DYNAMODB_TABLE already exists."
else
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$REGION"
    echo "Table created."
fi

echo "Backend infrastructure setup complete."
