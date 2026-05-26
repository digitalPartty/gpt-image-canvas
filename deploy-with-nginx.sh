#!/bin/bash

# GPT Image Canvas 完整部署脚本（包含 Nginx Docker 配置）

set -e

echo "=========================================="
echo "GPT Image Canvas 完整部署脚本"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    exit 1
fi

# 检查 Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}错误: Docker Compose 未安装${NC}"
    exit 1
fi

# 1. 创建 Docker 网络
echo -e "${YELLOW}步骤 1: 创建 Docker 网络${NC}"
if docker network inspect nginx_network &> /dev/null; then
    echo -e "${GREEN}✓ 网络 nginx_network 已存在${NC}"
else
    docker network create nginx_network
    echo -e "${GREEN}✓ 网络 nginx_network 创建成功${NC}"
fi

# 2. 检查 Nginx 容器
echo -e "\n${YELLOW}步骤 2: 检查 Nginx 容器${NC}"
NGINX_CONTAINER=$(docker ps --filter "name=nginx" --format "{{.Names}}" | head -n 1)

if [ -z "$NGINX_CONTAINER" ]; then
    echo -e "${RED}✗ 未找到运行中的 Nginx 容器${NC}"
    echo "请确保 Nginx 容器正在运行，容器名包含 'nginx'"
    exit 1
else
    echo -e "${GREEN}✓ 找到 Nginx 容器: $NGINX_CONTAINER${NC}"
fi

# 3. 将 Nginx 连接到网络
echo -e "\n${YELLOW}步骤 3: 连接 Nginx 到网络${NC}"
if docker network inspect nginx_network | grep -q "$NGINX_CONTAINER"; then
    echo -e "${GREEN}✓ Nginx 已在 nginx_network 网络中${NC}"
else
    docker network connect nginx_network "$NGINX_CONTAINER"
    echo -e "${GREEN}✓ Nginx 已连接到 nginx_network${NC}"
fi

# 4. 创建数据目录
echo -e "\n${YELLOW}步骤 4: 创建数据目录${NC}"
mkdir -p data
echo -e "${GREEN}✓ 数据目录创建成功${NC}"

# 5. 检查 .env 文件
echo -e "\n${YELLOW}步骤 5: 检查环境变量${NC}"
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}✓ .env 文件创建成功${NC}"
    echo -e "${YELLOW}提示: 如需生成图片，请编辑 .env 配置 API 密钥${NC}"
else
    echo -e "${GREEN}✓ .env 文件已存在${NC}"
fi

# 6. 构建并启动应用
echo -e "\n${YELLOW}步骤 6: 构建并启动应用${NC}"
docker compose -f docker-compose.prod.yml up -d --build
echo -e "${GREEN}✓ 应用启动成功${NC}"

# 7. 配置 Nginx
echo -e "\n${YELLOW}步骤 7: 配置 Nginx${NC}"
echo "正在复制 Nginx 配置文件..."
docker cp nginx/gpt-image-canvas.conf "$NGINX_CONTAINER":/etc/nginx/conf.d/
echo -e "${GREEN}✓ 配置文件复制成功${NC}"

echo "测试 Nginx 配置..."
if docker exec "$NGINX_CONTAINER" nginx -t; then
    echo -e "${GREEN}✓ Nginx 配置测试通过${NC}"
    echo "重载 Nginx..."
    docker exec "$NGINX_CONTAINER" nginx -s reload
    echo -e "${GREEN}✓ Nginx 重载成功${NC}"
else
    echo -e "${RED}✗ Nginx 配置测试失败${NC}"
    echo "请检查配置文件: nginx/gpt-image-canvas.conf"
    exit 1
fi

# 8. 等待服务启动
echo -e "\n${YELLOW}步骤 8: 等待服务启动${NC}"
echo "等待 40 秒让服务完全启动..."
sleep 40

# 9. 验证部署
echo -e "\n${YELLOW}步骤 9: 验证部署${NC}"

echo "检查容器状态..."
docker compose -f docker-compose.prod.yml ps

echo -e "\n检查网络连接..."
if docker exec "$NGINX_CONTAINER" ping -c 3 gpt-image-canvas &> /dev/null; then
    echo -e "${GREEN}✓ 网络连接正常${NC}"
else
    echo -e "${RED}✗ 网络连接失败${NC}"
fi

echo -e "\n检查健康状态..."
if docker exec "$NGINX_CONTAINER" curl -f http://gpt-image-canvas:8787/api/health &> /dev/null; then
    echo -e "${GREEN}✓ 应用健康检查通过${NC}"
else
    echo -e "${YELLOW}⚠ 健康检查失败，可能还在启动中${NC}"
fi

# 10. 完成
echo -e "\n=========================================="
echo -e "${GREEN}部署完成！${NC}"
echo "=========================================="
echo ""
echo "服务信息:"
echo "  - 容器名称: gpt-image-canvas"
echo "  - 内部端口: 8787"
echo "  - 域名: canvas.chatimage.cc.cd"
echo ""
echo "管理命令:"
echo "  查看日志: docker compose -f docker-compose.prod.yml logs -f"
echo "  重启服务: docker compose -f docker-compose.prod.yml restart"
echo "  停止服务: docker compose -f docker-compose.prod.yml down"
echo ""
echo "或使用管理脚本:"
echo "  ./manage.sh logs    # 查看日志"
echo "  ./manage.sh restart # 重启服务"
echo "  ./manage.sh status  # 查看状态"
echo ""
echo "网络信息:"
docker network inspect nginx_network --format '{{range .Containers}}  - {{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}'
echo ""
echo -e "${YELLOW}注意: 请确保域名 canvas.chatimage.cc.cd 已正确解析到服务器${NC}"
echo ""
