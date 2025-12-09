$ErrorActionPreference = "Stop"

$projectRoot = Get-Location
$otaDir = "$projectRoot\ota_server"
$metadataFile = "$otaDir\metadata.json"
$buildPath = "$projectRoot\build\app\outputs\flutter-apk\app-release.apk"

# Ensure OTA directory exists
if (-not (Test-Path $otaDir)) {
    New-Item -ItemType Directory -Path $otaDir | Out-Null
}

# 1. Build APK
Write-Host "Step 1: Building Release APK..." -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed."
    exit 1
}

# 2. Extract Version from pubspec.yaml
Write-Host "Step 2: Extracting Version..." -ForegroundColor Cyan
$pubspec = Get-Content "$projectRoot\pubspec.yaml"
$versionLine = $pubspec | Select-String "version:" | Select-Object -First 1
# Split version: 1.0.0+1 -> 1.0.0
$rawVersion = $versionLine.ToString().Split(":")[1].Trim()
$version = $rawVersion.Split("+")[0]
Write-Host "Detected Version: $version" -ForegroundColor Green

# 3. Calculate Hash
Write-Host "Step 3: Calculating SHA-256 Checksum..." -ForegroundColor Cyan
$hash = (Get-FileHash $buildPath -Algorithm SHA256).Hash
Write-Host "Hash: $hash" -ForegroundColor Green

# 4. Move/Copy APK
Write-Host "Step 4: Deploying to OTA Server..." -ForegroundColor Cyan
Copy-Item $buildPath "$otaDir\app-release.apk" -Force

# 5. Update metadata.json
Write-Host "Step 5: Updating Metadata..." -ForegroundColor Cyan
$metadata = @{
    version = $version
    apkUrl = "app-release.apk"
    hash = $hash
    releaseNotes = "Automated release $version"
}

# Convert to JSON with pretty print (if available in PS version, otherwise default)
$jsonContent = $metadata | ConvertTo-Json -Depth 2
# Use .NET class to write UTF8 WITHOUT BOM
[System.IO.File]::WriteAllText($metadataFile, $jsonContent)

Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "Starting HTTP Server in $otaDir on port 8000..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop server." -ForegroundColor Yellow

Set-Location $otaDir
python -m http.server 8000
