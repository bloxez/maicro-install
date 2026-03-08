#!/bin/sh

# mAIcro Quick Start Script (macOS / Linux / WSL)
# Usage: curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh
#    or: curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh -s -- /path/to/data

set -e

# Configuration
IMAGE="bloxez/maicro-g2a:latest"
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
APP_DATA_DIR=""

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
    echo ""
    printf "${YELLOW}  Docker needs a little setup before we can continue.${NC}\n"
    printf "${YELLOW}  You may be asked for your password.${NC}\n"
    echo ""

    # Start Docker service if possible
    if command -v systemctl > /dev/null 2>&1; then
        printf "  Starting Docker service...\n"
        sudo systemctl start docker 2>/dev/null || true
        sleep 1
    fi

    # Add user to docker group and apply immediately
    if ! docker info > /dev/null 2>&1; then
        printf "  Setting up Docker permissions for your user...\n"
        sudo usermod -aG docker "$USER"
        # Apply group change immediately via sg and re-run this script
        printf "${GREEN}  ✅ Done! Re-running setup with new permissions...${NC}\n"
        echo ""
        sg docker -c "sh $0 $*"
        exit $?
    fi
fi

printf "${GREEN}✅ Docker is running${NC}\n"

# Resolve to absolute path
DATA_DIR=$(cd "$(dirname "$DATA_DIR")" 2>/dev/null && pwd)/$(basename "$DATA_DIR") || DATA_DIR="$DEFAULT_DATA_DIR"
APP_DATA_DIR="${DATA_DIR}/data"

# Create data directory
printf "${YELLOW}📁 Data directory: ${DATA_DIR}${NC}\n"
mkdir -p "$DATA_DIR"
mkdir -p "$APP_DATA_DIR"

# Create update script
cat > "${DATA_DIR}/update.sh" << 'EOF'
#!/bin/sh
# mAIcro Update Script - Pull latest image and restart container

set -e

IMAGE="bloxez/maicro-g2a:latest"
CONTAINER_NAME="maicro"
APP_DATA_DIR="$(pwd)/data"

echo "🔍 Checking for updates..."

# Get current image digest
CURRENT_DIGEST=$(docker inspect --format='{{.Image}}' "$CONTAINER_NAME" 2>/dev/null || echo "")

# Pull latest
echo "📦 Pulling latest image..."
docker pull "$IMAGE"

# Get new image digest
NEW_DIGEST=$(docker inspect --format='{{.Id}}' "$IMAGE" 2>/dev/null || echo "")

if [ "$CURRENT_DIGEST" = "$NEW_DIGEST" ]; then
    echo "✅ Already on latest version"
    exit 0
fi

echo "🔄 New version available, updating..."

# Stop and remove old container
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Get port from environment or default
PORT="${MAICRO_PORT:-4321}"

# Restart with same settings
echo "🚀 Starting updated container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "${PORT}:3456" \
    -v "$(pwd):/app/runtime/userdata" \
    -v "${APP_DATA_DIR}:/app/data" \
    -e "OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-}" \
    --add-host=host.docker.internal:host-gateway \
    --restart unless-stopped \
    "$IMAGE"

sleep 2

if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
    echo "✅ Update complete!"
    echo "🌐 mAIcro: http://localhost:${PORT}/ide"
else
    echo "❌ Failed to start updated container"
    docker logs "$CONTAINER_NAME"
    exit 1
fi
EOF

chmod +x "${DATA_DIR}/update.sh"

# Create remove script
cat > "${DATA_DIR}/remove.sh" << 'EOF'
#!/bin/sh
# mAIcro Remove Script - Remove container and optionally remove persisted data

set -e

CONTAINER_NAME="maicro"
DATA_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "⚠️  This will remove the mAIcro container: ${CONTAINER_NAME}"
printf "Remove container now? [y/N]: "
read -r CONFIRM_CONTAINER

case "$CONFIRM_CONTAINER" in
    y|Y|yes|YES)
        echo "🛑 Stopping and removing container..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
        ;;
    *)
        echo "Cancelled."
        exit 0
        ;;
esac

echo "✅ Container removed (or was not present)."
echo ""
echo "Persisted data directory: ${DATA_DIR}"
printf "Also remove persisted data from host? [y/N]: "
read -r CONFIRM_DATA

case "$CONFIRM_DATA" in
    y|Y|yes|YES)
        echo "🗑️  Removing persisted data..."
        find "$DATA_DIR" -mindepth 1 -maxdepth 1 \
            ! -name "update.sh" \
            ! -name "remove.sh" \
            -exec rm -rf {} +
        echo "✅ Persisted data removed."
        ;;
    *)
        echo "Data kept at: ${DATA_DIR}"
        ;;
esac
EOF

chmod +x "${DATA_DIR}/remove.sh"

# Stop and remove existing container if it exists
if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
    printf "${YELLOW}🛑 Stopping existing mAIcro container...${NC}\n"
    docker stop "$CONTAINER_NAME" > /dev/null 2>&1 || true
    docker rm "$CONTAINER_NAME" > /dev/null 2>&1 || true
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
    -v "${APP_DATA_DIR}:/app/data" \
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
    echo "  🗄️  DB Data:  ${APP_DATA_DIR}"
    echo ""
    echo "Commands:"
    printf "  Update:  ${YELLOW}${DATA_DIR}/update.sh${NC}\n"
    printf "  Remove:  ${YELLOW}${DATA_DIR}/remove.sh${NC}\n"
    printf "  Stop:    ${YELLOW}docker stop maicro${NC}\n"
    printf "  Start:   ${YELLOW}docker start maicro${NC}\n"
    printf "  Logs:    ${YELLOW}docker logs -f maicro${NC}\n"
    printf "  Force Remove: ${YELLOW}docker rm -f maicro${NC}\n"
    echo ""
else
    printf "${RED}❌ Failed to start mAIcro${NC}\n"
    echo "Check logs with: docker logs $CONTAINER_NAME"
    exit 1
fi
