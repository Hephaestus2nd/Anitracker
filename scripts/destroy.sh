#!/usr/bin/env bash
# Destroys all AWS resources created by scripts/deploy.sh.
set -euo pipefail

cd "$(dirname "$0")/.."

terraform -chdir=infra init -input=false
terraform -chdir=infra destroy -auto-approve -input=false
