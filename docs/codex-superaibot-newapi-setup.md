# Codex Desktop 接入 Superaibot NewAPI 中转站配置说明

本文档用于在另一台 Windows 机器上配置 Codex Desktop，使其连接到 `https://superaibot.ccwu.cc/v1`，默认使用 `gpt-5.5`，并在 Codex 模型下拉框中显示 NewAPI 中转站里的测试模型。

参考文档：

- Codex 配置参考：<https://developers.openai.com/codex/config-reference/>
- Codex 高级配置：<https://developers.openai.com/codex/config-advanced/>
- 阿里云 DashScope Responses API 兼容说明：<https://www.alibabacloud.com/help/en/model-studio/compatibility-with-openai-responses-api>

## 1. 目标效果

配置完成后：

- Codex Desktop 默认模型是 `gpt-5.5`。
- Codex 的模型下拉框可以看到 `deepseek-v4-pro`、`qwen3.7-max-2026-06-08`、`qwen3-coder-plus`、`glm-5.1` 等模型。
- 所有请求都走自己的 NewAPI 中转站：`https://superaibot.ccwu.cc/v1`。
- 可以在同一个 Codex 会话中通过模型下拉框切换模型。

注意：Codex 当前使用 OpenAI Responses API，即请求 `/v1/responses`。Claude Code 能用的 Anthropic-compatible Gateway 不等价于 Codex 可用。

## 2. 新机器准备

在新机器上先确认：

```powershell
codex --version
codex debug models --bundled
```

确保 `C:\Users\<你的用户名>\.codex` 目录存在。如果不存在，先启动一次 Codex Desktop 或运行一次：

```powershell
codex app
```

下面示例以用户为 `Administrator`。如果另一台机器用户名不同，把路径里的 `Administrator` 改成实际用户名。

## 3. 设置 API Key

建议用 Windows 用户环境变量保存中转站 Token，不要把真实 Key 写入文档或仓库。

```powershell
setx SUPERAIBOT_API_KEY "sk-你的-newapi-token"
```

执行后关闭 Codex Desktop，并重新打开终端或重启 Codex Desktop，让环境变量生效。

## 4. 生成模型目录文件

在新机器 PowerShell 中执行下面脚本。它会基于 Codex 自带的 GPT 模型目录，追加 Superaibot / NewAPI 的测试模型，并写入：

```text
C:\Users\Administrator\.codex\superaibot-models.json
```

脚本：

