# iVentoy Docker

Dockerized iVentoy with **multi-architecture support** (amd64 & arm64).

> 🚀 **Available on DockerHub**: `javion666/iventoy-docker`  
> 📦 **Also on GitHub Container Registry**: `ghcr.io/thluozw/iventoy-docker`

## What is iVentoy?

iVentoy is the PXE (network boot) version of [Ventoy](https://www.ventoy.net). It allows you to boot ISO files over network, eliminating the need to write USB drives for each machine.

## ✨ Features

- ✅ **Multi-Architecture**: Supports both `linux/amd64` and `linux/arm64`
- ✅ **Easy Deployment**: Docker containerized, one-click startup
- ✅ **Data Persistence**: ISO files and configurations are mounted externally
- ✅ **Auto-Configuration**: Web UI for easy setup

## 🚀 Quick Start

### Option 1: Pull from DockerHub (Recommended)

```bash
# Pull the multi-arch image (auto-detects your CPU architecture)
docker pull javion666/iventoy-docker:latest

# Run the container
docker run -d \
  --name iventoy \
  --privileged \
  --network host \
  -v $(pwd)/iso:/iventoy/iso \
  -v $(pwd)/data:/iventoy/data \
  javion666/iventoy-docker:latest
```

### Option 2: Pull from GitHub Container Registry

```bash
docker pull ghcr.io/thluozw/iventoy-docker:latest

docker run -d \
  --name iventoy \
  --privileged \
  --network host \
  -v $(pwd)/iso:/iventoy/iso \
  -v $(pwd)/data:/iventoy/data \
  ghcr.io/thluozw/iventoy-docker:latest
```

### Option 3: Use Docker Compose

```yaml
version: '3.8'

services:
  iventoy:
    image: javion666/iventoy-docker:latest
    container_name: iventoy
    privileged: true
    network_mode: host
    volumes:
      - ./iso:/iventoy/iso
      - ./data:/iventoy/data
    restart: unless-stopped
```

Then run:

```bash
docker-compose up -d
```

## 🌐 Access Web Interface

After starting the container, access the web interface at:

```
http://<your-server-ip>:16000
```

**Default Credentials**:
- Username: `admin`
- Password: `admin`

## 📁 Directory Structure

```
.
├── iso/           # Place your ISO files here
│   ├── ubuntu-22.04.iso
│   ├── debian-11.iso
│   └── ...
└── data/          # iVentoy data directory (config, logs, etc.)
```

## 🔌 Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 16000 | TCP | iVentoy Web Management Interface |
| 69 | UDP | TFTP Service |
| 67, 68 | UDP | DHCP Service |

## 🏗️ Supported Architectures

| Architecture | Platform | Example Devices |
|-------------|----------|----------------|
| `linux/amd64` | x86_64 | Intel/AMD 64-bit CPUs, most PCs/servers |
| `linux/arm64` | ARM64 | Apple Silicon (M1/M2/M3), Raspberry Pi 4+/5, AWS Graviton |

Docker will automatically detect your CPU architecture and pull the correct image.

## ⚙️ Configuration Notes

### Why `--privileged`?

iVentoy needs to access network interfaces and raw sockets to provide PXE boot services, so it requires privileged mode.

### Why `--network host`?

PXE boot requires DHCP and TFTP services. Using host network mode simplifies network configuration.

## 🔄 Upgrade

```bash
# Pull latest image
docker pull javion666/iventoy-docker:latest

# Stop and remove old container
docker stop iventoy && docker rm iventoy

# Re-run with the same volume mounts
docker run -d \
  --name iventoy \
  --privileged \
  --network host \
  -v $(pwd)/iso:/iventoy/iso \
  -v $(pwd)/data:/iventoy/data \
  javion666/iventoy-docker:latest
```

## 🐛 Troubleshooting

### Check container logs

```bash
docker logs iventoy
```

### Verify architecture

```bash
# Check the architecture of the pulled image
docker inspect javion666/iventoy-docker:latest | grep Architecture
```

## 📝 License

iVentoy follows its own license. This project only provides Docker packaging.

## 🔗 Links

- **iVentoy Official Site**: https://www.ventoy.net/en/doc_pxe.html
- **iVentoy Releases**: https://github.com/ventoy/PXE/releases
- **This Project (GitHub)**: https://github.com/thluozw/iventoy-docker
- **DockerHub Repository**: https://hub.docker.com/r/javion666/iventoy-docker

## 🙏 Acknowledgments

This project is based on [ziggyds/iventoy](https://github.com/ziggyds/iventoy) with added ARM64 support.

## 🤝 Contributing

Issues and Pull Requests are welcome!

---

**⭐ If you find this project helpful, please give it a star on GitHub and DockerHub!**
