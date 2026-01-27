# mAIcro Quick Start Script (Windows PowerShell)
# Usage: irm https://raw.githubusercontent.com/bloxez/maicro-install/main/run.ps1 | iex
#    or: & ([scriptblock]::Create((irm https://raw.githubusercontent.com/bloxez/maicro-install/main/run.ps1))) -DataDir "C:\maicro-data"

param(
    [string]$DataDir = "$env:USERPROFILE\maicro-data",
    [int]$Port = 4321
)

# Configuration
$Image = "bloxez/maicro-g2a:0.1.0-alpha.1"
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

# Create data directory
Write-Host "📁 Data directory: $DataDir" -ForegroundColor Yellow
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

# Stop existing container if running
$existing = docker ps -q -f "name=$ContainerName" 2>$null
if ($existing) {
    Write-Host "🛑 Stopping existing mAIcro container..." -ForegroundColor Yellow
    docker stop $ContainerName | Out-Null
    docker rm $ContainerName | Out-Null
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
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor White
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
