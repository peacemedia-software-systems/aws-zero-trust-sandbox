#!/usr/bin/env bash

# Exit immediately if a command fails
set -euo pipefail

STACK_NAME="${1:-Peacemedia-ZeroTrust-Sandbox}"
TEMPLATE_FILE="zero_trust_sandbox_blueprint.json"

echo "=================================================="
echo " Deploying Peacemedia Zero-Trust Sandbox Stack"
echo " Stack Name: ${STACK_NAME}"
echo " Template:   ${TEMPLATE_FILE}"
echo "=================================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Prompt for required parameters if not set
read -p "Enter Target VPC ID (e.g., vpc-0123456789abcdef0): " VPC_ID
read -p "Enter Target Subnet ID (e.g., subnet-0123456789abcdef0): " SUBNET_ID

echo "Validating CloudFormation template..."
aws cloudformation validate-template --template-body "file://${TEMPLATE_FILE}" > /dev/null

echo "Executing CloudFormation stack creation..."
STACK_ID=$(aws cloudformation create-stack \
  --stack-name "${STACK_NAME}" \
  --template-body "file://${TEMPLATE_FILE}" \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameters \
      ParameterKey=VpcId,ParameterValue="${VPC_ID}" \
      ParameterKey=SubnetId,ParameterValue="${SUBNET_ID}" \
      ParameterKey=EvaluationDurationDays,ParameterValue=30 \
  --query 'StackId' \
  --output text)

echo "Stack creation initiated: ${STACK_ID}"
echo "Waiting for stack deployment to complete..."

# Block until stack creation finishes
aws cloudformation wait stack-create-complete --stack-name "${STACK_NAME}"

echo "=================================================="
echo " SUCCESS: Sandbox environment deployed safely!"
echo "=================================================="

# Display stack outputs (BYOK KMS ARN & Audit Log Stream ARN)
aws cloudformation describe-stacks \
  --stack-name "${STACK_NAME}" \
  --query "Stacks[0].Outputs" \
  --output table
