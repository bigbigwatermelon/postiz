# 多阶段构建
FROM node:20-alpine AS base

# 安装必要的系统依赖
RUN apk add --no-cache libc6-compat python3 make g++
RUN npm install -g pnpm@10.6.1

WORKDIR /app

# 复制依赖文件
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/frontend/package.json ./apps/frontend/
COPY apps/backend/package.json ./apps/backend/
COPY apps/workers/package.json ./apps/workers/
COPY apps/cron/package.json ./apps/cron/
COPY libraries/*/package.json ./libraries/*/

# 安装依赖
RUN pnpm install --frozen-lockfile

# 复制源代码
COPY . .

# 生成 Prisma 客户端
RUN pnpm run prisma-generate

# 构建阶段
FROM base AS builder
RUN pnpm run build

# 生产阶段
FROM node:20-alpine AS runner
RUN apk add --no-cache libc6-compat
RUN npm install -g pnpm@10.6.1

WORKDIR /app

# 创建非 root 用户
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# 复制必要的文件
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=builder /app/apps/frontend/.next ./apps/frontend/.next
COPY --from=builder /app/apps/backend/dist ./apps/backend/dist
COPY --from=builder /app/apps/workers/dist ./apps/workers/dist
COPY --from=builder /app/libraries ./libraries

# 设置正确的权限
USER nextjs

EXPOSE 3000 4200

CMD ["sh", "-c", "if [ \"$SERVICE_TYPE\" = \"frontend\" ]; then pnpm run start:prod:frontend; elif [ \"$SERVICE_TYPE\" = \"backend\" ]; then pnpm run start:prod:backend; elif [ \"$SERVICE_TYPE\" = \"workers\" ]; then pnpm run start:prod:workers; else echo 'Please set SERVICE_TYPE environment variable'; fi"] 