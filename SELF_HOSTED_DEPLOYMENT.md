# 🏠 Postiz 自建服务器部署指南

## 💰 成本对比

| 方案 | 月费用 | 功能完整度 | 性能 | 控制度 |
|------|--------|------------|------|--------|
| Render 免费 | $0 | 60% | 低 | 低 |
| Render 付费 | $25+ | 100% | 中 | 中 |
| **自建 VPS** | **$5-20** | **100%** | **高** | **高** |

## 🖥️ 推荐的 VPS 提供商

### 🏆 **高性价比选择：**

1. **腾讯云轻量应用服务器** ⭐⭐⭐⭐⭐
   - 2核4GB: ¥112/年 (~$16/年)
   - 国内访问速度快
   - 新用户有优惠

2. **阿里云 ECS**
   - 2核4GB: ¥300+/年
   - 稳定性好

3. **Vultr** ⭐⭐⭐⭐
   - 2GB RAM: $12/月
   - 全球节点，性能好

4. **DigitalOcean**
   - 2GB RAM: $12/月
   - 文档丰富，社区活跃

5. **搬瓦工 BandwagonHost** ⭐⭐⭐⭐⭐
   - 1GB RAM: $49.99/年
   - 便宜稳定，适合个人使用

## 🐳 Docker 一键部署（推荐）

### 步骤 1: 准备服务器
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 安装 Docker Compose
sudo apt install docker-compose -y

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker
```

### 步骤 2: 克隆项目
```bash
git clone https://github.com/bigbigwatermelon/postiz.git
cd postiz
```

### 步骤 3: 配置环境变量
```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件
nano .env
```

**必需的环境变量：**
```env
# 数据库配置
DATABASE_URL="postgresql://postiz:your_password@localhost:5432/postiz"
REDIS_URL="redis://localhost:6379"

# JWT 密钥（生成随机字符串）
JWT_SECRET="your-super-secret-jwt-key-here-make-it-long"

# 应用 URL（改为你的域名或 IP）
FRONTEND_URL="http://your-domain.com:4200"
NEXT_PUBLIC_BACKEND_URL="http://your-domain.com:3000"
BACKEND_INTERNAL_URL="http://localhost:3000"

# 存储设置
STORAGE_PROVIDER="local"
IS_GENERAL="true"
```

### 步骤 4: 一键启动
```bash
# 使用 Docker Compose 启动所有服务
docker-compose -f docker-compose.dev.yaml up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

## 🛠️ 手动部署（完全控制）

### 步骤 1: 安装依赖
```bash
# 安装 Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 安装 pnpm
npm install -g pnpm@10.6.1

# 安装 PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# 安装 Redis
sudo apt install redis-server -y

# 安装 PM2（进程管理器）
npm install -g pm2
```

### 步骤 2: 配置数据库
```bash
# 创建数据库用户
sudo -u postgres createuser --interactive
# 用户名: postiz
# 超级用户: y

# 创建数据库
sudo -u postgres createdb postiz

# 设置密码
sudo -u postgres psql
\password postiz
\q
```

### 步骤 3: 部署应用
```bash
# 克隆项目
git clone https://github.com/bigbigwatermelon/postiz.git
cd postiz

# 安装依赖
pnpm install

# 配置环境变量
cp .env.example .env
nano .env  # 编辑配置

# 生成 Prisma 客户端
pnpm run prisma-generate

# 初始化数据库
pnpm run prisma-db-push

# 构建项目
pnpm run build

# 使用 PM2 启动服务
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

## 🔧 PM2 配置文件

创建 `ecosystem.config.js`：

```javascript
module.exports = {
  apps: [
    {
      name: 'postiz-backend',
      script: 'pnpm',
      args: 'run start:prod:backend',
      cwd: '/path/to/postiz',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      }
    },
    {
      name: 'postiz-frontend',
      script: 'pnpm',
      args: 'run start:prod:frontend',
      cwd: '/path/to/postiz',
      env: {
        NODE_ENV: 'production',
        PORT: 4200
      }
    },
    {
      name: 'postiz-workers',
      script: 'pnpm',
      args: 'run start:prod:workers',
      cwd: '/path/to/postiz',
      env: {
        NODE_ENV: 'production'
      }
    },
    {
      name: 'postiz-cron',
      script: 'pnpm',
      args: 'run start:prod:cron',
      cwd: '/path/to/postiz',
      env: {
        NODE_ENV: 'production'
      }
    }
  ]
};
```

## 🌐 Nginx 反向代理配置

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # 前端
    location / {
        proxy_pass http://localhost:4200;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # 后端 API
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 🔒 SSL 证书（免费）

```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx -y

# 获取 SSL 证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo crontab -e
# 添加: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📊 监控和维护

### 系统监控
```bash
# 查看服务状态
pm2 status
pm2 logs

# 系统资源
htop
df -h
free -h

# 数据库状态
sudo -u postgres psql -c "\l"
```

### 自动备份脚本
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
sudo -u postgres pg_dump postiz > /backup/postiz_$DATE.sql
find /backup -name "postiz_*.sql" -mtime +7 -delete
```

## 🎯 总结

**自建服务器的优势：**
- 💰 **年费用 $16-100** vs Render 付费 $300+/年
- 🚀 **完整功能** - 支持所有 Worker、定时任务
- ⚡ **高性能** - 2核4GB vs 512MB限制
- 🎛️ **完全控制** - 想怎么配置就怎么配置
- 🔒 **数据安全** - 数据完全掌控在自己手中

**推荐配置：**
- **新手**：腾讯云轻量 2核4GB + Docker 部署
- **进阶**：VPS + 手动部署 + PM2 + Nginx
- **预算充足**：DigitalOcean + 完整监控体系

自建服务器确实是更好的选择！🎉 