```powershell
$ErrorActionPreference = "Stop"

$codexHome = "$env:USERPROFILE\.codex"
New-Item -ItemType Directory -Force $codexHome | Out-Null

$raw = codex debug models --bundled
$catalog = $raw | ConvertFrom-Json
$template = $catalog.models | Where-Object { $_.slug -eq "gpt-5.5" } | Select-Object -First 1

$customModels = @(
  @{ slug = "deepseek-v4-pro"; display = "DeepSeek V4 Pro"; ctx = 131072 },
  @{ slug = "deepseek-v4-flash"; display = "DeepSeek V4 Flash"; ctx = 131072 },
  @{ slug = "qwen3.6-plus"; display = "Qwen 3.6 Plus"; ctx = 131072 },
  @{ slug = "qwen3-coder-plus"; display = "Qwen3 Coder Plus"; ctx = 131072 },
  @{ slug = "qwen3-max-2026-01-23"; display = "Qwen3 Max 2026-01-23"; ctx = 131072 },
  @{ slug = "qwen3-coder-next"; display = "Qwen3 Coder Next"; ctx = 131072 },
  @{ slug = "qwen3.5-plus"; display = "Qwen 3.5 Plus"; ctx = 131072 },
  @{ slug = "qwen3.7-max"; display = "Qwen 3.7 Max"; ctx = 131072 },
  @{ slug = "qwen3.7-max-2026-06-08"; display = "Qwen 3.7 Max 2026-06-08"; ctx = 131072 },
  @{ slug = "qwen3.7-max-2026-05-20"; display = "Qwen 3.7 Max 2026-05-20"; ctx = 131072 },
  @{ slug = "qwen3.7-max-2026-05-17"; display = "Qwen 3.7 Max 2026-05-17"; ctx = 131072 },
  @{ slug = "qwen3.7-max-preview"; display = "Qwen 3.7 Max Preview"; ctx = 131072 },
  @{ slug = "claude-opus-4-6"; display = "Claude Opus 4.6"; ctx = 200000 },
  @{ slug = "claude-opus-4-7"; display = "Claude Opus 4.7"; ctx = 200000 },
  @{ slug = "claude-sonnet-4-6"; display = "Claude Sonnet 4.6"; ctx = 200000 },
  @{ slug = "claude-haiku-4-5-20251001"; display = "Claude Haiku 4.5 20251001"; ctx = 200000 },
  @{ slug = "kimi-k2.5"; display = "Kimi K2.5"; ctx = 131072 },
  @{ slug = "kimi-k2.6"; display = "Kimi K2.6"; ctx = 131072 },
  @{ slug = "glm-5"; display = "GLM 5"; ctx = 131072 },
  @{ slug = "glm-5.1"; display = "GLM 5.1"; ctx = 131072 },
  @{ slug = "glm-4.7"; display = "GLM 4.7"; ctx = 131072 },
  @{ slug = "MiniMax-M2.5"; display = "MiniMax M2.5"; ctx = 131072 }
)

$priority = 40
foreach ($m in $customModels) {
  if ($catalog.models.slug -contains $m.slug) {
    continue
  }

  $json = $template | ConvertTo-Json -Depth 100
  $obj = $json | ConvertFrom-Json

  $obj.slug = $m.slug
  $obj.display_name = $m.display
  $obj.description = "Superaibot / NewAPI model: $($m.slug)"
  $obj.default_reasoning_level = $null
  $obj.supported_reasoning_levels = @()
  $obj.priority = $priority
  $obj.availability_nux = $null
  $obj.upgrade = $null
  $obj.context_window = $m.ctx
  $obj.max_context_window = $m.ctx
  $obj.truncation_policy.limit = [Math]::Min(10000, [int]($m.ctx * 0.9))

  $catalog.models += $obj
  $priority += 2
}

$target = Join-Path $codexHome "superaibot-models.json"
$output = $catalog | ConvertTo-Json -Depth 100
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($target, $output, $utf8NoBom)

Write-Host "Wrote $target"
```

## 5. 写入 config.toml

编辑：

```text
C:\Users\Administrator\.codex\config.toml
```

推荐最小配置如下。不要复制旧机器上的 `notify`、`mcp_servers.node_repl`、插件缓存路径，这些是本机运行时生成的，换机器会失效。

```toml
model_provider = "superaibot"
model = "gpt-5.5"
review_model = "gpt-5.5"
model_catalog_json = 'C:\Users\Administrator\.codex\superaibot-models.json'

disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true

# 不建议全局强制 reasoning/context。
# 非 OpenAI 模型可能不支持 GPT 的 reasoning 参数。
# model_reasoning_effort = "high"
# model_context_window = 1000000
# model_auto_compact_token_limit = 900000

[model_providers.superaibot]
name = "superaibot"
base_url = "https://superaibot.ccwu.cc/v1"
env_key = "SUPERAIBOT_API_KEY"
wire_api = "responses"
requires_openai_auth = true
```

如果新机器的 Codex 版本不识别 `env_key`，可以临时改成下面这种写法，但不推荐长期使用：

```toml
experimental_bearer_token = "sk-你的-newapi-token"
```

## 6. NewAPI 渠道要求

Codex 必须走 `/v1/responses`。因此 NewAPI 里给 Codex 用的渠道必须能处理 Responses API。

已验证可用的类型：

