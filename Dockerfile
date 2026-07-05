# iVentoy Docker Image - Multi-Architecture Support
# Supports: linux/amd64, linux/arm64
# Based on: https://github.com/ziggyds/iventoy

ARG ARCH=amd64
FROM --platform=\${BUILDPLATFORM} alpine:latest AS builder

ARG IVENTOY_VERSION=1.0.20
ARG ARCH
ARG BUILDPLATFORM

RUN echo "Building for platform: ${BUILDPLATFORM}, ARCH: ${ARCH}"

# Install dependencies
RUN apk add --no-cache \
    wget \
    unzip \
    curl

# Download iVentoy based on architecture
WORKDIR /tmp
RUN if [ "${ARCH}" = "arm64" ]; then \
        IVENTOY_URL="https://github.com/ventoy/PXE/releases/download/v${IVENTOY_VERSION}/iventoy-${IVENTOY_VERSION}-linux-arm64.tar.gz"; \
    else \
        IVENTOY_URL="https://github.com/ventoy/PXE/releases/download/v${IVENTOY_VERSION}/iventoy-${IVENTOY_VERSION}-linux-x64.tar.gz"; \
    fi && \
    echo "Downloading from: ${IVENTOY_URL}" && \
    wget -q "${IVENTOY_URL}" -O iventoy.tar.gz || \
    (echo "Primary download failed, trying alternative source..." && \
     wget -q "https://mirrors.tuna.tsinghua.edu.cn/github-release/ventoy/PXE/LatestRelease/iventoy-${IVENTOY_VERSION}-linux-$([ "${ARCH}" = "arm64" ] && echo "arm64" || echo "x64").tar.gz" -O iventoy.tar.gz) && \
    tar -xzf iventoy.tar.gz && \
    rm iventoy.tar.gz

# Final stage
FROM alpine:latest

LABEL maintainer="thluozw"
LABEL description="iVentoy in Docker - Multi-architecture support (amd64/arm64)"

ARG ARCH
ENV ARCH=${ARCH}

# Install runtime dependencies
RUN apk add --no-cache \
    openrc \
    tini \
    bash \
    curl \
    netcat-openbsd

# Copy iVentoy from builder
COPY --from=builder /tmp/iventoy /iventoy

WORKDIR /iventoy

# Create required directories
RUN mkdir -p /iventoy/iso \
    && mkdir -p /iventoy/data \
    && chmod +x /iventoy/iventoy.sh \
    && chmod +x /iventoy/iventoy \
    && ln -sf /iventoy/iventoy.sh /usr/local/bin/iventoy

# Expose ports (iVentoy default ports)
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
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD nc -z localhost 16000 || exit 1

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Default command
CMD ["/iventoy/iventoy.sh", "-R"]
