#!/bin/bash

# mAIcro Quick Start Script (macOS / Linux)
# Usage: curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh
#    or: curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh -s -- /path/to/data

set -e

# Configuration
IMAGE="bloxez/maicro-g2a:0.1.0-alpha.1"
CONTAINER_NAME="maicro"
PORT="${MAICRO_PORT:-4321}"
DEFAULT_DATA_DIR="$HOME/maicro-data"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ███╗   ███╗ █████╗ ██╗ ██████╗██████╗  ██████╗ "
echo "  ████╗ ████║██╔══██╗██║██╔════╝██╔══██╗██╔═══██╗"
echo "  ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║"
echo "  ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║"
echo "  ██║ ╚═╝ ██║██║  ██║██║╚██████╗██║  ██║╚██████╔╝"
echo "  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ "
echo -e "${NC}"
echo "  GraphQL-first rapid prototyping platform"
echo ""

# Parse arguments
DATA_DIR="${1:-$DEFAULT_DATA_DIR}"

# Check Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed.${NC}"
    echo ""
    echo "Please install Docker Desktop from:"
    echo "  https://www.docker.com/products/docker-desktop"
    echo ""
    exit 1
fi

# Check Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running.${NC}"
    echo ""
    echo "Please start Docker Desktop and try again."
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Docker is running${NC}"

# Resolve to absolute path
DATA_DIR=$(cd "$(dirname "$DATA_DIR")" 2>/dev/null && pwd)/$(basename "$DATA_DIR") || DATA_DIR="$DEFAULT_DATA_DIR"

# Create data directory
echo -e "${YELLOW}📁 Data directory: ${DATA_DIR}${NC}"
mkdir -p "$DATA_DIR"

# Stop existing container if running
if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
    echo -e "${YELLOW}🛑 Stopping existing mAIcro container...${NC}"
    docker stop "$CONTAINER_NAME" > /dev/null
    docker rm "$CONTAINER_NAME" > /dev/null
fi

# Pull latest image
echo -e "${YELLOW}📦 Pulling mAIcro image...${NC}"
docker pull "$IMAGE"

# Run container
echo -e "${YELLOW}🚀 Starting mAIcro...${NC}"
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "${PORT}:3456" \
    -v "${DATA_DIR}:/app/runtime/userdata" \
    -e "OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-}" \
    --add-host=host.docker.internal:host-gateway \
    --restart unless-stopped \
    "$IMAGE" > /dev/null

# Wait for startup
echo -e "${YELLOW}⏳ Waiting for mAIcro to start...${NC}"
sleep 3

# Check if running
if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
    echo ""
    echo -e "${GREEN}✅ mAIcro is running!${NC}"
    echo ""
    echo -e "  🌐 IDE:      ${CYAN}http://localhost:${PORT}/ide${NC}"
    echo -e "  📊 GraphQL:  ${CYAN}http://localhost:${PORT}/graphql${NC}"
    echo -e "  📁 Data:     ${DATA_DIR}"
    echo ""
    echo -e "Commands:"
    echo -e "  Stop:    ${YELLOW}docker stop maicro${NC}"
    echo -e "  Start:   ${YELLOW}docker start maicro${NC}"
    echo -e "  Logs:    ${YELLOW}docker logs -f maicro${NC}"
    echo -e "  Remove:  ${YELLOW}docker rm -f maicro${NC}"
    echo ""
else
    echo -e "${RED}❌ Failed to start mAIcro${NC}"
    echo "Check logs with: docker logs $CONTAINER_NAME"
    exit 1
fi
