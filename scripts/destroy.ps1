# Destroys all AWS resources created by scripts/deploy.ps1.
$ErrorActionPreference = 'Stop'
cd (Split-Path -Parent $PSScriptRoot)

# Terraform reads these files during plan even when destroying, so make sure they exist.
mkdir -Force build\distributions, frontend\dist | Out-Null
$zip = 'build\distributions\anitracker-1.0.0.zip'
if (-not (Test-Path $zip)) { New-Item -ItemType File $zip | Out-Null }

terraform -chdir=infra init -input=false
if ($LASTEXITCODE -ne 0) { throw 'terraform init failed' }
terraform -chdir=infra destroy -auto-approve -input=false
if ($LASTEXITCODE -ne 0) { throw 'terraform destroy failed' }
