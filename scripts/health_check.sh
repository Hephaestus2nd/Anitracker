#!/usr/bin/env bash
# Checks the health of the deployed AWS services (ALB, target group, EC2, RDS) and the request path through them.
# Usage: bash health_check.sh [--wait]   (--wait retries for up to 5 minutes while EC2 bootstraps)
set -uo pipefail

cd "$(dirname "$0")/.."

PROJECT="${PROJECT_NAME:-anitracker}"
TIMEOUT=0
[ "${1:-}" = "--wait" ] && TIMEOUT=300

if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "AWS credentials missing or expired. Paste fresh Learner Lab credentials (AWS Details > AWS CLI) into ~/.aws/credentials." >&2
    exit 1
fi

SITE_URL="$(terraform -chdir=infra output -raw site_url 2>/dev/null)" || {
    echo "Could not read site_url. Has the infrastructure been deployed?" >&2
    exit 1
}

failed=0

# check <label> <command...>: runs the command (retrying until TIMEOUT) and prints PASS/FAIL.
check() {
    local label="$1"; shift
    local deadline=$((SECONDS + TIMEOUT))
    
    until "$@" >/dev/null 2>&1; do
        if [ "$SECONDS" -ge "$deadline" ]; then
            echo "FAIL  $label"
            failed=1
            return
        fi
        sleep 10
    done
    echo "PASS  $label"
}

alb_active() {
    [ "$(aws elbv2 describe-load-balancers --names "$PROJECT-alb" \
        --query 'LoadBalancers[0].State.Code' --output text)" = "active" ]
}

targets_healthy() {
    local arn states
    arn="$(aws elbv2 describe-target-groups --names "$PROJECT-web-tg" \
        --query 'TargetGroups[0].TargetGroupArn' --output text)" || return 1
    
    states="$(aws elbv2 describe-target-health --target-group-arn "$arn" \
        --query 'TargetHealthDescriptions[].TargetHealth.State' --output text)"
    
    [ -n "$states" ] && [ "$(echo "$states" | tr '\t' '\n' | sort -u)" = "healthy" ]
}

instance_ok() {
    [ "$(aws ec2 describe-instance-status \
        --filters "Name=tag:Name,Values=$PROJECT-$1" "Name=instance-state-name,Values=running" \
        --query 'InstanceStatuses[0].[InstanceStatus.Status,SystemStatus.Status]' --output text)" = "ok	ok" ]
}

rds_available() {
    [ "$(aws rds describe-db-instances --db-instance-identifier "$PROJECT-db" \
        --query 'DBInstances[0].DBInstanceStatus' --output text)" = "available" ]
}

http_ok() {
    curl -fsS --max-time 10 "$SITE_URL$1" >/dev/null
}

# /api/health runs SELECT 1 against RDS inside the API, so it proves ALB -> web -> API -> RDS.
api_health_ok() {
    curl -fsS --max-time 10 "$SITE_URL/api/health" | grep -q '"ok"'
}

echo "Health check for $PROJECT ($SITE_URL)"
check "ALB $PROJECT-alb is active" alb_active
check "Target group $PROJECT-web-tg targets are healthy" targets_healthy
check "Web EC2 instance is running with status checks ok" instance_ok web
check "API EC2 instance is running with status checks ok" instance_ok api
check "RDS $PROJECT-db is available" rds_available
check "GET / returns 200 via ALB" http_ok /
check "GET /api/anime returns 200 via ALB" http_ok /api/anime
check "GET /api/health reports database connected" api_health_ok

echo
if [ "$failed" -eq 0 ]; then
    echo "All checks passed."
else
    echo "One or more checks failed." >&2
fi
exit "$failed"
