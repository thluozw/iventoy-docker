# iVentoy Docker Image - Multi-Architecture Support
# Supports: linux/amd64, linux/arm64

ARG IVENTOY_VERSION=1.0.37
ARG IVENTOY_SUFFIX_amd64=free
ARG IVENTOY_SUFFIX_arm64=trial

# ==================== Builder Stage ====================
FROM --platform=$BUILDPLATFORM alpine:latest AS builder

ARG IVENTOY_VERSION
ARG IVENTOY_SUFFIX_amd64
ARG IVENTOY_SUFFIX_arm64
ARG BUILDPLATFORM

# Determine architecture for download
RUN echo "BUILDPLATFORM: ${BUILDPLATFORM}" && \
    if [ "${BUILDPLATFORM}" = "linux/arm64" ]; then \
        export ARCH_SUFFIX="${IVENTOY_SUFFIX_arm64}"; \
        export ARCH_NAME="arm64"; \
    else \
        export ARCH_SUFFIX="${IVENTOY_SUFFIX_amd64}"; \
        export ARCH_NAME="x86_64"; \
    fi && \
    echo "Building for: linux/${ARCH_NAME}, suffix: ${ARCH_SUFFIX}"

# Install dependencies
RUN apk add --no-cache \
    wget \
    curl \
    tar

# Download iVentoy
WORKDIR /tmp
RUN IVENTOY_FILE="iventoy-${IVENTOY_VERSION}-linux-${ARCH_NAME}-${ARCH_SUFFIX}.tar.gz" && \
    IVENTOY_URL="https://github.com/ventoy/PXE/releases/download/v${IVENTOY_VERSION}/${IVENTOY_FILE}" && \
    echo "Downloading: ${IVENTOY_URL}" && \
    wget --no-verbose --show-progress "${IVENTOY_URL}" -O iventoy.tar.gz && \
    tar -xzf iventoy.tar.gz && \
    rm -f iventoy.tar.gz && \
    echo "Download and extraction complete"

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
    && chmod +x /iventoy/iventoy

# Expose ports
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

# Default command - run iventoy in daemon mode
CMD ["/iventoy/iventoy.sh", "-R"]
