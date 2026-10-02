#!/usr/bin/env bash
# Builds the backend and frontend, then provisions/updates all AWS infrastructure with Terraform.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "AWS credentials missing or expired. Paste fresh Learner Lab credentials (AWS Details > AWS CLI) into ~/.aws/credentials." >&2
    exit 1
fi

echo "==> Building backend"
chmod +x gradlew
./gradlew clean distZip

echo "==> Building frontend"
(cd frontend && npm ci && npm run build)

echo "==> Applying Terraform"
terraform -chdir=infra init -input=false
terraform -chdir=infra apply -auto-approve -input=false

echo "==> Invalidating CloudFront cache"
DIST_ID="$(terraform -chdir=infra output -raw cloudfront_distribution_id)"
aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths "/*" >/dev/null

echo
echo "Deployed: $(terraform -chdir=infra output -raw site_url)"
echo "Note: a new CloudFront distribution and API bootstrap can take ~5-15 minutes to become fully available."
