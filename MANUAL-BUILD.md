# iVentoy Docker - 手动构建指南

由于 iVentoy 的分发限制，自动构建可能无法正常工作。请按照以下步骡手动构建。

## 快速开始

### 1. 下载 iVentoy

访问 https://github.com/ventoy/PXE/releases/ 下载对应版本：

**x86_64 (Intel/AMD):**
```bash
wget https://github.com/ventoy/PXE/releases/download/v1.0.37/iventoy-1.0.37-linux-x86_64-free.tar.gz
```

**ARM64 (Raspberry Pi, Apple Silicon):**
```bash
wget https://github.com/ventoy/PXE/releases/download/v1.0.37/iventoy-1.0.37-linux-arm64-trial.tar.gz
```

### 2. 放置文件

将下载的 `.tar.gz` 文件放置在项目根目录（与 Dockerfile 同级）。

### 3. 构建镜像

**x86_64:**
```bash
docker build --build-arg ARCH=amd64 -t iventoy:latest .
```

**ARM64:**
```bash
docker build --build-arg ARCH=arm64 -t iventoy:arm64 .
```

### 4. 运行容器

```bash
docker run -d \
  --name iventoy \
  --privileged \
  --network host \
  -v $(pwd)/iso:/iventoy/iso \
  -v $(pwd)/data:/iventoy/data \
  iventoy:latest
```

## 使用 Docker Compose

1. 下载 iVentoy 并放置在项目根目录
2. 重命名文件为 `iventoy.tar.gz`
3. 运行：
   ```bash
   docker-compose up -d
   ```

## 访问 Web 界面

打开浏览器访问：`http://<你的IP>:16000`

默认用户名/密码：`admin` / `admin`

## 常见问题

### Q: 为什么不能自动下载？
A: iVentoy 是闭源软件，分发可能受到限制。请遵守其许可证要求。

### Q: ARM64 版本是 trial，有什么限制？
A: 请查看 iVentoy 官方文档了解 trial 版本的限制。

### Q: 如何更新 iVentoy 版本？
A: 下载新版本，替换 `iventoy.tar.gz`，重新构建镜像。

## 项目链接

- GitHub: https://github.com/thluozw/iventoy-docker
- iVentoy 官网: https://www.ventoy.net/en/doc_pxe.html
