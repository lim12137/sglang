# ChatGPT / Codex 桌面端高 CPU 复测与 Web 对照（2026-07-19 第二轮）

## 结论（给用户）

**不是「防火墙坏了」**，也不是「装错了客户端」。  
本机的 ChatGPT 桌面端 = **OpenAI Codex 合并版**（`OpenAI.Codex_*` / `ChatGPT.exe`）。  
高占用主因是：**桌面端 Codex 的 `git-repo-watcher` + `review_model` / `subscribe-live-query` 对超大 monorepo `M:\AI\1work`（及下面十几个子项目）高频跑 git**；Windows Defender 实时扫描（`MsMpEng`）在 git 风暴时会二次放大 CPU/IO。  

同客户端在别的系统不这样，通常是因为：  
1. 工作区小 / 不是巨型 monorepo；  
2. 没有 trust 整棵 `M:\AI\1work`；  
3. 没有空/残缺 `.git` 触发重试；  
4. 没有 Defender 对大量 git 读扫。

Web/社区同类问题：
- Codex 在空/损坏 `.git` 上 `git status` 死循环高 CPU（GitHub openai/codex 相关 issue 描述与本机 `gstak\.git` 残缺形态一致）。
- Windows 上 Codex 会话结束后后台仍高 CPU（讨论区常见）。
- ChatGPT 桌面 Electron 关窗仍后台、CPU 频率抬升的社区报告。

---

## 复测命令与结果摘要

### 1) 进程采样（约 3–4s Delta）

```powershell
Get-Process ChatGPT,codex,git,MsMpEng -ErrorAction SilentlyContinue
# 两次采样差分估算瞬时 CPU
```

| 组件 | 状态 | 瞬时 DeltaCPU/s（核秒） | 内存约 |
|------|------|-------------------------|--------|
| ChatGPT.exe 桌面（7 进程） | **已再次运行** | 主进程/渲染器 ≈ 0–0.09（空闲期） | 合计 ~674 MB |
| codex CLI（node 包装） | 2–3 路 | 0.01–0.29 | 合计 ~284 MB |
| git.exe | 采样瞬间 0 | — | — |
| MsMpEng | 常驻 | 空闲期 typeperf ~1.5–7.8% | WS ~690–705 MB |

说明：用户感觉「还是占多」时，任务管理器里可能混有：
- **ChatGPT 桌面**（多进程 Electron，内存大）；
- **codex.exe CLI**（当前 agent 会话，累计 CPU 高）；
- **MsMpEng**（被当成「安全中心/防火墙」）。

空闲期桌面瞬时 CPU 已不高；**启动/切项目/review 时**日志仍显示 git 风暴。

### 2) 铁证：桌面日志 git 风暴

