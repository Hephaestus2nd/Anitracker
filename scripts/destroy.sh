#!/usr/bin/env bash
# Destroys all AWS resources created by scripts/deploy.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Terraform reads these files during plan even when destroying, so make sure they exist.
mkdir -p build/distributions frontend/dist
[ -f build/distributions/anitracker-1.0.0.zip ] || touch build/distributions/anitracker-1.0.0.zip

terraform -chdir=infra init -input=false
terraform -chdir=infra destroy -auto-approve -input=false
