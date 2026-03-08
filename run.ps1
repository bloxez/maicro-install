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

# Create update script
$updateScript = @'
# mAIcro Update Script - Pull latest image and restart container

$ErrorActionPreference = "Stop"

$Image = "bloxez/maicro-g2a:latest"
$ContainerName = "maicro"
$Port = if ($env:MAICRO_PORT) { $env:MAICRO_PORT } else { 4321 }
$AppDataDir = Join-Path $PSScriptRoot "data"

Write-Host "🔍 Checking for updates..."

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
    "--restart", "unless-stopped"
)

if ($OpenRouterKey) {
    $dockerArgs += @("-e", "OPENROUTER_API_KEY=$OpenRouterKey")
}

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
    "--restart", "unless-stopped"
)

if ($OpenRouterKey) {
    $dockerArgs += @("-e", "OPENROUTER_API_KEY=$OpenRouterKey")
}

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
    Write-Host "  Stop:    " -NoNewline; Write-Host "docker stop maicro" -ForegroundColor Yellow
    Write-Host "  Start:   " -NoNewline; Write-Host "docker start maicro" -ForegroundColor Yellow
    Write-Host "  Logs:    " -NoNewline; Write-Host "docker logs -f maicro" -ForegroundColor Yellow
    Write-Host "  Remove:  " -NoNewline; Write-Host "docker rm -f maicro" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "❌ Failed to start mAIcro" -ForegroundColor Red
    Write-Host "Check logs with: docker logs $ContainerName"
    exit 1
}