路径：`%LOCALAPPDATA%\Codex\Logs\2026\07\19\`

| 日志 | git.command | abortedBeforeStart | watcher |
|------|-------------|--------------------|---------|
| `…21444-t1…041626…` | 622 | 264 | 9 |
| `…34584-t1…043155…` | 160 | 57 | 6 |
| `…17736-t1…044459…`（刚重启） | 46 | 42 | 6 |

- `requestKind`：`subscribe-live-query` × 数百  
- `source`：`review_model` 为主  
- 典型命令：`git rev-parse`、`git config --get remote.origin.url`、`ls-files` 等  

**高频 cwd（从日志提取）**：

| 次数（约） | 路径 |
|-----------|------|
| 73 | `M:/AI/1work` |
| 31 | `M:\AI\1work\llm\jtptllm_fresh\` |
| 31 | `M:\AI\1work\advisor\` |
| 29 | `M:\AI\1work\gstak\.claude\skills\gstack\` |
| 29 | `M:\AI\1work\clash-web\` |
| 28 | `M:\AI\1work\sglang\` 等十余个子仓 |

→ 桌面端在扫 **整棵 monorepo + 侧栏多个 workspace**，不是单仓库 sglang。

### 3) 配置状态

`~\.codex\config.toml`：

- 仅保留：`[projects.'m:\ai\1work\sglang'] trust_level = "trusted"`
- 已去除（上一轮）：`m:\ai\1work`、`c:\windows\system32` 信任
- 备份：`~\.codex\config.toml.bak-cpu-20260719-122214`

**注意**：去掉 monorepo trust **不能阻止** 已打开的桌面侧栏/历史 workspace 继续被 watcher 扫。

### 4) 残缺 `.git` 处理

- `M:\AI\1work\gstak\.git` 仅有 `hooks/pre-commit`（Children=1）— 与「空/损坏 .git 导致 git 重试」同类风险  
- `git rev-parse` 显示 gstak 实际挂在父仓 `M:/AI/1work`（非独立完整仓）  
- **已隔离**：  
  `M:\AI\1work\gstak\.git` → `M:\AI\1work\gstak\.git.bak-empty-20260719-124436`  
- 父仓 `M:\AI\1work\.git` 正常（约 290 MB / 7034 files）

### 5) 日志库膨胀

- `~\.codex\logs_2.sqlite` ≈ **226 MB**（持续写入）  
- 可能加重磁盘/Defender IO；建议后续轮转（退出 Codex 后重命名备份）

### 6) Defender / 防火墙

| 组件 | 角色 | 本次 |
|------|------|------|
| **MsMpEng** | 实时防护扫描 | 二次放大器；git 风暴时曾 IO 极高 |
| **mpssvc / BFE** | 防火墙 | 非元凶（近空闲） |
| **NisSrv** | 网络检查 | 近 0% |

无威胁检出风暴（非 1116/1117 告警型）。  
排除项脚本（需管理员）：`scripts/add-defender-dev-exclusions.ps1`  
当前用户无管理员权限，无法直接 `Add-MpPreference`。

---

## 为何「别的系统同一客户端」不这样

| 因素 | 本机 | 典型「正常」机 |
|------|------|----------------|
| 工作区 | 巨型 monorepo `M:\AI\1work` + 十几个子项目 | 单个小 repo |
| 侧栏/历史项目 | 多 workspace 被 review_model 订阅 | 少 |
| 残缺 `.git` | gstak 曾有空壳 `.git` | 无 |
| Defender | 扫大量 git 读 | 已排除 dev 目录或未装强扫 |
| 进程混淆 | 桌面 + 多路 CLI codex + MsMpEng | 仅聊天 |

客户端二进制同类；**差异在 Codex 项目图 + 环境**。

---

## 已执行动作

1. 确认桌面端再次运行（PID 主进程约 17736）  
2. 复测进程 / 日志 / config / `.git`  
3. 隔离 `gstak` 空壳 `.git`  
4. 确认 monorepo trust 已移除，仅 sglang trusted  
5. Web 对照：空 `.git` 死循环、Windows 后台高 CPU、Electron 常驻 — 与本机证据一致  

---

## 用户可立即做的（按优先级）

### A. 立刻降占用（无需管理员）

1. **完全退出 ChatGPT 桌面**（托盘图标右键退出，不要只关窗口）  
2. 任务管理器确认无 `ChatGPT.exe`  
3. 不要把 **整个 `M:\AI\1work`** 加为 Codex 项目；只开需要的子仓（如 `sglang`）  
4. 桌面侧栏关掉不用的 workspace / 历史线程对应的大仓  
5. 若暂时只要聊天：用浏览器 ChatGPT，避免桌面 Codex 模式  

### B. 管理员一次（强烈建议）

以管理员 PowerShell 运行仓库内：

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
& 'M:\AI\1work\sglang\scripts\add-defender-dev-exclusions.ps1'
```

建议排除至少：`M:\AI\1work`、`%USERPROFILE%\.codex`、git 路径。  
然后：

```powershell
typeperf '\Process(MsMpEng)\% Processor Time' -sc 10
```

### C. 可选清理

退出所有 Codex/ChatGPT 后：

```powershell
# 备份并清空过大日志库（可重建）
Move-Item $env:USERPROFILE\.codex\logs_2.sqlite `
  "$env:USERPROFILE\.codex\logs_2.sqlite.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
```

### D. 勿做

- 不要关 Windows 防火墙「治 CPU」  
- 不要长期关实时保护  
- 不要无确认杀掉当前正在用的 **CLI codex** 会话（PID 30892 等可能是本对话）

---

## 验收标准

| 检查 | 目标 |
|------|------|
| 退出桌面后 | 无 `ChatGPT.exe` |
| 只开 sglang 时 | 日志不再对 `M:/AI/1work` 整树 + 十余子仓狂扫 |
| `git.exe` 子进程 | 无持续父子链 `ChatGPT → git` |
| MsMpEng | typeperf 空闲 < 10–15%（有排除后更稳） |
| 任务管理器 | 「ChatGPT」不再长期高 CPU；内存 Electron 基线仍可能数百 MB（正常） |

---

## 相关文件

- 首轮报告：`docs/chatgpt-desktop-cpu-investigation-2026-07-19.md`
- Defender 报告：`docs/windows-defender-firewall-cpu-investigation-2026-07-19.md`
- 排除脚本：`scripts/add-defender-dev-exclusions.ps1`
- 配置备份：`~\.codex\config.toml.bak-cpu-20260719-122214`
- 空 .git 隔离：`M:\AI\1work\gstak\.git.bak-empty-20260719-124436`

## 采样时间

2026-07-19 12:43–12:46 Asia/Shanghai  
机器：DESKTOP-IUGH0MB / hopemyl
