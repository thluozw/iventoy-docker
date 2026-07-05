# iVentoy Docker Image - Multi-Architecture Support
# Supports: linux/amd64, linux/arm64
# NOTE: Due to iVentoy distribution restrictions, manual download is required
# See MANUAL-BUILD.md for details

# ==================== Builder Stage ====================
FROM alpine:latest AS builder

ARG IVENTOY_VERSION=1.0.37

# Install dependencies
RUN apk add --no-cache \
    tar

# Copy pre-downloaded iVentoy tarball
# Users must place iventoy-*.tar.gz in the build context
WORKDIR /tmp
COPY iventoy-*.tar.gz iventoy.tar.gz || true
COPY iventoy-${IVENTOY_VERSION}-linux-*.tar.gz iventoy.tar.gz 2>/dev/null || true

# If no local file, show error message
RUN if [ ! -f iventoy.tar.gz ]; then \
        echo "==================================================" && \
        echo "ERROR: iVentoy tarball not found!" && \
        echo "Please download iVentoy manually." && \
        echo "See MANUAL-BUILD.md for instructions." && \
        echo "==================================================" && \
        exit 1; \
    fi

# Extract iVentoy
RUN tar -xzf iventoy.tar.gz && \
    rm -f iventoy.tar.gz && \
    echo "iVentoy extracted successfully"

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

# Create required directories and set permissions
RUN mkdir -p /iventoy/iso \
    && mkdir -p /iventoy/data \
    && chmod +x /iventoy/iventoy.sh \
    && chmod +x /iventoy/iventoy \
    && ln -sf /iventoy/iventoy.sh /usr/local/bin/iventoy || true

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
