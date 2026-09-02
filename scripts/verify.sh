#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

status_output=$(vagrant status --machine-readable)
for vm in frontend api db; do
  if ! grep -q ",${vm},state,running" <<< "$status_output"; then
    echo "VM '${vm}' is not running" >&2
    exit 1
  fi
done

echo "All VMs are running."

# Verifies a request path that touches all three VMs:
# frontend VM initiates request to API VM, which reads Postgres on DB VM.
vagrant ssh frontend -c "curl -fsS 'http://10.10.10.11:8080/api/movies?sort=title' | grep -q 'title'"

echo "Cross-VM movie interaction succeeded."

curl -fsS http://localhost:8081/ >/dev/null

echo "Frontend is reachable at http://localhost:8081"
