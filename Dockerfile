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

# ==================== Fix iventoy.sh ====================
# Fix parameter check logic (missing '!', causing wrong usage message)
RUN if [ -f /tmp/iventoy/iventoy.sh ]; then \
        # Fix: Add missing '!' in parameter check
        # The original code shows usage when parameter IS valid (WRONG!)
        # We need to show usage when parameter is NOT valid
        sed -i 's/if echo \$1 | grep.*start.*stop.*status/if ! echo $1 | grep -q "start\\|stop\\|status"/' /tmp/iventoy/iventoy.sh && \
        echo "✅ Fixed iventoy.sh: added missing '!' in parameter check"; \
    else \
        echo "⚠️ iventoy.sh not found, skipping fix"; \
    fi

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
    && chmod +x /iventoy/iventoy.sh \
    && chmod +x /iventoy/lib/iventoy \
    && ln -sf /iventoy/iventoy.sh /usr/local/bin/iventoy || true

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

# Default command
# iventoy.sh accepts: start, stop, status
CMD ["/iventoy/iventoy.sh", "start"]
