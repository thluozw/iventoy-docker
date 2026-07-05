# iVentoy Docker - Multi-Architecture Support

This project provides a Dockerized version of iVentoy with **full ARM64 (AArch64) support**.

## Key Improvements over Original

1. **Multi-Architecture Support**: 
   - linux/amd64 (x86_64)
   - linux/arm64 (ARM64/AArch64)

2. **Automated Builds**:
   - GitHub Actions workflow for automatic multi-arch builds
   - Pushes to both Docker Hub and GitHub Container Registry

3. **Better Documentation**:
   - Complete setup instructions
   - ARM64-specific guidance
   - Troubleshooting tips

## Quick Start

### Pre-built Images

```bash
# Pull for your architecture (auto-detected)
docker pull ghcr.io/thluozw/iventoy-docker:latest

# Or use Docker Compose
docker-compose up -d
```

### Build Locally

```bash
# Clone the repository
git clone https://github.com/thluozw/iventoy-docker.git
cd iventoy-docker

# Build for current architecture
docker build -t iventoy-docker .

# Or build for specific architecture
docker build --build-arg ARCH=arm64 -t iventoy-docker:arm64 .
```

## Directory Structure

```
iventoy-docker/
├── Dockerfile              # Multi-arch Dockerfile
├── docker-compose.yml     # Docker Compose configuration
├── .github/
│   └── workflows/
│       └── docker-build.yml  # Automated CI/CD
├── iso/                   # Mount your ISO files here
├── data/                  # Persistent data (config, logs)
└── README.md
```

## Usage

### Basic Usage

```bash
docker run -d \
  --name iventoy \
  --privileged \
  --network host \
  -v $(pwd)/iso:/iventoy/iso \
  -v $(pwd)/data:/iventoy/data \
  -p 16000:16000 \
  ghcr.io/thluozw/iventoy-docker:latest
```

### With Docker Compose

1. Place your ISO files in the `iso/` directory
2. Run: `docker-compose up -d`
3. Access web interface: `http://localhost:16000`

## ARM64 Support Details

The Dockerfile automatically detects the target architecture and downloads the appropriate iVentoy binary:

- **amd64**: Downloads `iventoy-*-linux-x64.tar.gz`
- **arm64**: Downloads `iventoy-*-linux-arm64.tar.gz`

Tested on:
- Raspberry Pi 4B/400
- Apple Silicon Macs (M1/M2)
- ARM64 cloud servers

## Contributing

Contributions welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

iVentoy itself is copyrighted by its authors - see https://www.ventoy.net for details.
