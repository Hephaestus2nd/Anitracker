# Destroys all AWS resources created by scripts/deploy.ps1.
$ErrorActionPreference = 'Stop'
cd (Split-Path -Parent $PSScriptRoot)

terraform -chdir=infra init -input=false
if ($LASTEXITCODE -ne 0) { throw 'terraform init failed' }
terraform -chdir=infra destroy -auto-approve -input=false
if ($LASTEXITCODE -ne 0) { throw 'terraform destroy failed' }
