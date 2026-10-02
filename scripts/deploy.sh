#!/usr/bin/env bash
# Provisions AWS infrastructure with Terraform; EC2 builds the pinned repository during bootstrap.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "AWS credentials missing or expired. Paste fresh Learner Lab credentials (AWS Details > AWS CLI) into ~/.aws/credentials." >&2
    exit 1
fi

echo "==> Applying Terraform"
terraform -chdir=infra init -input=false
terraform -chdir=infra apply -auto-approve -input=false

echo
echo "Deployed: $(terraform -chdir=infra output -raw site_url)"
echo "Note: the ALB and EC2 bootstrap can take several minutes to become fully available."
