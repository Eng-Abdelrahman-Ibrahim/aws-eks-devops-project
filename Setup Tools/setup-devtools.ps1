# --------------------------------------------------
# setup-devtools.ps1
# Installs AWS CLI, Git, and Terraform on Windows
# --------------------------------------------------

$ErrorActionPreference = "Stop"
Write-Host "Starting setup..." -ForegroundColor Cyan

# ----------------------------
# 1. Install AWS CLI
# ----------------------------
Write-Host "Installing AWS CLI..." -ForegroundColor Green
$awsInstaller = "$env:TEMP\AWSCLIV2.msi"
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $awsInstaller
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$awsInstaller`" /qn"
Remove-Item $awsInstaller
Write-Host "AWS CLI version:" -ForegroundColor Yellow
aws --version

# ----------------------------
# 2. Install Git
# ----------------------------
Write-Host "Installing Git..." -ForegroundColor Green
$gitInstaller = "$env:TEMP\GitSetup.exe"
Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.51.0.windows.1/Git-2.51.0-64-bit.exe" -OutFile $gitInstaller
Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
Remove-Item $gitInstaller
Write-Host "Git version:" -ForegroundColor Yellow
git --version

# ----------------------------
# 3. Install Terraform
# ----------------------------
Write-Host "Installing Terraform..." -ForegroundColor Green
$terraformZip = "$env:TEMP\terraform.zip"
Invoke-WebRequest -Uri "https://releases.hashicorp.com/terraform/1.13.1/terraform_1.13.1_windows_amd64.zip" -OutFile $terraformZip

# Extract to Program Files
$terraformPath = "$env:ProgramFiles\Terraform"
if (-Not (Test-Path $terraformPath)) { New-Item -ItemType Directory -Path $terraformPath }
Expand-Archive -Path $terraformZip -DestinationPath $terraformPath -Force
Remove-Item $terraformZip

# Add Terraform to PATH
$envPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
if (-Not $envPath.Contains($terraformPath)) {
    [System.Environment]::SetEnvironmentVariable("Path", "$envPath;$terraformPath", [System.EnvironmentVariableTarget]::Machine)
}

# Reload environment variables for current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
Write-Host "Terraform version:" -ForegroundColor Yellow
terraform -version

Write-Host "Setup complete! AWS CLI, Git, and Terraform are installed." -ForegroundColor Cyan
