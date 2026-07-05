# iVentoy Docker Image - Multi-Architecture Support
# Supports: linux/amd64, linux/arm64
# Based on: https://github.com/ziggyds/iventoy

# ==================== Builder Stage ====================
FROM --platform=$BUILDPLATFORM alpine:latest AS builder

ARG IVENTOY_VERSION=1.0.37
ARG TARGETPLATFORM

# Install dependencies
RUN apk add --no-cache \
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
# BusyBox grep does not support -P (Perl regex)
# Replace 'grep -P' with 'grep -E' (extended regex) in iventoy.sh
RUN if [ -f /tmp/iventoy/iventoy.sh ]; then \
        sed -i 's/grep -P/grep -E/g' /tmp/iventoy/iventoy.sh && \
        echo "✅ Fixed iventoy.sh: replaced 'grep -P' with 'grep -E'"; \
    else \
        echo "⚠️ iventoy.sh not found, skipping fix"; \
    fi

# ==================== Final Stage ====================
FROM alpine:latest

LABEL maintainer="thluozw"
LABEL description="iVentoy in Docker - Multi-architecture support (amd64/arm64)"

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    curl \
    openrc \
    tini

# Copy iVentoy from builder
COPY --from=builder /tmp/iventoy /iventoy

WORKDIR /iventoy

# Create required directories
RUN mkdir -p /iventoy/iso \
    && mkdir -p /iventoy/data \
    && chmod +x /iventoy/iventoy.sh \
    && chmod +x /iventoy/iventoy \
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

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Default command
# iventoy.sh accepts: start, stop, status
CMD ["/iventoy/iventoy.sh", "start"]