- `gpt-5.5`：走你的 ChatGPT / OpenAI 相关渠道。
- `qwen3.7-max-2026-06-08`：当前测试可用。
- `glm-5.1`：当前测试可用。

需要注意的类型：

- Claude Code 使用的是 Anthropic-compatible Gateway，通常走 `/v1/messages`。
- Codex 使用 OpenAI Responses，走 `/v1/responses`。
- Claude Code 能用的模型，不代表 Codex 一定能用。

阿里 Qwen Coder / Coding Plan 模型如果在 Codex 里报：

```text
stream disconnected before completion: stream closed before response.completed
```

通常说明 NewAPI 上游没有正确返回 Responses SSE 的 `response.completed`。此时优先检查 NewAPI 渠道，不要先改 Codex。

阿里 Responses 兼容地址应指向类似：

```text
https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1
```

最终 NewAPI 应能把 Codex 的请求转发到：

```text
https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1/responses
```

如果 NewAPI 渠道类型不允许填写完整路径，可以尝试使用“OpenAI”或“自定义 OpenAI 兼容”类型，而不是普通“阿里”类型。

## 7. 验证 Codex 是否读到模型目录

执行：

```powershell
codex debug models | ConvertFrom-Json | Select-Object -ExpandProperty models | Where-Object {
  $_.slug -in @("gpt-5.5", "qwen3.7-max-2026-06-08", "qwen3-coder-plus", "glm-5.1")
} | Select-Object slug, display_name, priority
```

应该能看到类似：

```text
gpt-5.5
qwen3.7-max-2026-06-08
qwen3-coder-plus
glm-5.1
```

## 8. 验证 NewAPI Responses 是否可用

执行：

```powershell
$key = $env:SUPERAIBOT_API_KEY
$headers = @{
  Authorization = "Bearer $key"
  "Content-Type" = "application/json"
}

$body = @{
  model = "qwen3.7-max-2026-06-08"
  input = "只回答 OK"
  stream = $false
  max_output_tokens = 20
} | ConvertTo-Json -Compress

$r = Invoke-WebRequest `
  -Uri "https://superaibot.ccwu.cc/v1/responses" `
  -Method Post `
  -Headers $headers `
  -Body $body `
  -TimeoutSec 60

$r.Content
```

返回 JSON 里如果有：

```json
"status": "completed"
```

说明该模型对 Codex 可用。

如果 `/v1/chat/completions` 可用，但 `/v1/responses` 不可用，Codex Desktop 仍然会失败。这个场景需要修 NewAPI 渠道或上游地址。

## 9. 使用方式

完成配置后：

1. 完全退出 Codex Desktop。
2. 重新打开 Codex Desktop。
3. 新建会话，默认应是 `gpt-5.5`。
4. 在输入框旁边的模型下拉框中选择测试模型。
5. 切换后先问一句 `你具体是什么模型？`，再到 NewAPI 后台看请求日志确认实际路由。

建议主力使用 `gpt-5.5`，测试时切换到 `qwen3.7-max-2026-06-08`、`glm-5.1`、`deepseek-v4-pro` 等已验证 Responses 可用的模型。

## 10. 常见问题

`model_not_found`：

模型名不是 NewAPI 可路由的真实模型名。注意 `ailiCodeingPlanPro` 是渠道名称，不是模型名。Codex 里应该选 `qwen3-coder-plus` 这类真实模型名。

`stream disconnected before completion`：

NewAPI 上游流式响应提前断开，或没有转换出 Responses API 需要的 `response.completed` 事件。先用第 8 节的非流式 `/v1/responses` 验证。

Claude Code 可以用，Codex 不可以：

这是协议不同。Claude Code 走 Anthropic `/v1/messages`，Codex 走 OpenAI `/v1/responses`。需要给 Codex 单独准备 Responses 可用的 NewAPI 渠道。

模型下拉框没有新增模型：

检查 `model_catalog_json` 路径是否正确，`superaibot-models.json` 是否是 UTF-8 无 BOM，并完全重启 Codex Desktop。

