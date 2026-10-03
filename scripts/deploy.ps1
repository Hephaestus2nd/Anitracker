# Provisions AWS infrastructure with Terraform; EC2 builds the pinned repository during bootstrap.
$ErrorActionPreference = 'Stop'
$infraDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'infra'

function Invoke-Checked {
    param([scriptblock]$Command)
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "Command failed with exit code $LASTEXITCODE" }
}

aws sts get-caller-identity *> $null

if ($LASTEXITCODE -ne 0) {
    throw 'AWS credentials missing or expired. Paste fresh Learner Lab credentials (AWS Details > AWS CLI) into ~/.aws/credentials.'
}

Write-Host '==> Applying Terraform'
Invoke-Checked { terraform "-chdir=$infraDir" init -input=false }
Invoke-Checked { terraform "-chdir=$infraDir" apply -auto-approve -input=false }

$siteUrl = terraform "-chdir=$infraDir" output -raw site_url
Write-Host ''
Write-Host "Deployed: $siteUrl"
Write-Host 'Note: the ALB and EC2 bootstrap can take several minutes to become fully available.'
