#!/bin/bash

# Render 部署脚本
echo "🚀 开始部署 Postiz 到 Render..."

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Render CLI 是否已安装
if ! command -v render &> /dev/null; then
    echo -e "${YELLOW}⚠️  Render CLI 未安装，正在安装...${NC}"
    npm install -g @render-app/cli
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Render CLI 安装失败${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Render CLI 安装成功${NC}"
fi

# 检查是否已登录 Render
echo -e "${YELLOW}🔐 检查 Render 登录状态...${NC}"
if ! render auth whoami &> /dev/null; then
    echo -e "${YELLOW}🔑 请登录 Render 账户...${NC}"
    render auth login
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Render 登录失败${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Render 登录成功${NC}"

# 检查 render.yaml 文件是否存在
if [ ! -f "render.yaml" ]; then
    echo -e "${RED}❌ render.yaml 文件不存在${NC}"
    exit 1
fi

# 验证环境变量
echo -e "${YELLOW}🔍 验证部署配置...${NC}"

# 部署服务
echo -e "${YELLOW}🚀 开始部署服务...${NC}"
render deploy

if [ $? -eq 0 ]; then
    echo -e "${GREEN}🎉 部署成功！${NC}"
    echo -e "${GREEN}✅ 您的 Postiz 应用现在应该已经在 Render 上运行了${NC}"
    
    # 获取服务 URL
    echo -e "${YELLOW}📱 获取服务 URL...${NC}"
    render services list
    
    echo -e "${GREEN}💡 部署完成后的注意事项：${NC}"
    echo "1. 检查所有服务状态是否正常"
    echo "2. 配置域名（如果需要自定义域名）"
    echo "3. 设置环境变量（API keys 等）"
    echo "4. 运行数据库迁移"
    
else
    echo -e "${RED}❌ 部署失败${NC}"
    echo "请检查错误信息并重试"
    exit 1
fi 