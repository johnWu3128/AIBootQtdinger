# QuantDinger 使用文档

本文档描述本地部署完成后如何使用 QuantDinger。默认地址和账号基于当前仓库的 Docker Compose 配置。

## 1. 启动和访问

当前机器使用 Podman Desktop / Podman Compose。在项目根目录执行：

```powershell
$env:Path = "$env:APPDATA\Python\Python313\Scripts;$env:Path"
podman compose -f docker-compose.yml -f docker-compose.podman.yml pull
podman compose -f docker-compose.yml -f docker-compose.podman.yml up -d
podman compose -f docker-compose.yml -f docker-compose.podman.yml ps
```

访问：

```text
http://localhost:8888
```

默认管理员：

```text
用户名：quantdinger
密码：123456
```

首次登录后请立刻修改密码。

## 2. 停止、重启和查看日志

```powershell
# 查看服务状态
podman compose -f docker-compose.yml -f docker-compose.podman.yml ps

# 查看后端日志
podman logs -f quantdinger-backend

# 查看前端日志
podman logs -f quantdinger-frontend

# 重启后端
podman restart quantdinger-backend

# 停止全部服务
podman compose -f docker-compose.yml -f docker-compose.podman.yml down
```

如果修改了 `backend_api_python/.env`，通常需要重启后端：

```powershell
podman restart quantdinger-backend
```

## 3. 首次配置建议

登录后台后按下面顺序配置：

1. 修改管理员密码。
2. 检查系统设置和时区。
3. 配置至少一个 LLM Provider，用于 AI 分析。
4. 先配置模拟或低权限交易凭证，不要直接配置高权限实盘 Key。
5. 创建一个简单策略并完成回测。
6. 确认通知渠道可用。
7. 再考虑启用自动交易或实盘执行。

## 4. 配置 AI 分析

编辑：

```text
backend_api_python/.env
```

常见配置项：

```ini
LLM_PROVIDER=openrouter
OPENROUTER_API_KEY=你的 OpenRouter Key

# 或使用 OpenAI
LLM_PROVIDER=openai
OPENAI_API_KEY=你的 OpenAI Key
```

保存后重启后端：

```powershell
podman restart quantdinger-backend
```

进入前端的 AI 分析或快速分析页面，选择标的并发起分析。

## 5. 创建和回测策略

推荐流程：

1. 进入策略或指标相关页面。
2. 新建策略，选择策略类型或粘贴 Python 策略代码。
3. 设置标的、周期、资金和策略参数。
4. 先执行回测。
5. 查看收益、回撤、胜率、交易次数和交易明细。
6. 调整参数后再次回测。
7. 多次验证后再进入模拟运行。

策略开发参考：

- `docs/STRATEGY_DEV_GUIDE_CN.md`
- `docs/examples/dual_ma_with_params.py`
- `docs/examples/multi_indicator_composite.py`
- `docs/examples/cross_sectional_momentum_rsi.py`

## 6. 模拟运行策略

完成回测后：

1. 确认策略参数。
2. 确认交易账户处于模拟或低风险模式。
3. 启动策略。
4. 观察运行日志、订单、持仓和组合变化。
5. 若出现异常，立即停止策略并查看 `docker compose logs -f backend`。

## 7. 配置交易账户

进入凭证或 Broker Accounts 页面，按平台提示添加交易所或券商信息。

常见注意事项：

- 先用只读权限验证连接。
- 实盘 API Key 不要开启提现权限。
- 使用 IP 白名单。
- 小资金试运行。
- 给每个策略设置最大仓位、最大亏损和止损逻辑。

## 8. 使用通知

可按需配置 Telegram、邮件、SMS、Discord 或 Webhook。配置完成后先发送测试通知，再绑定到策略信号或异常告警。

通知配置参考：

- `docs/NOTIFICATION_TELEGRAM_CONFIG_CH.md`
- `docs/NOTIFICATION_EMAIL_CONFIG_CH.md`
- `docs/NOTIFICATION_SMS_CONFIG_CH.md`

## 9. 使用 MCP / AI Agent

部署完成后，在前端创建 Agent Token，然后在 Cursor、Claude Code 或 Codex 中配置 MCP。

基础配置示例：

```json
{
  "mcpServers": {
    "quantdinger": {
      "command": "uvx",
      "args": ["quantdinger-mcp"],
      "env": {
        "QUANTDINGER_BASE_URL": "http://localhost:8888",
        "QUANTDINGER_AGENT_TOKEN": "qd_agent_xxxxxxxx"
      }
    }
  }
}
```

建议 Token 权限：

| 阶段 | 建议权限 |
| --- | --- |
| 初次接入 | Read |
| 策略开发 | Read、Workspace、Backtest |
| 自动通知 | Read、Workspace、Backtest、Notify |
| 实盘交易 | 仅在严格风控后开放 Trading |

详细参考：

- `docs/agent/MCP_SETUP.md`
- `docs/agent/AGENT_QUICKSTART.md`

## 10. 常见问题

### 10.1 页面打不开

检查服务状态：

```powershell
podman compose -f docker-compose.yml -f docker-compose.podman.yml ps
podman logs -f quantdinger-frontend
podman logs -f quantdinger-backend
```

确认端口：

- 前端：`8888`
- 后端：`5000`
- PostgreSQL：`5432`
- Redis：`6379`

### 10.2 后端启动失败

重点检查：

- `backend_api_python/.env` 是否存在。
- `SECRET_KEY` 是否已经替换为随机值。
- Docker 是否能拉取 Python、PostgreSQL、Redis 和 GHCR 镜像。
- `DATABASE_URL` 是否与 Compose 中的数据库配置一致。

### 10.3 AI 分析不可用

检查：

- `LLM_PROVIDER` 是否设置。
- 对应 API Key 是否设置。
- 当前网络是否能访问该 Provider。
- 后端是否已重启。

### 10.4 Docker 拉取镜像很慢或失败

国内环境可能需要配置 Docker Desktop 代理或镜像源。可在项目根目录 `.env` 中设置：

```ini
IMAGE_PREFIX=docker.m.daocloud.io/library/
```

然后重新执行：

```powershell
podman compose -f docker-compose.yml -f docker-compose.podman.yml pull
podman compose -f docker-compose.yml -f docker-compose.podman.yml up -d
```
