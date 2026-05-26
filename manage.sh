#!/bin/bash

# GPT Image Canvas 管理脚本

COMPOSE_FILE="docker-compose.prod.yml"

case "$1" in
    start)
        echo "启动服务..."
        docker compose -f $COMPOSE_FILE up -d
        ;;
    stop)
        echo "停止服务..."
        docker compose -f $COMPOSE_FILE down
        ;;
    restart)
        echo "重启服务..."
        docker compose -f $COMPOSE_FILE restart
        ;;
    logs)
        docker compose -f $COMPOSE_FILE logs -f "${2:-gpt-image-canvas}"
        ;;
    status)
        docker compose -f $COMPOSE_FILE ps
        ;;
    build)
        echo "重新构建..."
        docker compose -f $COMPOSE_FILE up -d --build
        ;;
    backup)
        BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
        echo "备份数据到 $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        cp -r data "$BACKUP_DIR/"
        echo "备份完成: $BACKUP_DIR"
        ;;
    clean)
        echo "清理未使用的 Docker 资源..."
        docker system prune -f
        ;;
    health)
        echo "检查服务健康状态..."
        curl -f http://localhost:8787/api/health && echo "✓ 服务正常" || echo "✗ 服务异常"
        ;;
    *)
        echo "GPT Image Canvas 管理脚本"
        echo ""
        echo "用法: $0 {start|stop|restart|logs|status|build|backup|clean|health}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动服务"
        echo "  stop    - 停止服务"
        echo "  restart - 重启服务"
        echo "  logs    - 查看日志 (可选参数: 容器名)"
        echo "  status  - 查看服务状态"
        echo "  build   - 重新构建并启动"
        echo "  backup  - 备份数据目录"
        echo "  clean   - 清理 Docker 资源"
        echo "  health  - 检查服务健康状态"
        echo ""
        exit 1
        ;;
esac
