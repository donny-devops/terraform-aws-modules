<#
.SYNOPSIS
    Automated bootstrap script to provision Terraform remote state storage (S3 + DynamoDB)
    and configure environment backend.tf files.

.DESCRIPTION
    1. Verifies AWS CLI authentication and Terraform availability.
    2. Initializes and applies the bootstrap Terraform configuration.
    3. Extracts the generated S3 bucket and DynamoDB table names.
    4. Auto-generates backend.tf configurations for dev and prod environments.

.PARAMETER Region
    AWS Region to deploy the state backend (default: us-east-1).

.PARAMETER BucketPrefix
    Name prefix for the state bucket and locking table (default: tf-state).
#>

[CmdletBinding()]
param (
    [string]$Region = "us-east-1",
    [string]$BucketPrefix = "tf-state",
    [switch]$SkipBackendFileGen
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Terraform AWS Remote State & Lock Table Bootstrapper " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Preflight checks
Write-Host "[1/4] Running preflight credential and tool checks..." -ForegroundColor Yellow

if (-not (Get-Command "terraform" -ErrorAction SilentlyContinue)) {
    Write-Warning "Terraform CLI was not found on PATH. Please install Terraform (e.g., winget install HashiCorp.Terraform) to run this script."
    exit 1
}

if (Get-Command "aws" -ErrorAction SilentlyContinue) {
    try {
        $callerIdentity = aws sts get-caller-identity --output json | ConvertFrom-Json
        Write-Host "  Authenticated as AWS Principal: $($callerIdentity.Arn)" -ForegroundColor Green
    }
    catch {
        Write-Warning "AWS CLI is present, but active credentials could not be verified. Ensure AWS_ACCESS_KEY_ID or AWS_PROFILE is set."
    }
} else {
    Write-Host "  Note: AWS CLI not detected on PATH. Terraform will rely on local environment variables or EC2/SSO provider credentials." -ForegroundColor Gray
}

# 2. Terraform Init
Write-Host "`n[2/4] Initializing Terraform in bootstrap directory..." -ForegroundColor Yellow
$bootstrapDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Push-Location $bootstrapDir
try {
    terraform init -input=false

    # 3. Terraform Apply
    Write-Host "`n[3/4] Provisioning S3 State Bucket and DynamoDB Lock Table..." -ForegroundColor Yellow
    terraform apply -auto-approve `
        -var="aws_region=$Region" `
        -var="bucket_prefix=$BucketPrefix" `
        -input=false

    # Extract outputs
    $outputsJson = terraform output -json | ConvertFrom-Json
    $bucketName = $outputsJson.s3_bucket_name.value
    $tableName  = $outputsJson.dynamodb_table_name.value

    Write-Host "`nSUCCESS: State resources provisioned successfully!" -ForegroundColor Green
    Write-Host "  S3 State Bucket:    $bucketName" -ForegroundColor Cyan
    Write-Host "  DynamoDB Lock Table: $tableName" -ForegroundColor Cyan

    # 4. Generate environment backend.tf files
    if (-not $SkipBackendFileGen) {
        Write-Host "`n[4/4] Generating backend.tf files for environments..." -ForegroundColor Yellow
        $rootDir = Split-Path -Parent $bootstrapDir
        $environments = @("dev", "prod")

        foreach ($env in $environments) {
            $envDir = Join-Path $rootDir "environments\$env"
            if (Test-Path $envDir) {
                $backendFilePath = Join-Path $envDir "backend.tf"
                $backendContent = @"
# Generated automatically by bootstrap-backend.ps1
terraform {
  backend "s3" {
    bucket         = "$bucketName"
    key            = "platform/$env/terraform.tfstate"
    region         = "$Region"
    dynamodb_table = "$tableName"
    encrypt        = true
  }
}
"@
                Set-Content -Path $backendFilePath -Value $backendContent -Encoding UTF8
                Write-Host "  Created: $backendFilePath" -ForegroundColor Green
            }
        }
    }

    Write-Host "`nBootstrap Complete! You can now run 'terraform init' in environments/dev or environments/prod." -ForegroundColor Green
}
finally {
    Pop-Location
}
