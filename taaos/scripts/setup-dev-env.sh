#!/bin/bash
#
# TaaOS Development Environment Setup
# Installs popular libraries and tools for all major languages
#

set -e

echo "========================================="
echo "   TaaOS Development Environment Setup"
echo "========================================="
echo ""

# Python Development
echo "[1/5] Setting up Python environment..."
pip3 install --user \
    numpy pandas matplotlib seaborn \
    scikit-learn tensorflow pytorch \
    flask django fastapi \
    requests beautifulsoup4 selenium \
    pytest black flake8 mypy \
    jupyter notebook ipython \
    sqlalchemy redis pymongo \
    celery asyncio aiohttp \
    pydantic typer rich click

# Node.js Development
echo "[2/5] Setting up Node.js environment..."
npm install -g \
    typescript ts-node \
    @types/node @types/react \
    eslint prettier \
    jest mocha chai \
    webpack vite \
    express fastify \
    react vue @angular/cli \
    next create-react-app \
    prisma typeorm \
    pm2 nodemon \
    axios lodash moment

# Rust Development
echo "[3/5] Setting up Rust environment..."
cargo install \
    cargo-watch cargo-edit \
    cargo-audit cargo-outdated \
    ripgrep fd-find bat exa \
    tokei hyperfine \
    serde_json clap

# Go Development
echo "[4/5] Setting up Go environment..."
go install golang.org/x/tools/gopls@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Docker & Container Tools
echo "[5/5] Setting up Docker and container tools..."
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install common Docker images
docker pull python:3.11-slim
docker pull node:20-alpine
docker pull rust:latest
docker pull postgres:15-alpine
docker pull redis:7-alpine
docker pull nginx:alpine

echo ""
echo "========================================="
echo "   Development Environment Ready!"
echo "========================================="
echo "Please log out and back in for Docker group changes to take effect"
