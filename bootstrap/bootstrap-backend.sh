#!/usr/bin/env bash
# ==============================================================================
# Automated bootstrap script to provision Terraform remote state storage (S3 + DynamoDB)
# and configure environment backend.tf files.
# ==============================================================================
set -euo pipefail

REGION="${1:-us-east-1}"
BUCKET_PREFIX="${2:-tf-state}"

echo "=========================================================="
echo " Terraform AWS Remote State & Lock Table Bootstrapper "
echo "=========================================================="

echo "[1/4] Checking tools and AWS credentials..."
if ! command -v terraform &> /dev/null; then
    echo "ERROR: terraform command not found on PATH. Please install Terraform before continuing." >&2
    exit 1
fi

if command -v aws &> /dev/null; then
    if caller_identity=$(aws sts get-caller-identity --output json 2>/dev/null); then
        arn=$(echo "$caller_identity" | grep -o '"Arn": "[^"]*' | cut -d'"' -f4)
        echo "  Authenticated as AWS Principal: $arn"
    else
        echo "  WARNING: AWS CLI is installed, but could not authenticate with STS."
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo ""
echo "[2/4] Initializing Terraform in bootstrap directory..."
cd "${SCRIPT_DIR}"
terraform init -input=false

echo ""
echo "[3/4] Provisioning S3 State Bucket and DynamoDB Lock Table..."
terraform apply -auto-approve \
    -var="aws_region=${REGION}" \
    -var="bucket_prefix=${BUCKET_PREFIX}" \
    -input=false

BUCKET_NAME=$(terraform output -raw s3_bucket_name)
TABLE_NAME=$(terraform output -raw dynamodb_table_name)

echo ""
echo "SUCCESS: Remote state storage ready:"
echo "  S3 Bucket:     ${BUCKET_NAME}"
echo "  DynamoDB Table: ${TABLE_NAME}"

echo ""
echo "[4/4] Writing backend.tf configurations into environments..."
for ENV in dev prod; do
    ENV_DIR="${ROOT_DIR}/environments/${ENV}"
    if [ -d "${ENV_DIR}" ]; then
        BACKEND_FILE="${ENV_DIR}/backend.tf"
        cat <<EOF > "${BACKEND_FILE}"
# Generated automatically by bootstrap-backend.sh
terraform {
  backend "s3" {
    bucket         = "${BUCKET_NAME}"
    key            = "platform/${ENV}/terraform.tfstate"
    region         = "${REGION}"
    dynamodb_table = "${TABLE_NAME}"
    encrypt        = true
  }
}
EOF
        echo "  Created: ${BACKEND_FILE}"
    fi
done

echo ""
echo "Bootstrap Complete! You can now run 'terraform init' in environments/dev or environments/prod."
