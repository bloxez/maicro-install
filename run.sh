#!/bin/sh

# mAIcro Quick Start Script (macOS / Linux / WSL)
# Usage: curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh
#    or: curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh -s -- /path/to/data

set -e

# Configuration
IMAGE="bloxez/maicro-g2a:0.1.0-alpha.1"
CONTAINER_NAME="maicro"
PORT="${MAICRO_PORT:-4321}"
DEFAULT_DATA_DIR="$HOME/maicro-data"

# Colors (using printf for POSIX compatibility)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

printf "${CYAN}"
echo "               _    ___                 "
echo "   _ __ ___   / \  |_ _| ___  _ __  ___ "
echo "  | '_ \` _ \ / _ \  | | / __|| '__|/ _ \\"
echo "  | | | | | / ___ \ | || |__ | |  | (_) |"
echo "  |_| |_| |_/_/  \_\___|\___||_|   \___/"
echo ""
printf "${NC}"
echo ""
echo "  mAIcro:G2A - Your gateway to anything"
echo ""

# Parse arguments
DATA_DIR="${1:-$DEFAULT_DATA_DIR}"

# Check Docker is installed
if ! command -v docker > /dev/null 2>&1; then
    printf "${RED}❌ Docker is not installed.${NC}\n"
    echo ""
    echo "Install Docker:"
    echo "  Linux:       https://docs.docker.com/engine/install/"
    echo "  macOS/Win:   https://www.docker.com/products/docker-desktop"
    echo ""
    exit 1
fi

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    printf "${RED}❌ Docker daemon is not running or you lack permissions.${NC}\n"
    echo ""
    echo "Try one of these:"
    echo "  - Start Docker:          sudo systemctl start docker"
    echo "  - Add user to group:     sudo usermod -aG docker \$USER && newgrp docker"
    echo "  - Start Docker Desktop:  (macOS/Windows)"
    echo ""
    exit 1
fi

printf "${GREEN}✅ Docker is running${NC}\n"

# Resolve to absolute path
DATA_DIR=$(cd "$(dirname "$DATA_DIR")" 2>/dev/null && pwd)/$(basename "$DATA_DIR") || DATA_DIR="$DEFAULT_DATA_DIR"

# Create data directory
printf "${YELLOW}📁 Data directory: ${DATA_DIR}${NC}\n"
mkdir -p "$DATA_DIR"

# Stop existing container if running
if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
    printf "${YELLOW}🛑 Stopping existing mAIcro container...${NC}\n"
    docker stop "$CONTAINER_NAME" > /dev/null
    docker rm "$CONTAINER_NAME" > /dev/null
fi

# Pull latest image
printf "${YELLOW}📦 Pulling mAIcro image...${NC}\n"
docker pull "$IMAGE"

# Run container
printf "${YELLOW}🚀 Starting mAIcro...${NC}\n"
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "${PORT}:3456" \
    -v "${DATA_DIR}:/app/runtime/userdata" \
    -e "OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-}" \
    --add-host=host.docker.internal:host-gateway \
    --restart unless-stopped \
    "$IMAGE" > /dev/null

# Wait for startup
printf "${YELLOW}⏳ Waiting for mAIcro to start...${NC}\n"
sleep 3

# Check if running
if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
    echo ""
    printf "${GREEN}✅ mAIcro is running!${NC}\n"
    echo ""
    printf "  🌐 IDE:      ${CYAN}http://localhost:${PORT}/ide${NC}\n"
    printf "  📊 GraphQL:  ${CYAN}http://localhost:${PORT}/graphql${NC}\n"
    echo "  📁 Data:     ${DATA_DIR}"
    echo ""
    echo "Commands:"
    printf "  Stop:    ${YELLOW}docker stop maicro${NC}\n"
    printf "  Start:   ${YELLOW}docker start maicro${NC}\n"
    printf "  Logs:    ${YELLOW}docker logs -f maicro${NC}\n"
    printf "  Remove:  ${YELLOW}docker rm -f maicro${NC}\n"
    echo ""
else
    printf "${RED}❌ Failed to start mAIcro${NC}\n"
    echo "Check logs with: docker logs $CONTAINER_NAME"
    exit 1
fi
