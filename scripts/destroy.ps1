# Destroys all AWS resources created by scripts/deploy.ps1.
$ErrorActionPreference = 'Stop'
$infraDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'infra'

terraform "-chdir=$infraDir" init -input=false
if ($LASTEXITCODE -ne 0) { throw 'terraform init failed' }
terraform "-chdir=$infraDir" destroy -auto-approve -input=false
if ($LASTEXITCODE -ne 0) { throw 'terraform destroy failed' }
