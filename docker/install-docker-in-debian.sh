#!/bin/bash

# Docker安装脚本
set -e

# 更新包索引并安装依赖
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# 添加Docker GPG密钥
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 添加Docker仓库
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新包索引并安装Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 配置用户组
sudo groupadd -f docker
sudo usermod -aG docker $USER

echo "Docker安装完成！请重新登录或运行 'newgrp docker' 以使用户组生效。"