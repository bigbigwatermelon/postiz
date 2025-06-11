#!/bin/bash

# 🏠 Postiz 自建服务器一键部署脚本
echo "🚀 开始部署 Postiz 到自建服务器..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查是否为 root 用户
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ 请不要使用 root 用户运行此脚本${NC}"
    exit 1
fi

# 检查操作系统
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo -e "${RED}❌ 此脚本仅支持 Linux 系统${NC}"
    exit 1
fi

echo -e "${BLUE}📋 系统信息：${NC}"
echo "操作系统: $(uname -s)"
echo "架构: $(uname -m)"
echo "用户: $(whoami)"
echo ""

# 检查并安装 Docker
echo -e "${YELLOW}🐳 检查 Docker 安装状态...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}📦 安装 Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✅ Docker 安装完成${NC}"
    echo -e "${YELLOW}⚠️  请重新登录或运行 'newgrp docker' 后再次执行此脚本${NC}"
    exit 0
else
    echo -e "${GREEN}✅ Docker 已安装${NC}"
fi

# 检查并安装 Docker Compose
echo -e "${YELLOW}🔧 检查 Docker Compose 安装状态...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}📦 安装 Docker Compose...${NC}"
    sudo apt update
    sudo apt install -y docker-compose
    echo -e "${GREEN}✅ Docker Compose 安装完成${NC}"
else
    echo -e "${GREEN}✅ Docker Compose 已安装${NC}"
fi

# 创建环境变量文件
echo -e "${YELLOW}⚙️  配置环境变量...${NC}"
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ 从 .env.example 创建了 .env 文件${NC}"
    else
        echo -e "${YELLOW}📝 创建默认 .env 文件...${NC}"
        cat > .env << EOL
# 数据库配置
DB_PASSWORD=postiz_secure_password_$(date +%s)
JWT_SECRET=postiz_jwt_secret_$(openssl rand -hex 32)

# 应用配置
NODE_ENV=production
FRONTEND_URL=http://localhost:4200
NEXT_PUBLIC_BACKEND_URL=http://localhost:3000
BACKEND_INTERNAL_URL=http://localhost:3000
STORAGE_PROVIDER=local
IS_GENERAL=true
API_LIMIT=30

# 可选：社交媒体 API keys（后续可以添加）
# X_API_KEY=
# X_API_SECRET=
# LINKEDIN_CLIENT_ID=
# LINKEDIN_CLIENT_SECRET=
EOL
        echo -e "${GREEN}✅ 创建了默认 .env 文件${NC}"
    fi
    
    echo -e "${BLUE}💡 提示：您可以编辑 .env 文件来配置社交媒体 API keys${NC}"
fi

# 创建必要的目录
echo -e "${YELLOW}📁 创建必要的目录...${NC}"
mkdir -p uploads
mkdir -p backups
sudo chown -R $USER:$USER uploads backups

# 启动服务
echo -e "${YELLOW}🚀 启动 Postiz 服务...${NC}"
docker-compose -f docker-compose.prod.yaml down
docker-compose -f docker-compose.prod.yaml build
docker-compose -f docker-compose.prod.yaml up -d

# 等待服务启动
echo -e "${YELLOW}⏳ 等待服务启动（约30秒）...${NC}"
sleep 30

# 初始化数据库
echo -e "${YELLOW}🗄️  初始化数据库...${NC}"
docker-compose -f docker-compose.prod.yaml exec -T backend pnpm run prisma-db-push

# 检查服务状态
echo -e "${YELLOW}🔍 检查服务状态...${NC}"
if docker-compose -f docker-compose.prod.yaml ps | grep -q "Up"; then
    echo -e "${GREEN}🎉 部署成功！${NC}"
    echo ""
    echo -e "${BLUE}📱 访问应用：${NC}"
    echo "前端: http://localhost:4200"
    echo "后端 API: http://localhost:3000"
    echo ""
    echo -e "${BLUE}🛠️  管理命令：${NC}"
    echo "查看日志: docker-compose -f docker-compose.prod.yaml logs -f"
    echo "停止服务: docker-compose -f docker-compose.prod.yaml down"
    echo "重启服务: docker-compose -f docker-compose.prod.yaml restart"
    echo ""
    echo -e "${BLUE}💡 下一步：${NC}"
    echo "1. 配置防火墙开放端口 4200 和 3000"
    echo "2. 设置域名和 SSL 证书"
    echo "3. 在 .env 中添加社交媒体 API keys"
    echo "4. 设置 Nginx 反向代理（可选）"
else
    echo -e "${RED}❌ 部署失败，请检查日志：${NC}"
    docker-compose -f docker-compose.prod.yaml logs
fi

# 创建备份脚本
echo -e "${YELLOW}💾 创建备份脚本...${NC}"
cat > scripts/backup.sh << 'EOL'
#!/bin/bash
# Postiz 数据库备份脚本

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"

echo "🗄️  开始备份数据库..."
docker-compose -f docker-compose.prod.yaml exec -T postgres pg_dump -U postiz postiz > ${BACKUP_DIR}/postiz_${DATE}.sql

if [ $? -eq 0 ]; then
    echo "✅ 备份成功: ${BACKUP_DIR}/postiz_${DATE}.sql"
    
    # 删除7天前的备份
    find ${BACKUP_DIR} -name "postiz_*.sql" -mtime +7 -delete
    echo "🧹 清理了7天前的旧备份"
else
    echo "❌ 备份失败"
fi
EOL

chmod +x scripts/backup.sh
echo -e "${GREEN}✅ 备份脚本已创建：scripts/backup.sh${NC}"

echo ""
echo -e "${GREEN}�� Postiz 部署完成！${NC}" 