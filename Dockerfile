# iVentoy Docker Image - Multi-Architecture Support
# Supports: linux/amd64, linux/arm64
# Based on: https://github.com/ziggyds/iventoy
# Base image: Ubuntu (needed for glibc compatibility)

# ==================== Builder Stage ====================
FROM --platform=$BUILDPLATFORM ubuntu:latest AS builder

ARG IVENTOY_VERSION=1.0.37
ARG TARGETPLATFORM

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    tar \
    bash

# Download iVentoy based on TARGETPLATFORM
WORKDIR /tmp

RUN echo "TARGETPLATFORM: ${TARGETPLATFORM}" && \
    if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
        IVENTOY_FILE="iventoy-${IVENTOY_VERSION}-linux-arm64-trial.tar.gz"; \
    else \
        IVENTOY_FILE="iventoy-${IVENTOY_VERSION}-linux-x86_64-free.tar.gz"; \
    fi && \
    IVENTOY_URL="https://github.com/ventoy/PXE/releases/download/v${IVENTOY_VERSION}/${IVENTOY_FILE}" && \
    echo "Downloading from: ${IVENTOY_URL}" && \
    wget --no-verbose --show-progress "${IVENTOY_URL}" -O iventoy.tar.gz && \
    tar -xzf iventoy.tar.gz && \
    rm -f iventoy.tar.gz && \
    echo "Contents after extraction:" && \
    ls -la && \
    mv iventoy-* iventoy || true && \
    echo "✅ iVentoy ${IVENTOY_VERSION} downloaded and prepared successfully"

# ==================== Final Stage ====================
FROM ubuntu:latest

LABEL maintainer="thluozw"
LABEL description="iVentoy in Docker - Multi-architecture support (amd64/arm64)"

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy iVentoy from builder
COPY --from=builder /tmp/iventoy /iventoy

WORKDIR /iventoy

# Create required directories
RUN mkdir -p /iventoy/iso \
    && mkdir -p /iventoy/data \
    && chmod +x /iventoy/lib/iventoy

# Create a simple start script (replace the buggy iventoy.sh)
RUN cat > /iventoy/start-iventoy.sh << 'EOF'
#!/bin/bash

# Simple iVentoy startup script
# This replaces the buggy iventoy.sh from the original package

IVENTOY_BIN="/iventoy/lib/iventoy"

# Check if running as root
uid=$(id -u)
if [ $uid -ne 0 ]; then
    echo "Please use sudo or run the script as root."
    exit 1
fi

# Handle parameters
case "$1" in
    start)
        echo "Starting iVentoy..."
        cd /iventoy
        env IVENTOY_API_ALL=1 $IVENTOY_BIN &
        echo $! > /var/run/iventoy.pid
        echo "iVentoy started (PID: $!)"
        ;;
    stop)
        echo "Stopping iVentoy..."
        if [ -f /var/run/iventoy.pid ]; then
            kill $(cat /var/run/iventoy.pid)
            rm -f /var/run/iventoy.pid
            echo "iVentoy stopped"
        else
            echo "iVentoy is not running"
        fi
        ;;
    status)
        if [ -f /var/run/iventoy.pid ]; then
            pid=$(cat /var/run/iventoy.pid)
            if ps -p $pid > /dev/null 2>&1; then
                echo "iVentoy is running (PID: $pid)"
            else
                echo "iVentoy is not running (stale PID file)"
                rm -f /var/run/iventoy.pid
            fi
        else
            echo "iVentoy is not running"
        fi
        ;;
    *)
        echo "Usage: $0 { start | stop | status }"
        exit 1
        ;;
esac

exit 0
EOF

RUN chmod +x /iventoy/start-iventoy.sh

# ExPOSE ports (iVentoy default ports)
# 16000 - HTTP service
# 69 - TFTP service (UDP)
# 67, 68 - DHCP service (UDP)
EXPOSE 16000/tcp
EXPOSE 69/udp
EXPOSE 67/udp
EXPOSE 68/udp

# Mount points
VOLUME ["/iventoy/iso", "/iventoy/data"]

# Environment variables
ENV IVENTOY_ISO_PATH=/iventoy/iso
ENV IVENTOY_DATA_PATH=/iventoy/data
ENV IVENTOY_HTTP_PORT=16000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:16000 || exit 1

# Use our simple start script instead of the buggy iventoy.sh
CMD ["/iventoy/start-iventoy.sh", "start"]
