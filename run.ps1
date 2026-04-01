# mAIcro Quick Start Script (Windows PowerShell)
# Usage: irm https://raw.githubusercontent.com/bloxez/maicro-install/main/run.ps1 | iex
#    or: & ([scriptblock]::Create((irm https://raw.githubusercontent.com/bloxez/maicro-install/main/run.ps1))) -DataDir "C:\maicro-data"

param(
    [string]$DataDir = "$env:USERPROFILE\maicro-data",
    [int]$Port = 4321
)

# Configuration
$Image = "bloxez/maicro-g2a:latest"
$ContainerName = "maicro"

Write-Host ""
Write-Host "  ███╗   ███╗ █████╗ ██╗ ██████╗██████╗  ██████╗ " -ForegroundColor Cyan
Write-Host "  ████╗ ████║██╔══██╗██║██╔════╝██╔══██╗██╔═══██╗" -ForegroundColor Cyan
Write-Host "  ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║" -ForegroundColor Cyan
Write-Host "  ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║" -ForegroundColor Cyan
Write-Host "  ██║ ╚═╝ ██║██║  ██║██║╚██████╗██║  ██║╚██████╔╝" -ForegroundColor Cyan
Write-Host "  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ " -ForegroundColor Cyan
Write-Host ""
Write-Host "  GraphQL-first rapid prototyping platform" -ForegroundColor White
Write-Host ""

# Check Docker is installed
try {
    $null = Get-Command docker -ErrorAction Stop
} catch {
    Write-Host "❌ Docker is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Docker Desktop from:"
    Write-Host "  https://www.docker.com/products/docker-desktop"
    Write-Host ""
    exit 1
}

# Check Docker is running
$dockerInfo = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker is not running." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start Docker Desktop and try again."
    Write-Host ""
    exit 1
}

Write-Host "✅ Docker is running" -ForegroundColor Green

# Resolve to absolute path
$DataDir = [System.IO.Path]::GetFullPath($DataDir)
$AppDataDir = Join-Path $DataDir "data"

# Create data directory
Write-Host "📁 Data directory: $DataDir" -ForegroundColor Yellow
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}
if (-not (Test-Path $AppDataDir)) {
    New-Item -ItemType Directory -Path $AppDataDir -Force | Out-Null
}
if (-not (Test-Path "$DataDir\config")) {
    New-Item -ItemType Directory -Path "$DataDir\config" -Force | Out-Null
}

# Create platform config file
$configContent = @'
{
  "Label": "mAIcro Default Configuration",

  "rootKey": "{{ ROOT_KEY }}",
  "rootUser": "{{ ROOT_USER }}",

  "defaultProject": "{{ MAICRO_DEFAULT_PROJECT }}",
  "maicroAdminKey": "{{ MAICRO_ADMIN_KEY }}",

  "McpEnabled": true,
  "ApiPort": 3456,

  "PlatformAdmin": "platform_admin@maicro.ai",
  "Admin1": "admin1@maicro.ai",
  "Admin2": "admin2@maicro.ai",
  "TestUser1": "maicro1@maicro.ai",
  "TestUser2": "maicro2@maicro.ai",
  "AuthProvider": "internal",
  "AuthProviderFallback": null,
  
  "Auth": [
    {
      "id": "internal",
      "provider": "internal",
      "audience": "https://dev.maicro.app",
      "issuer": "https://dev.maicro.app",
      "tokenExpiration": "24h"
    }
  ],
  
  "Security": {
    "allowedOrigins": ["*"],
    "corsCredentials": true,
    "hstsMaxAge": 31536000,
    "hstsIncludeSubdomains": true,
    "referrerPolicy": "strict-origin-when-cross-origin",
    "xFrameOptions": "DENY",
    "cspPolicy": "default-src 'self' data: blob:; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net https://unpkg.com https://cdn.skypack.dev; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://unpkg.com; img-src 'self' data: blob: https:; font-src 'self' data: https://cdn.jsdelivr.net https://unpkg.com; connect-src 'self' https: wss: ws: data:; worker-src 'self' blob:'"
  },
  
  "Database": {
    "schema": "maicro",
    "connection": "postgresql://maicro:{{POSTGRES_PASSWORD}}@localhost:5432/maicrodb",
    "idType": "UUID",
    "idField": "id",
    "idSuffix": "_id",
    "extensions": ["vector", "uuid-ossp", "hstore", "pg_trgm", "btree_gin", "unaccent"]
  },

  "Otel": {
    "endpoint": "http://localhost:4318",
    "protocol": "http/protobuf",
    "serviceName": "maicro"
  },
  
  "ProjectRoot": "/app",
  "RuntimeDataFolder": "/app/runtime/userdata",
  "TestInputFolder": "/app/test_input",
  "TestOutputFolder": "/app/output",
  "TmpFolder": "/app/tmp",
  "DocsOutputFolder": "/app/tmp/docs",
  "LogFolder": "/app/data/logs",
  
  "NoAdminResolvers": null,
  "DbSchemaLock": null,
  "DbUseCachedSchema": null,
  "Jwt": null,
  "JwtSigningKey": null,
  
  "RandomApiPort": null,

  "TraceLevel": "INFO",
  "UnitTest": null
}
'@

