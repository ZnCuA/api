# 变量定义
PYTHON := python3
PIP := pip3
UVICORN := uvicorn
APP := main:app
PORT := 8000
WORKERS := 4

# 虚拟环境名称
VENV := venv

# 检测操作系统并设置合适的base64命令
ifeq ($(shell uname),Darwin)
    # macOS
    BASE64_CMD = base64 -i
else
    # Linux
    BASE64_CMD = base64 -w 0
endif

# 测试相关变量
TEST_AUDIO := test.mp3
TEST_PORT := $(PORT)
BASE64_AUDIO := $(shell [ -f $(TEST_AUDIO) ] && $(BASE64_CMD) $(TEST_AUDIO))
OUTPUT_AUDIO := output.mp3

# 默认目标
.DEFAULT_GOAL := help

.PHONY: help
help: ## 显示帮助信息
	@echo "使用方法:"
	@echo "  make <目标>"
	@echo ""
	@echo "目标:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: venv
venv: ## 创建虚拟环境
	$(PYTHON) -m venv $(VENV)
	@echo "请运行 'source $(VENV)/bin/activate' 来激活虚拟环境"

.PHONY: install
install: ## 安装依赖
	$(PIP) install -r requirements.txt

.PHONY: run
run: ## 启动开发服务器（单进程）
	$(UVICORN) $(APP) --reload --host 0.0.0.0 --port $(PORT)

.PHONY: start
start: ## 启动生产服务器（多进程）
	$(UVICORN) $(APP) --host 0.0.0.0 --port $(PORT) --workers $(WORKERS)

.PHONY: clean
clean: ## 清理临时文件和缓存
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.pyd" -delete
	find . -type f -name ".DS_Store" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name "*.egg" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".coverage" -delete
	find . -type d -name "htmlcov" -exec rm -rf {} +

.PHONY: test
test: prepare-test test-api test-api-invalid ## 运行所有测试（包括API测试）
	pytest

.PHONY: lint
lint: ## 运行代码检查
	flake8 .
	black --check .
	isort --check-only .

.PHONY: format
format: ## 格式化代码
	black .
	isort .

.PHONY: requirements
requirements: ## 更新requirements.txt
	$(PIP) freeze > requirements.txt 

.PHONY: test-api
test-api: ## 测试音频倒放API
	@echo "测试音频倒放API..."
	@curl -s -X POST "http://localhost:$(TEST_PORT)/reverse-audio" \
		-H "Content-Type: application/json" \
		-d '{"audio":"$(BASE64_AUDIO)","format":"mp3"}' | \
		tee response.json | jq '.' || echo "请确保已安装jq并且服务器正在运行"
	@echo "保存倒放后的音频到 $(OUTPUT_AUDIO)..."
	@jq -r .reversedAudio response.json | base64 -d > $(OUTPUT_AUDIO)
	@rm -f response.json
	@echo "音频已保存到 $(OUTPUT_AUDIO)"

.PHONY: test-api-invalid
test-api-invalid: ## 测试API错误处理
	@echo "测试无效格式..."
	@curl -s -X POST "http://localhost:$(TEST_PORT)/reverse-audio" \
		-H "Content-Type: application/json" \
		-d '{"audio":"invalid","format":"mp3"}' | \
		jq '.' || echo "请确保已安装jq并且服务器正在运行"
	
	@echo "\n测试不支持的格式..."
	@curl -s -X POST "http://localhost:$(TEST_PORT)/reverse-audio" \
		-H "Content-Type: application/json" \
		-d '{"audio":"$(BASE64_AUDIO)","format":"invalid"}' | \
		jq '.' || echo "请确保已安装jq并且服务器正在运行"

.PHONY: prepare-test
prepare-test: ## 准备测试音频文件
	@if [ ! -f $(TEST_AUDIO) ]; then \
		echo "生成测试音频文件..."; \
		ffmpeg -f lavfi -i "sine=frequency=1000:duration=5" -c:a libmp3lame $(TEST_AUDIO); \
	fi

.PHONY: clean-test
clean-test: ## 清理测试文件
	rm -f $(TEST_AUDIO) $(OUTPUT_AUDIO) response.json