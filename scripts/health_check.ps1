# Checks the health of the deployed AWS services (ALB, target group, EC2, RDS) and the request path through them.
# Usage: .\health_check.ps1 [-Wait]   (-Wait retries for up to 5 minutes while EC2 bootstraps)
param([switch]$Wait)

$ErrorActionPreference = 'Stop'
cd (Split-Path -Parent $PSScriptRoot)

$project = if ($env:PROJECT_NAME) { $env:PROJECT_NAME } else { 'anitracker' }
$timeout = if ($Wait) { 300 } else { 0 }

aws sts get-caller-identity *> $null
if ($LASTEXITCODE -ne 0) {
    throw 'AWS credentials missing or expired. Paste fresh Learner Lab credentials (AWS Details > AWS CLI) into ~/.aws/credentials.'
}

$siteUrl = terraform -chdir=infra output -raw site_url
if ($LASTEXITCODE -ne 0) { throw 'Could not read site_url. Has the infrastructure been deployed?' }

$script:failed = $false

# Runs the test (retrying until $timeout) and prints PASS/FAIL. A test passes when it returns $true.
function Test-Check {
    param([string]$Label, [scriptblock]$Test)

    $deadline = (Get-Date).AddSeconds($timeout)

    while ($true) {
        try { 
            $ok = [bool](& $Test) 
        } catch { 
            $ok = $false 
        }

        if ($ok) { 
            Write-Host "PASS  $Label"; 
            return 
        }

        if ((Get-Date) -ge $deadline) { 
            Write-Host "FAIL  $Label"; 
            $script:failed = $true; 
            return 
        }
        
        Start-Sleep -Seconds 10
    }
}

function Test-Http {
    param([string]$Path)
    (Invoke-WebRequest -Uri "$siteUrl$Path" -UseBasicParsing -TimeoutSec 10).StatusCode -eq 200
}

Write-Host "Health check for $project ($siteUrl)"

Test-Check "ALB $project-alb is active" {
    (aws elbv2 describe-load-balancers --names "$project-alb" --query 'LoadBalancers[0].State.Code' --output text) -eq 'active'
}

Test-Check "Target group $project-web-tg targets are healthy" {
    $arn = aws elbv2 describe-target-groups --names "$project-web-tg" --query 'TargetGroups[0].TargetGroupArn' --output text
    $states = @(aws elbv2 describe-target-health --target-group-arn $arn --query 'TargetHealthDescriptions[].TargetHealth.State' --output text) -split '\s+' | Where-Object { $_ }
    $states.Count -gt 0 -and -not ($states | Where-Object { $_ -ne 'healthy' })
}

foreach ($role in 'web', 'api') {
    Test-Check "$($role.ToUpper()) EC2 instance is running with status checks ok" {
        # describe-instance-status has no tag filters, so resolve the instance ID first.
        $id = aws ec2 describe-instances --filters "Name=tag:Name,Values=$project-$role" 'Name=instance-state-name,Values=running' --query 'Reservations[0].Instances[0].InstanceId' --output text
        $status = aws ec2 describe-instance-status --instance-ids $id --query 'InstanceStatuses[0].[InstanceStatus.Status,SystemStatus.Status]' --output text
        ($status -split '\s+') -join ' ' -eq 'ok ok'
    }.GetNewClosure()
}

Test-Check "RDS $project-db is available" {
    (aws rds describe-db-instances --db-instance-identifier "$project-db" --query 'DBInstances[0].DBInstanceStatus' --output text) -eq 'available'
}

Test-Check 'GET / returns 200 via ALB' { Test-Http '/' }
Test-Check 'GET /api/anime returns 200 via ALB' { Test-Http '/api/anime' }

# /api/health runs SELECT 1 against RDS inside the API, so it proves ALB -> web -> API -> RDS.
Test-Check 'GET /api/health reports database connected' {
    (Invoke-WebRequest -Uri "$siteUrl/api/health" -UseBasicParsing -TimeoutSec 10).Content -match '"ok"'
}

Write-Host ''
if ($script:failed) {
    Write-Host 'One or more checks failed.'
    exit 1
}
Write-Host 'All checks passed.'
