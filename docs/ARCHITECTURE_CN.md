# QuantDinger 架构文档

本文档面向本地自托管部署和二次开发，基于当前仓库结构整理。

## 1. 总体架构

QuantDinger 是一个 Docker Compose 编排的自托管 AI 量化交易平台，核心由四类服务组成：

| 层级 | 组件 | 说明 |
| --- | --- | --- |
| 前端层 | `frontend` | 预构建 Vue 3 单页应用，由 Nginx 托管，默认访问端口 `8888`。 |
| API 层 | `backend` | Flask / Gunicorn 后端，提供认证、行情、策略、回测、交易、AI 分析等 API。 |
| 数据层 | `postgres` | PostgreSQL 16，保存用户、策略、回测、交易、凭证、账单等业务数据。 |
| 缓存层 | `redis` | Redis 7，用于缓存和部分异步/状态型能力。 |

默认访问链路：

```text
浏览器 -> http://localhost:8888 -> frontend(Nginx)
frontend -> http://backend:5000 -> Flask API
Flask API -> PostgreSQL / Redis / 外部行情源 / 交易所或券商 / LLM 服务
```

## 2. 目录结构

| 路径 | 作用 |
| --- | --- |
| `docker-compose.yml` | 标准本地部署入口，后端本地构建，前端拉取 GHCR 镜像。 |
| `docker-compose.ghcr.yml` | 轻量部署入口，前后端都使用预构建镜像。 |
| `docker-compose.build.yml` | 本地构建 Vue 前端时使用的 Compose 覆盖文件。 |
| `backend_api_python/` | 后端 Flask 项目。 |
| `backend_api_python/app/routes/` | API 路由层，按业务模块拆分。 |
| `backend_api_python/app/services/` | 业务服务层，封装策略、回测、AI、交易执行等核心逻辑。 |
| `backend_api_python/app/data_sources/` | 市场数据源适配。 |
| `backend_api_python/app/data_providers/` | 行情、新闻、指数、情绪、机会等数据提供能力。 |
| `backend_api_python/app/utils/` | 数据库、认证、缓存、加密、日志等通用工具。 |
| `backend_api_python/migrations/` | 初始化和版本迁移 SQL。 |
| `mcp_server/` | QuantDinger MCP Server，用于 Cursor、Claude Code、Codex 等 AI Agent 接入。 |
| `docs/` | 项目文档、使用指南、示例策略和截图。 |

## 3. 后端模块

主要 API 路由：

| 路由模块 | 功能 |
| --- | --- |
| `auth.py` / `user.py` | 登录、认证、用户管理。 |
| `dashboard.py` | 仪表盘数据聚合。 |
| `market.py` / `kline.py` / `global_market.py` | 市场、K 线和全球市场数据。 |
| `indicator.py` | 技术指标定义、计算和指标代码能力。 |
| `strategy.py` | 策略创建、管理、启动、停止和运行状态。 |
| `backtest.py` | 策略回测。 |
| `quick_trade.py` | 快速交易入口。 |
| `portfolio.py` | 投资组合、资产、持仓和收益监控。 |
| `credentials.py` | 交易所、券商、LLM 等凭证管理。 |
| `ai_chat.py` / `fast_analysis.py` | AI 对话和快速分析。 |
| `ibkr.py` / `mt5.py` / `alpaca.py` | IBKR、MT5、Alpaca 等交易通道适配。 |
| `billing.py` | 会员、积分、USDT 付费等运营能力。 |
| `health.py` | 健康检查。 |

主要服务：

| 服务模块 | 功能 |
| --- | --- |
| `strategy.py` / `strategy_lifecycle.py` | 策略生命周期管理。 |
| `strategy_compiler.py` / `strategy_script_runtime.py` | Python 策略编译与运行。 |
| `backtest.py` | 回测执行和结果计算。 |
| `trading_executor.py` | 策略实时执行器。 |
| `exchange_execution.py` | 交易所执行适配。 |
| `market_data_collector.py` / `kline.py` | 行情采集和 K 线处理。 |
| `llm.py` | LLM Provider 统一适配。 |
| `fast_analysis.py` | 快速 AI 分析流程。 |
| `portfolio_monitor.py` | 投资组合监控。 |
| `pending_order_worker.py` | 挂单/待执行订单后台处理。 |
| `signal_notifier.py` | 交易信号通知。 |
| `security_service.py` | 安全相关服务。 |

## 4. 数据与配置

运行配置集中在：

```text
backend_api_python/.env
```

关键配置：

| 配置 | 说明 |
| --- | --- |
| `SECRET_KEY` | JWT 和敏感数据加密相关密钥，必须使用随机强密钥。 |
| `ADMIN_USER` / `ADMIN_PASSWORD` | 默认管理员账号密码。 |
| `DATABASE_URL` | PostgreSQL 连接串。Compose 部署时默认连接 `postgres` 服务。 |
| `LLM_PROVIDER` 与各类 API Key | AI 分析和自然语言策略生成相关配置。 |
| `ENABLE_PENDING_ORDER_WORKER` | 是否启用待执行订单后台处理。 |
| `ENABLE_PORTFOLIO_MONITOR` | 是否启用组合监控。 |
| `AGENT_LIVE_TRADING_ENABLED` | AI Agent 是否允许实盘交易，默认应保持关闭。 |

## 5. 交易与安全边界

1. 默认部署可用于本地研究、模拟/纸面交易和策略验证。
2. 实盘交易前必须单独配置交易所或券商凭证，并确认平台、策略和风控参数。
3. API Key、交易凭证、LLM Key 应只写入本地 `.env` 或后台凭证管理，不要提交到 Git。
4. 首次登录后必须修改默认管理员密码。
5. 建议先使用小资金、只读权限或模拟账户完成验证，再逐步开放实盘权限。

## 6. AI Agent / MCP 架构

仓库包含 `mcp_server/`，可把 QuantDinger 暴露为 MCP 工具。典型链路：

```text
Cursor / Claude Code / Codex
  -> quantdinger-mcp
  -> QuantDinger Agent Gateway /api/agent/v1
  -> 策略、行情、回测、通知、凭证、交易等后端能力
```

建议先使用只读、工作区和回测权限；交易权限需要额外审查，并默认保持 paper-only。

