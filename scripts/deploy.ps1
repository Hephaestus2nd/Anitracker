# Builds the backend and frontend, then provisions/updates all AWS infrastructure with Terraform.
$ErrorActionPreference = 'Stop'
cd (Split-Path -Parent $PSScriptRoot)

function Invoke-Checked {
    param([scriptblock]$Command)
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "Command failed with exit code $LASTEXITCODE" }
}

aws sts get-caller-identity *> $null

if ($LASTEXITCODE -ne 0) {
    throw 'AWS credentials missing or expired. Paste fresh Learner Lab credentials (AWS Details > AWS CLI) into ~/.aws/credentials.'
}

Write-Host '==> Building backend'
Invoke-Checked { .\gradlew.bat clean distZip }

Write-Host '==> Building frontend'
Push-Location frontend
try {
    Invoke-Checked { npm ci }
    Invoke-Checked { npm run build }
} finally {
    Pop-Location
}

Write-Host '==> Applying Terraform'
Invoke-Checked { terraform -chdir=infra init -input=false }
Invoke-Checked { terraform -chdir=infra apply -auto-approve -input=false }

Write-Host '==> Invalidating CloudFront cache'
$distId = terraform -chdir=infra output -raw cloudfront_distribution_id
Invoke-Checked { aws cloudfront create-invalidation --distribution-id $distId --paths '/*' | Out-Null }

$siteUrl = terraform -chdir=infra output -raw site_url
Write-Host ''
Write-Host "Deployed: $siteUrl"
Write-Host 'Note: a new CloudFront distribution and API bootstrap can take ~5-15 minutes to become fully available.'