Set-Content -Path "$DataDir\config\config.platform.json" -Value $configContent -Force

# Create update script
$updateScript = @'
# mAIcro Update Script - Pull latest image and restart container

$ErrorActionPreference = "Stop"

$Image = "bloxez/maicro-g2a:latest"
$ContainerName = "maicro"
$Port = if ($env:MAICRO_PORT) { $env:MAICRO_PORT } else { 4321 }
$AppDataDir = Join-Path $PSScriptRoot "data"
$ConfigPath = Join-Path $PSScriptRoot "config" "config.platform.json"

Write-Host "🔍 Checking for updates..."

# Verify config exists
if (-not (Test-Path $ConfigPath)) {
    Write-Host "ERROR: Config file not found at $ConfigPath" -ForegroundColor Red
    Write-Host "Please create the config file or re-run the initial installation." -ForegroundColor Red
    exit 1
}

# Get current image digest
$currentDigest = docker inspect --format='{{.Image}}' $ContainerName 2>$null
if (-not $currentDigest) { $currentDigest = "" }

# Pull latest
Write-Host "📦 Pulling latest image..."
docker pull $Image

# Get new image digest
$newDigest = docker inspect --format='{{.Id}}' $Image 2>$null

if ($currentDigest -eq $newDigest) {
    Write-Host "✅ Already on latest version" -ForegroundColor Green
    exit 0
}

Write-Host "🔄 New version available, updating..." -ForegroundColor Yellow

# Stop and remove old container
docker stop $ContainerName 2>$null | Out-Null
docker rm $ContainerName 2>$null | Out-Null

# Get OpenRouter API key from environment if set
$OpenRouterKey = $env:OPENROUTER_API_KEY

# Restart with same settings
Write-Host "🚀 Starting updated container..."
$dockerArgs = @(
    "run", "-d",
    "--name", $ContainerName,
    "-p", "${Port}:3456",
    "-v", "${PSScriptRoot}:/app/runtime/userdata",
    "-v", "${AppDataDir}:/app/data",
    "-e", "CONFIG_PATH=/app/runtime/userdata/config/config.platform.json",
    "--restart", "unless-stopped"
)

if ($OpenRouterKey) {
    $dockerArgs += @("-e", "OPENROUTER_API_KEY=$OpenRouterKey")
}

# Add project authentication and root management variables
$DockerDefaultProject = if ($env:MAICRO_DEFAULT_PROJECT) { $env:MAICRO_DEFAULT_PROJECT } else { "maicro" }
$DockerAdminKey = if ($env:MAICRO_ADMIN_KEY) { $env:MAICRO_ADMIN_KEY } else { "" }
$DockerRootUser = if ($env:ROOT_USER) { $env:ROOT_USER } else { "" }
$DockerRootKey = if ($env:ROOT_KEY) { $env:ROOT_KEY } else { "" }

$dockerArgs += @("-e", "MAICRO_DEFAULT_PROJECT=$DockerDefaultProject")
if ($DockerAdminKey) { $dockerArgs += @("-e", "MAICRO_ADMIN_KEY=$DockerAdminKey") }
if ($DockerRootUser) { $dockerArgs += @("-e", "ROOT_USER=$DockerRootUser") }
if ($DockerRootKey) { $dockerArgs += @("-e", "ROOT_KEY=$DockerRootKey") }

$dockerArgs += $Image
docker @dockerArgs | Out-Null

Start-Sleep -Seconds 2

$running = docker ps -q -f "name=$ContainerName"
if ($running) {
    Write-Host "✅ Update complete!" -ForegroundColor Green
    Write-Host "🌐 mAIcro: http://localhost:${Port}/ide" -ForegroundColor Cyan
} else {
    Write-Host "❌ Failed to start updated container" -ForegroundColor Red
    docker logs $ContainerName
    exit 1
}
'@

$updateScriptPath = Join-Path $DataDir "update.ps1"
Set-Content -Path $updateScriptPath -Value $updateScript -Force

# Create remove script
$removeScript = @'
# mAIcro Remove Script - Remove container and optionally remove persisted data

$ErrorActionPreference = "Stop"

$ContainerName = "maicro"
$DataDir = $PSScriptRoot

Write-Host "⚠️  This will remove the mAIcro container: $ContainerName" -ForegroundColor Yellow
$confirmContainer = Read-Host "Remove container now? [y/N]"

if ($confirmContainer -notin @("y", "Y", "yes", "YES")) {
    Write-Host "Cancelled."
    exit 0
}

