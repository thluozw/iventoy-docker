#!/bin/bash
# iVentoy Docker - Quick Start Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}iVentoy Docker - Setup Script${NC}"
echo "=================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Create directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p iso data

# Check architecture
ARCH=$(uname -m)
echo -e "${YELLOW}Detected architecture: ${ARCH}${NC}"

if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    echo -e "${GREEN}ARM64 architecture detected${NC}"
    PLATFORM="linux/arm64"
else
    echo -e "${GREEN}x86_64 architecture detected${NC}"
    PLATFORM="linux/amd64"
fi

# Build image
echo -e "${YELLOW}Building Docker image for ${PLATFORM}...${NC}"
docker build --build-arg ARCH=$([ "$ARCH" = "aarch64" ] && echo "arm64" || echo "amd64") -t iventoy-docker .

# Run container
echo -e "${YELLOW}Starting iVentoy container...${NC}"
docker run -d \
    --name iventoy \
    --privileged \
    --network host \
    -v $(pwd)/iso:/iventoy/iso \
    -v $(pwd)/data:/iventoy/data \
    --restart unless-stopped \
    iventoy-docker

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}iVentoy is now running!${NC}"
echo -e "${GREEN}Web interface: http://localhost:16000${NC}"
echo -e "${GREEN}Default login: admin / admin${NC}"
echo "=================================="
echo ""
echo "Useful commands:"
echo "  View logs:    docker logs -f iventoy"
echo "  Stop:         docker stop iventoy"
echo "  Start:        docker start iventoy"
echo "  Remove:       docker rm -f iventoy"
echo ""
echo -e "${YELLOW}Place your ISO files in the 'iso' directory${NC}"
