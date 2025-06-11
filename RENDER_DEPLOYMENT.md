# Postiz Render 部署指南

本指南将帮助您将 Postiz 应用部署到 Render 平台的免费计划。

## 前提条件

1. **Render 账户**: 在 [render.com](https://render.com) 注册免费账户
2. **GitHub 存储库**: 将代码推送到 GitHub 存储库
3. **Node.js**: 本地安装 Node.js 20+

## 快速部署

### 方法一：使用自动化脚本 (推荐)

```bash
# 运行自动部署脚本
./scripts/deploy-to-render.sh
```

### 方法二：手动部署

#### 步骤 1: 准备 Git 存储库

```bash
# 确保代码已推送到 GitHub
git add .
git commit -m "准备 Render 部署"
git push origin main
```

#### 步骤 2: 创建 Render 服务

1. 登录 [Render Dashboard](https://dashboard.render.com)
2. 点击 "New +" 按钮
3. 选择 "Blueprint"
4. 连接您的 GitHub 存储库
5. 选择包含 `render.yaml` 的存储库

#### 步骤 3: 配置环境变量

Render 会自动读取 `render.yaml` 中的配置，但您需要手动设置一些敏感的环境变量：

**必需的环境变量：**
```
JWT_SECRET=your-long-random-string-here
```

**可选的环境变量（用于社交媒体集成）：**
```
# Cloudflare R2 存储（推荐用于生产环境）
CLOUDFLARE_ACCOUNT_ID=your-account-id
CLOUDFLARE_ACCESS_KEY=your-access-key
CLOUDFLARE_SECRET_ACCESS_KEY=your-secret-access-key
CLOUDFLARE_BUCKETNAME=your-bucket-name
CLOUDFLARE_BUCKET_URL=https://your-bucket.r2.cloudflarestorage.com/

# 社交媒体 API
X_API_KEY=your-x-api-key
X_API_SECRET=your-x-api-secret
LINKEDIN_CLIENT_ID=your-linkedin-client-id
LINKEDIN_CLIENT_SECRET=your-linkedin-client-secret
```

## Render 免费计划限制

⚠️ **重要限制：**

1. **服务休眠**: 15分钟不活动后服务会休眠
2. **构建时间**: 每月限制构建时间
3. **数据库**: PostgreSQL 免费实例有存储限制
4. **内存**: 512MB RAM 限制
5. **网络**: 每月 100GB 带宽

## 部署后配置

### 1. 数据库初始化

部署完成后，需要初始化数据库：

```bash
# 通过 Render Shell 或 Web 终端运行
pnpm run prisma-db-push
```

### 2. 服务健康检查

确认所有服务正常运行：
- 前端服务: `https://your-app-name.onrender.com`
- 后端 API: `https://your-backend-name.onrender.com/health`

### 3. 配置域名（可选）

在 Render Dashboard 中：
1. 进入服务设置
2. 添加自定义域名
3. 配置 DNS 记录

## 故障排除

### 构建失败
```bash
# 检查构建日志
render logs --service your-service-name

# 本地测试构建
pnpm run build
```

### 内存不足
```bash
# 减少并发构建进程
export NODE_OPTIONS="--max-old-space-size=512"
```

### 数据库连接问题
- 确认 `DATABASE_URL` 环境变量正确设置
- 检查 Render PostgreSQL 服务状态

## 成本优化建议

1. **使用 Render 的自动休眠功能**来节省资源
2. **定期清理不用的服务**
3. **监控使用量**避免超出免费额度
4. **考虑升级到付费计划**如果需要更多资源

## 替代方案

如果免费计划不够用，考虑：
- **Railway**: 另一个类似的平台
- **Vercel + PlanetScale**: 前端 + 数据库分离部署
- **Heroku**: 传统的 PaaS 平台

## 支持

如果遇到问题：
1. 查看 [Render 文档](https://render.com/docs)
2. 检查项目的 GitHub Issues
3. 联系 Render 支持团队

---

🎉 **恭喜！您的 Postiz 应用现在已经部署到 Render 了！** 