Write-Host "🛑 Stopping and removing container..."
docker stop $ContainerName 2>$null | Out-Null
docker rm $ContainerName 2>$null | Out-Null

Write-Host "✅ Container removed (or was not present)." -ForegroundColor Green
Write-Host ""
Write-Host "Persisted data directory: $DataDir"
$confirmData = Read-Host "Also remove persisted data from host? [y/N]"

if ($confirmData -in @("y", "Y", "yes", "YES")) {
    Write-Host "🗑️  Removing persisted data..."
    Get-ChildItem -Path $DataDir -Force |
        Where-Object { $_.Name -notin @("update.ps1", "remove.ps1") } |
        Remove-Item -Recurse -Force
    Write-Host "✅ Persisted data removed." -ForegroundColor Green
} else {
    Write-Host "Data kept at: $DataDir"
}
'@

$removeScriptPath = Join-Path $DataDir "remove.ps1"
Set-Content -Path $removeScriptPath -Value $removeScript -Force

# Stop and remove existing container if it exists
$existing = docker ps -aq -f "name=$ContainerName" 2>$null
if ($existing) {
    Write-Host "🛑 Stopping existing mAIcro container..." -ForegroundColor Yellow
    docker stop $ContainerName 2>$null | Out-Null
    docker rm $ContainerName 2>$null | Out-Null
}

# Pull latest image
Write-Host "📦 Pulling mAIcro image..." -ForegroundColor Yellow
docker pull $Image

# Get OpenRouter API key from environment if set
$OpenRouterKey = $env:OPENROUTER_API_KEY

# Run container
Write-Host "🚀 Starting mAIcro..." -ForegroundColor Yellow
$dockerArgs = @(
    "run", "-d",
    "--name", $ContainerName,
    "-p", "${Port}:3456",
    "-v", "${DataDir}:/app/runtime/userdata",
    "-v", "${AppDataDir}:/app/data",
    "-e", "CONFIG_PATH=/app/runtime/userdata/config/config.platform.json",
    "--restart", "unless-stopped"
)

if ($OpenRouterKey) {
    $dockerArgs += @("-e", "OPENROUTER_API_KEY=$OpenRouterKey")
}

# Add project authentication and root management variables
$DockerDefaultProject = if ($env:MAICRO_DEFAULT_PROJECT) { $env:MAICRO_DEFAULT_PROJECT } else { "maicro" }
$DockerAdminKey = if ($env:MAICRO_ADMIN_KEY) { $env:MAICRO_ADMIN_KEY } else { "" }
$DockerRootUser = if ($env:ROOT_USER) { $env:ROOT_USER } else { "" }
$DockerRootKey = if ($env:ROOT_KEY) { $env:ROOT_KEY } else { "" }

$dockerArgs += @("-e", "MAICRO_DEFAULT_PROJECT=$DockerDefaultProject")
if ($DockerAdminKey) { $dockerArgs += @("-e", "MAICRO_ADMIN_KEY=$DockerAdminKey") }
if ($DockerRootUser) { $dockerArgs += @("-e", "ROOT_USER=$DockerRootUser") }
if ($DockerRootKey) { $dockerArgs += @("-e", "ROOT_KEY=$DockerRootKey") }

$dockerArgs += $Image

docker @dockerArgs | Out-Null

# Wait for startup
Write-Host "⏳ Waiting for mAIcro to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Check if running
$running = docker ps -q -f "name=$ContainerName"
if ($running) {
    Write-Host ""
    Write-Host "✅ mAIcro is running!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  🌐 IDE:      " -NoNewline; Write-Host "http://localhost:${Port}/ide" -ForegroundColor Cyan
    Write-Host "  📊 GraphQL:  " -NoNewline; Write-Host "http://localhost:${Port}/graphql" -ForegroundColor Cyan
    Write-Host "  📁 Data:     $DataDir"
    Write-Host "  🗄️  DB Data:  $AppDataDir"
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor White
    Write-Host "  Update:  " -NoNewline; Write-Host "powershell $DataDir\update.ps1" -ForegroundColor Yellow
    Write-Host "  Remove:  " -NoNewline; Write-Host "powershell $DataDir\remove.ps1" -ForegroundColor Yellow
    Write-Host "  Stop:    " -NoNewline; Write-Host "docker stop maicro" -ForegroundColor Yellow
    Write-Host "  Start:   " -NoNewline; Write-Host "docker start maicro" -ForegroundColor Yellow
    Write-Host "  Logs:    " -NoNewline; Write-Host "docker logs -f maicro" -ForegroundColor Yellow
    Write-Host "  Force Remove: " -NoNewline; Write-Host "docker rm -f maicro" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "❌ Failed to start mAIcro" -ForegroundColor Red
    Write-Host "Check logs with: docker logs $ContainerName"
    exit 1
}
