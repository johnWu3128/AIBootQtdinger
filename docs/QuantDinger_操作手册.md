# QuantDinger 操作手册

> **版本**：基于 commit `c01de70`（2026-10-21）  
> **作者**：AIBootQtdinger 部署版  
> **仓库**：https://github.com/johnWu3128/AIBootQtdinger  
> **适用系统**：Windows 10/11（Podman Desktop + WSL2）

---

## 目录

1. [系统要求](#1-系统要求)
2. [首次安装部署](#2-首次安装部署)
3. [日常使用——启动与停止](#3-日常使用启动与停止)
4. [功能界面说明](#4-功能界面说明)
5. [AI 量化助手使用](#5-ai-量化助手使用)
6. [自选股管理](#6-自选股管理)
7. [策略与回测](#7-策略与回测)
8. [常见问题排查](#8-常见问题排查)
9. [更新升级流程](#9-更新升级流程)

---

## 1. 系统要求

| 组件 | 最低要求 |
|------|---------|
| 操作系统 | Windows 10 21H2+ / Windows 11 |
| 内存 | 8 GB（推荐 16 GB） |
| 磁盘 | 20 GB 可用空间 |
| Podman Desktop | v1.13+ |
| WSL2 | 已启用 |
| Python | 3.10+（运行辅助脚本时需要） |

---

## 2. 首次安装部署

### 2.1 安装 Podman Desktop

1. 前往 https://podman-desktop.io 下载安装包
2. 安装时勾选 **"Install WSL2"** 和 **"Install Podman Machine"**
3. 安装完成后，桌面右下角托盘会出现 Podman 图标

### 2.2 初始化 Podman Machine

双击项目目录中的 **`初始化Podman_Machine.bat`**：

```
初始化Podman_Machine.bat
```

或手动执行：

```powershell
podman machine init
podman machine start
```

**验证成功：**

```powershell
podman ps
# 输出：CONTAINER ID  IMAGE  COMMAND  CREATED  STATUS  PORTS  NAMES（空列表即正常）
```

### 2.3 克隆项目

```bash
git clone https://github.com/johnWu3128/AIBootQtdinger.git quandtinger
cd quandtinger
```

### 2.4 配置环境变量

复制示例配置文件：

```bash
cp backend_api_python/.env.example backend_api_python/.env
```

编辑 `.env`，填入你的 API Key：

```env
# AI 服务（必填其一）
OPENAI_API_KEY=sk-xxxxxxxx
# 或
ANTHROPIC_API_KEY=sk-ant-xxxxxxxx

# 数据源（可选，提升行情质量）
POLYGON_API_KEY=xxxxxxxx

# 安全密钥（建议修改）
SECRET_KEY=your-random-secret-key-here
```

### 2.5 启动服务

双击桌面的 **`QuantDinger_Start.bat`**，或执行：

```powershell
podman compose -f docker-compose.yml -f docker-compose.podman.yml up -d
```

等待约 1-2 分钟，看到以下输出表示成功：

```
quantdinger-db        Up (healthy)   127.0.0.1:5432->5432/tcp
quantdinger-redis     Up (healthy)   127.0.0.1:6379->6379/tcp
quantdinger-backend   Up (healthy)   127.0.0.1:5000->5000/tcp
quantdinger-frontend  Up (healthy)   0.0.0.0:8888->80/tcp
```

### 2.6 访问系统

打开浏览器，访问：

```
http://localhost:8888
```

首次访问需要注册账号（本地账号，数据存本机）。

---

## 3. 日常使用——启动与停止

### 启动

每次开机后 Podman Machine 需要重新启动：

**方式一：双击 `QuantDinger_Start.bat`**（推荐）

```bat
REM 内部逻辑：
podman machine start
podman compose -f docker-compose.yml -f docker-compose.podman.yml up -d
```

**方式二：命令行**

```powershell
podman machine start
cd D:\javaEE\IdeaProjects\baosight\tools\quandtinger
podman compose -f docker-compose.yml -f docker-compose.podman.yml up -d
```

### 停止

**双击 `QuantDinger_Stop.bat`**，或：

```powershell
podman compose down
```

> 💡 数据存储在 Podman volume 中，停止容器不会丢失数据。

### 查看日志

**双击 `QuantDinger_Logs.bat`**，或：

```powershell
podman compose logs -f --tail=100
```

---

## 4. 功能界面说明

访问 `http://localhost:8888` 后，主界面分为以下模块：

### 4.1 行情看板（Dashboard）

- **实时行情**：展示自选股的最新价格、涨跌幅
- **大盘概况**：主要指数（SPY、QQQ、BTC 等）一览
- **热门板块**：按涨跌幅排名的行业板块

### 4.2 图表分析（Charts）

- 支持 K 线图、指标叠加（MA、MACD、RSI、布林带等）
- 支持多周期切换（1m / 5m / 1h / 1D / 1W）
- 支持手动画线、标注

### 4.3 AI 助手（AI Chat）

> 见 [第 5 节](#5-ai-量化助手使用)

### 4.4 自选股（Watchlist）

> 见 [第 6 节](#6-自选股管理)

### 4.5 策略工坊（Strategy）

> 见 [第 7 节](#7-策略与回测)

---

## 5. AI 量化助手使用

### 5.1 基本对话

在右侧 AI Chat 面板输入问题，例如：

```
分析一下 NVDA 近期的技术面走势
```

```
帮我写一个基于 RSI 超卖反弹的 Python 策略
```

### 5.2 图表联动分析

1. 先在图表区打开某只股票（如 AAPL）
2. 点击图表右上角的 **"AI分析"** 按钮
3. AI 会自动读取当前图表数据，给出技术分析

### 5.3 策略生成

在 AI Chat 中输入：

```
帮我生成一个双均线金叉策略，适合 A 股日线，用 Python 实现
```

AI 会输出完整的 Python 策略代码，可直接复制到策略工坊运行。

### 5.4 配置 AI 服务商

在 **Settings → AI Provider** 中可以切换：

| 服务商 | 模型 | 特点 |
|--------|------|------|
| OpenAI | GPT-4o | 综合最强 |
| Anthropic | Claude 3.5 | 代码能力强 |
| 本地 Ollama | Llama3/Qwen | 离线使用，免费 |

---

## 6. 自选股管理

### 6.1 添加股票

1. 点击顶部搜索框（快捷键 `/`）
2. 输入股票代码或名称，如 `AAPL` 或 `苹果`
3. 点击 **"添加到自选"** ⭐

支持的市场：
- 🇺🇸 美股（NYSE / NASDAQ）
- 🇨🇳 A股（沪深两市）
- 🪙 加密货币（BTC / ETH 等）
- 📦 期货（黄金 / 原油等）

### 6.2 管理分组

在 **Watchlist** 页面可以：
- 新建分组（如"科技股"、"B圈"）
- 拖拽调整排序
- 设置价格提醒（触达目标价时系统通知）

### 6.3 导入导出

```
Watchlist → 右上角 ··· → 导出 CSV
Watchlist → 右上角 ··· → 导入 CSV
```

CSV 格式：

```csv
symbol,market,note
AAPL,us,苹果
600519,cn,茅台
BTC/USDT,crypto,比特币
```

---

## 7. 策略与回测

### 7.1 使用内置策略

进入 **Strategy → Library**，可以看到内置策略模板：

| 策略名 | 类型 | 适合市场 |
|--------|------|---------|
| 双均线金叉 | 趋势跟随 | 股票/期货 |
| RSI 超买超卖 | 均值回归 | 股票/加密 |
| 布林带突破 | 波动突破 | 适合所有 |
| MACD 动量 | 趋势 + 动量 | 股票 |

### 7.2 自定义 Python 策略

点击 **New Strategy**，在代码编辑器中编写：

```python
def strategy(df, params):
    """
    df: pandas DataFrame，包含 open/high/low/close/volume
    params: 策略参数字典
    返回: signals Series（1=买入，-1=卖出，0=持有）
    """
    fast = params.get('fast_period', 5)
    slow = params.get('slow_period', 20)
    
    df['ma_fast'] = df['close'].rolling(fast).mean()
    df['ma_slow'] = df['close'].rolling(slow).mean()
    
    signals = pd.Series(0, index=df.index)
    signals[df['ma_fast'] > df['ma_slow']] = 1
    signals[df['ma_fast'] < df['ma_slow']] = -1
    
    return signals
```

### 7.3 回测

1. 选择策略和标的
2. 设置回测区间（如 2023-01-01 ~ 2024-01-01）
3. 设置初始资金（如 10万）
4. 点击 **Run Backtest**

回测结果包括：
- 总收益率 / 年化收益率
- 最大回撤
- 夏普比率
- 胜率 / 盈亏比
- 完整交易记录

---

## 8. 常见问题排查

### Q1：双击启动脚本，提示"Cannot connect to Podman"

**原因**：Podman Machine 未启动

**解决**：

```powershell
podman machine start
```

等待 20-30 秒，再重试启动脚本。

---

### Q2：启动后访问 8888 端口无法打开

**检查步骤**：

```powershell
# 查看容器状态
podman ps

# 如果 frontend 不健康，查看日志
podman logs quantdinger-frontend

# 检查端口是否被占用
netstat -ano | findstr :8888
```

---

### Q3：known_hosts 报 "illegal base64 data"

**原因**：SSH known_hosts 文件被 Windows 工具写入了 UTF-16 乱码

**解决**：运行 Python 脚本修复

```python
# 保存为 fix_known_hosts.py 运行
with open(r'C:\Users\Administrator\.ssh\known_hosts', 'rb') as f:
    raw = f.read()
lines = raw.split(b'\n')
valid = [l for l in lines if l and b'\x00' not in l and (b'ssh-' in l or b'ecdsa-' in l)]
with open(r'C:\Users\Administrator\.ssh\known_hosts', 'wb') as f:
    f.write(b'\n'.join(valid) + b'\n')
```

---

### Q4：AI 对话没有响应

**检查**：
1. 确认 `.env` 中的 API Key 已正确填写
2. 检查网络是否能访问 AI 服务商
3. 查看 backend 日志：`podman logs quantdinger-backend`

---

### Q5：行情数据不更新

**原因**：免费数据源有频率限制

**解决**：
- 注册 [Polygon.io](https://polygon.io) 免费账号，获取 API Key
- 在 `.env` 中填入 `POLYGON_API_KEY=xxxx`
- 重启 backend：`podman restart quantdinger-backend`

---

## 9. 更新升级流程

### 9.1 拉取上游最新代码

```powershell
cd D:\javaEE\IdeaProjects\baosight\tools\quandtinger

# 从上游（原始仓库）拉取新代码
git fetch origin
git merge origin/main

# 推送到你的 fork
git push aiboot main
```

### 9.2 重新拉取 Docker 镜像

```powershell
podman compose -f docker-compose.yml -f docker-compose.podman.yml pull
podman compose -f docker-compose.yml -f docker-compose.podman.yml up -d
```

### 9.3 数据库迁移（如有）

新版本如果有数据库变更，需要运行迁移：

```powershell
podman exec quantdinger-backend python -m alembic upgrade head
```

---

## 附录：快速命令速查

| 操作 | 命令 |
|------|------|
| 启动全部服务 | `podman compose up -d` |
| 停止全部服务 | `podman compose down` |
| 查看容器状态 | `podman ps` |
| 查看实时日志 | `podman compose logs -f` |
| 重启某个服务 | `podman restart quantdinger-backend` |
| 进入容器 Shell | `podman exec -it quantdinger-backend bash` |
| 备份数据库 | `podman exec quantdinger-db pg_dump -U postgres quantdinger > backup.sql` |
| 恢复数据库 | `podman exec -i quantdinger-db psql -U postgres quantdinger < backup.sql` |

---

*文档生成时间：2026-10-21 | QuantDinger v1.x | Windows Podman 部署版*
