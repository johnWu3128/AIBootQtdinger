# 本地部署记录

本文档记录当前机器在 `D:\javaEE\IdeaProjects\baosight\tools\quandtinger` 下的部署状态。

## 1. 已完成

- 已从官方公开仓库克隆源码：

```text
https://github.com/brokermr810/QuantDinger.git
```

- 已创建后端配置文件：

```text
backend_api_python/.env
```

- 已生成并写入随机 `SECRET_KEY`。
- 已安装用户级 `podman-compose`：

```powershell
py -m pip install --user podman-compose
```

- 已新增 Podman Compose 兼容覆盖文件：

```text
docker-compose.podman.yml
```

- 已使用 Podman Desktop / Podman Machine 构建并启动服务。
- 当前默认管理员配置：

```text
ADMIN_USER=quantdinger
ADMIN_PASSWORD=123456
```

首次登录后必须修改默认密码。

## 2. 当前运行状态

当前使用 Podman Desktop 替代 Docker Desktop。服务启动命令：

```powershell
$env:Path = "$env:APPDATA\Python\Python313\Scripts;$env:Path"
podman compose -f docker-compose.yml -f docker-compose.podman.yml up -d
```

访问地址：

```text
前端：http://localhost:8888
后端健康检查：http://localhost:5000/api/health
```

已验证：

- `http://localhost:5000/api/health` 返回 HTTP 200。
- `http://localhost:8888` 返回页面标题 `QuantDinger`。

## 3. Podman 代理说明

本机 Windows 侧代理监听：

```text
127.0.0.1:7897
```

Podman Machine 是 WSL VM，VM 内的 `127.0.0.1` 指向 VM 自身，不能直接访问 Windows 回环代理。因此已添加 Windows 端口转发：

```powershell
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=7898 connectaddress=127.0.0.1 connectport=7897
```

Podman 命令执行时使用：

```powershell
$env:HTTP_PROXY='http://172.29.128.1:7898'
$env:HTTPS_PROXY='http://172.29.128.1:7898'
$env:http_proxy='http://172.29.128.1:7898'
$env:https_proxy='http://172.29.128.1:7898'
```

如 Podman Machine 网关变化，重新获取：

```powershell
podman machine ssh podman-machine-default "ip route | awk '/default/ {print `$3; exit}'"
```

## 4. 常用 Podman 命令

进入项目根目录后执行：

```powershell
$env:Path = "$env:APPDATA\Python\Python313\Scripts;$env:Path"

# 查看运行状态
podman compose -f docker-compose.yml -f docker-compose.podman.yml ps

# 启动
podman compose -f docker-compose.yml -f docker-compose.podman.yml up -d

# 停止
podman compose -f docker-compose.yml -f docker-compose.podman.yml down

# 查看后端日志
podman logs -f quantdinger-backend

# 查看前端日志
podman logs -f quantdinger-frontend

# 重启后端
podman restart quantdinger-backend
```

## 5. 如需使用国内镜像加速

如果 Podman 拉取 Docker Hub 基础镜像慢或失败，可在项目根目录 `.env` 中设置：

```ini
IMAGE_PREFIX=docker.m.daocloud.io/library/
FRONTEND_TAG=latest
IMAGE_TAG=latest
```

然后重新执行：

```powershell
podman compose -f docker-compose.yml -f docker-compose.podman.yml pull
podman compose -f docker-compose.yml -f docker-compose.podman.yml up -d
```
