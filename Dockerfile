# 构建阶段
FROM python:3.11-slim as builder

# 安装构建依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制依赖文件
COPY requirements.txt .

# 创建虚拟环境并安装依赖
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt

# 最终阶段
FROM python:3.11-slim

# 安装ffmpeg
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 复制虚拟环境
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 设置工作目录
WORKDIR /app

# 复制应用代码
COPY main.py .
COPY start.sh .

# 设置权限
RUN chmod +x start.sh

# 设置环境变量
ENV PORT=8000
ENV HOST=0.0.0.0
ENV WORKERS=4

# 暴露端口
EXPOSE $PORT

# 启动命令
CMD ["./start.sh"] 