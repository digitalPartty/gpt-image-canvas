#!/bin/bash

# GPT Image Canvas 部署脚本

set -e

echo "=========================================="
echo "GPT Image Canvas 部署脚本"
echo "=========================================="

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装"
    exit 1
fi

# 检查 Docker Compose
if ! docker compose version &> /dev/null; then
    echo "错误: Docker Compose 未安装"
    exit 1
fi

# 创建必要目录
echo "创建数据目录..."
mkdir -p data

# 检查 .env 文件
if [ ! -f .env ]; then
    echo "创建 .env 文件..."
    cp .env.example .env
    echo "请编辑 .env 文件配置你的 API 密钥（可选）"
fi

# 创建 Docker 网络
echo "创建 Docker 网络..."
docker network create nginx_network 2>/dev/null || echo "网络已存在"

# 构建并启动
echo "构建并启动服务..."
docker compose -f docker-compose.prod.yml up -d --build

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "服务状态:"
docker compose -f docker-compose.prod.yml ps
echo ""
echo "查看日志: docker compose -f docker-compose.prod.yml logs -f"
echo "停止服务: docker compose -f docker-compose.prod.yml down"
echo "重启服务: docker compose -f docker-compose.prod.yml restart"
echo ""
echo "健康检查: curl http://localhost:8787/api/health"
echo ""
echo "Nginx 配置文件位置: ./nginx/gpt-image-canvas.conf"
echo "请将此文件复制到你的 Nginx 配置目录，然后重载 Nginx"
echo ""
