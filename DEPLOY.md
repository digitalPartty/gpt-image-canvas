# 部署指南

本文档说明如何在 Ubuntu 服务器上部署 GPT Image Canvas。

## 前置要求

- Ubuntu 20.04+ 或其他 Linux 发行版
- Docker 和 Docker Compose
- Nginx（已安装并运行）
- 域名和 SSL 证书

## 快速部署

### 1. 准备项目

```bash
# 克隆项目
git clone <your-repo-url>
cd gpt-image-canvas

# 运行部署脚本
chmod +x deploy.sh
./deploy.sh
```

### 2. 配置 Nginx

```bash
# 复制 Nginx 配置到你的 Nginx 配置目录
sudo cp nginx/gpt-image-canvas.conf /etc/nginx/conf.d/

# 或者如果使用 sites-available/sites-enabled 结构
sudo cp nginx/gpt-image-canvas.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/gpt-image-canvas.conf /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重载 Nginx
sudo nginx -s reload

# 如果是 Docker Nginx
docker exec nginx nginx -t
docker exec nginx nginx -s reload
```

### 3. 验证部署

```bash
# 检查容器状态
docker compose -f docker-compose.prod.yml ps

# 测试健康检查
curl http://localhost:8787/api/health

# 测试域名访问
curl -I https://canvas.chatimage.cc.cd
```

## 环境变量配置

编辑 `.env` 文件：

```env
# 服务器配置
PORT=8787
HOST=0.0.0.0
DATA_DIR=/app/data

# SQLite 配置
SQLITE_JOURNAL_MODE=DELETE
SQLITE_LOCKING_MODE=EXCLUSIVE

# OpenAI API（可选，浏览模式不需要）
OPENAI_API_KEY=your-api-key-here
OPENAI_BASE_URL=
OPENAI_IMAGE_MODEL=gpt-image-2
OPENAI_IMAGE_TIMEOUT_MS=1200000

# Codex 配置
CODEX_RESPONSES_MODEL=gpt-5.5
```

**注意：** 如果只是浏览界面，不需要配置 API 密钥。

## 管理命令

使用 `manage.sh` 脚本管理服务：

```bash
# 赋予执行权限
chmod +x manage.sh

# 启动服务
./manage.sh start

# 停止服务
./manage.sh stop

# 重启服务
./manage.sh restart

# 查看日志
./manage.sh logs

# 查看状态
./manage.sh status

# 重新构建
./manage.sh build

# 备份数据
./manage.sh backup

# 检查健康状态
./manage.sh health

# 清理 Docker 资源
./manage.sh clean
```

## Docker 命令

如果不使用管理脚本，可以直接使用 Docker Compose 命令：

```bash
# 启动
docker compose -f docker-compose.prod.yml up -d

# 停止
docker compose -f docker-compose.prod.yml down

# 重启
docker compose -f docker-compose.prod.yml restart

# 查看日志
docker compose -f docker-compose.prod.yml logs -f

# 查看状态
docker compose -f docker-compose.prod.yml ps

# 重新构建
docker compose -f docker-compose.prod.yml up -d --build
```

## Nginx 配置说明

配置文件位于 `nginx/gpt-image-canvas.conf`，包含以下功能：

- HTTP 到 HTTPS 重定向
- SSL/TLS 配置
- WebSocket 支持（Agent 功能需要）
- 流式响应支持
- 大文件上传支持（256MB）
- 长超时配置（图片生成需要）

**重要配置项：**

- `server_name`: 修改为你的域名
- `ssl_certificate`: SSL 证书路径
- `ssl_certificate_key`: SSL 私钥路径
- `resolver 127.0.0.11`: Docker 内部 DNS，如果使用宿主机 Nginx 可能需要修改

## 数据持久化

数据存储在 `./data` 目录：

- `gpt-image-canvas.sqlite`: 数据库文件
- `assets/`: 生成的图片文件

**备份建议：**

```bash
# 手动备份
cp -r data data-backup-$(date +%Y%m%d)

# 使用管理脚本备份
./manage.sh backup

# 定期备份（添加到 crontab）
0 2 * * * cd /opt/gpt-image-canvas && ./manage.sh backup
```

## 网络配置

项目使用外部 Docker 网络 `nginx_network`：

```bash
# 创建网络
docker network create nginx_network

# 查看网络
docker network inspect nginx_network

# 如果需要删除网络
docker network rm nginx_network
```

## 故障排查

### 容器无法启动

```bash
# 查看详细日志
docker compose -f docker-compose.prod.yml logs

# 检查配置
docker compose -f docker-compose.prod.yml config
```

### 健康检查失败

```bash
# 进入容器检查
docker exec -it gpt-image-canvas sh

# 手动测试健康检查
curl http://localhost:8787/api/health
```

### Nginx 无法连接到容器

```bash
# 检查容器是否在正确的网络中
docker network inspect nginx_network

# 检查容器 IP
docker inspect gpt-image-canvas | grep IPAddress

# 测试容器端口
curl http://172.x.x.x:8787/api/health
```

### 数据库错误

```bash
# 检查数据目录权限
ls -la data/

# 如果需要重置数据库
docker compose -f docker-compose.prod.yml down
rm -rf data/gpt-image-canvas.sqlite*
docker compose -f docker-compose.prod.yml up -d
```

## 更新应用

```bash
# 备份数据
./manage.sh backup

# 拉取最新代码
git pull

# 重新构建
./manage.sh build

# 查看日志
./manage.sh logs
```

## 安全建议

1. **不要公开暴露应用**：此应用设计为本地使用，包含敏感数据
2. **保护 data 目录**：包含 API 密钥和 OAuth token
3. **定期备份**：设置自动备份任务
4. **使用强密码**：如果添加认证层
5. **更新依赖**：定期更新 Docker 镜像和依赖包

## 功能可用性

### 无需 API 密钥即可使用

- ✅ 首页（`/`）
- ✅ Prompt Pool（`/pool`）
- ✅ Gallery（`/gallery`）
- ✅ Canvas 界面（`/canvas`）

### 需要 API 密钥

- ❌ 生成新图片
- ❌ 参考图生成
- ❌ Agent 多图规划

## 支持

如有问题，请查看：

- 项目 README: `README.md`
- 故障排查: 本文档"故障排查"部分
- 日志: `./manage.sh logs`
