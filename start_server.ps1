$ErrorActionPreference = "Stop"

$projectRoot = Get-Location
$otaDir = "$projectRoot\ota_server"

# Ensure OTA directory exists
if (-not (Test-Path $otaDir)) {
    Write-Error "OTA Server directory not found! Please run deploy_update.ps1 first to create a release."
    exit 1
}

Write-Host "Starting OTA Server..." -ForegroundColor Cyan
Write-Host "Hosting files from: $otaDir" -ForegroundColor Gray
Write-Host "Server URL: http://<YOUR_PC_IP>:8000" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop server." -ForegroundColor Yellow

Set-Location $otaDir
python -m http.server 8000
