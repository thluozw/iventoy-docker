# iVentoy Docker

Dockerized iVentoy with **multi-architecture support** (amd64 & arm64).

基于 [ziggyds/iventoy](https://github.com/ziggyds/iventoy) 改进，添加 ARM64 架构支持。

## 什么是 iVentoy？

iVentoy 是 [Ventoy](https://www.ventoy.net) 的 PXE 网络启动版本，允许你通过网络启动 ISO 文件，无需逐台机器写入 USB。

## ⚠️ 重要提示

由于 iVentoy 的分发限制，**自动构建可能无法正常工作**。请按照 [MANUAL-BUILD.md](MANUAL-BUILD.md) 的说明手动下载 iVentoy 并构建。

## 功能特点

✅ **多架构支持**: linux/amd64, linux/arm64 (ARM64/AArch64)  
✅ **简化部署**: Docker 容器化，一键启动  
✅ **数据持久化**: ISO 文件和配置外挂存储  
✅ **自动更新**: 支持指定 iVentoy 版本  

## 快速开始

### 使用 Docker CLI

```bash
# 拉取镜像（自动匹配架构）
docker pull ghcr.io/thluozw/iventoy-docker:latest

# 运行容器
docker run -d \
  --name iventoy \
  --privileged \
  --network host \
  -v /path/to/your/iso:/iventoy/iso \
  -v /path/to/data:/iventoy/data \
  ghcr.io/thluozw/iventoy-docker:latest
```

### 使用 Docker Compose

```yaml
version: '3.8'

services:
  iventoy:
    image: ghcr.io/thluozw/iventoy-docker:latest
    container_name: iventoy
    privileged: true
    network_mode: host
    volumes:
      - ./iso:/iventoy/iso
      - ./data:/iventoy/data
    restart: unless-stopped
```

## 构建多架构镜像

```bash
# 设置 buildx
docker buildx create --use --name multiarch || true
docker buildx inspect --bootstrap

# 构建并推送多架构镜像
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/thluozw/iventoy-docker:latest \
  -t ghcr.io/thluozw/iventoy-docker:v1.0.20 \
  --push \
  .
```

## 配置说明

### 目录结构

```
.
├── iso/           # 放置 ISO 文件的目录
│   ├── ubuntu-22.04.iso
│   ├── debian-11.iso
│   └── ...
└── data/          # iVentoy 数据目录（配置、日志等）
```

### 端口说明

| 端口 | 协议 | 用途 |
|------|------|------|
| 16000 | TCP | iVentoy Web 管理界面 |
| 69 | UDP | TFTP 服务 |
| 67, 68 | UDP | DHCP 服务 |

### 访问 Web 界面

容器启动后，访问：`http://<你的IP>:16000`

默认用户名/密码：admin / admin

## ARM64 设备支持

✅ 已测试平台：
- Raspberry Pi 4B/400 (Ubuntu/Debian)
- Apple Silicon Mac (Docker Desktop)
- 华为鲲鹏服务器
- 亚马逊 Graviton (AWS)

## 常见问题

### 1. 为什么需要 `--privileged`？

iVentoy 需要访问网络接口和原始套接字来提供 PXE 启动服务，因此需要特权模式。

### 2. 为什么使用 `--network host`？

PXE 启动需要 DHCP 和 TFTP 服务，使用 host 网络模式可以简化网络配置。

### 3. ARM64 版本性能如何？

在 Raspberry Pi 4B 上测试，iVentoy 运行良好，可以同时服务多台客户端。

## 升级

```bash
# 拉取最新镜像
docker pull ghcr.io/thluozw/iventoy-docker:latest

# 停止并删除旧容器
docker stop iventoy && docker rm iventoy

# 重新运行（使用相同的卷挂载）
docker run -d ...
```

## 许可证

iVentoy 遵循其自身的许可证。本项目仅提供 Docker 封装。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 作者

- thluozw
- 基于 [ziggyds/iventoy](https://github.com/ziggyds/iventoy) 改进

## 链接

- iVentoy 官网: https://www.ventoy.net/en/doc_pxe.html
- Ventoy GitHub: https://github.com/ventoy/PXE
- 本项目 GitHub: https://github.com/thluozw/iventoy-docker
