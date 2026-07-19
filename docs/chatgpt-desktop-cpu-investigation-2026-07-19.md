# ChatGPT/Codex 本地应用后台高 CPU 调查报告

- **日期**: 2026-07-19
- **机器**: Windows, 12 逻辑核心
- **现象**: 任务管理器中 `ChatGPT.exe` 在后台持续占用 CPU

## 1. 结论（先说结果）

本地「ChatGPT」进程**不是** chatgpt.com 网页壳，而是 **OpenAI Codex 桌面端（MSIX）**：

- 路径: `C:\Program Files\WindowsApps\OpenAI.Codex_26.707.12708.0_x64__2p2nqsd0c76g0\app\ChatGPT.exe`
- 包名: `OpenAI.Codex`
- 用户数据: `%APPDATA%\Codex`、`%LOCALAPPDATA%\Codex`、`%USERPROFILE%\.codex`

**主要根因**: 桌面端内置 `git-repo-watcher` + `review_model` 的 `subscribe-live-query`，对 **巨型 monorepo `M:\AI\1work`** 及其大量嵌套仓库高频执行 `git rev-parse / status / write-tree` 等命令，形成轮询风暴，导致主进程与渲染进程持续占 CPU。

**次要占用**: 终端中另有 **2 路 Codex CLI**（`node …/codex.js` → `codex.exe`），其中一路为当前会话，属正常工作负载。

## 2. 采样数据

### 2.1 进程树（问题发生时）

| 角色 | 进程 | 说明 |
|------|------|------|
| 桌面主进程 | ChatGPT.exe (PID 21444) | 由 explorer 启动 |
| GPU | ChatGPT.exe --type=gpu-process | Chromium GPU |
| 渲染 | ChatGPT.exe --type=renderer ×2 | UI |
| 网络/存储 | utility processes | 常规 |
| 桌面 app-server | `resources\codex.exe … app-server` | 桌面内嵌 codex |
| CLI #1 | node codex.js → codex.exe | Windows Terminal |
| CLI #2 | node codex.js → codex.exe | Windows Terminal |

### 2.2 CPU 采样（约 3–4 秒）

| 采样点 | 高占用进程 | 估测（单核%） |
|--------|------------|---------------|
| 桌面打开时 | ChatGPT renderer / main | ~11% / 后续 main ~27% |
| 桌面打开时 | CLI codex (30892) | ~24–34%（会话活动） |
| **关闭桌面后** | ChatGPT.exe | **全部消失** |
| 关闭桌面后 | CLI codex (30892) | 仍有会话占用（预期） |

### 2.3 日志证据

日志: `%LOCALAPPDATA%\Codex\Logs\2026\07\19\codex-desktop-…-21444-….log`

- 该日志 **601 行几乎全部为 git 相关**
- `warning [git]` **584 条 / ~291 秒 ≈ 2 次/秒**
- subcommand 分布: `rev-parse` 537, `add` 33, `read-tree` 7, `status` 2, `write-tree` 1
- source **全部为** `review_model`
- requestKind: `subscribe-live-query`
- failureReason: `waitFailed` 289, `abortedBeforeStart` 264（命令被频繁中止/踩踏）
- 首行: `info [git-repo-watcher] Starting git repo watcher`
- cwd 覆盖 monorepo 及大量子路径，例如:
  - `M:/AI/1work`
  - `M:\AI\1work\llm\…`
  - `M:\AI\1work\gstak\…`
  - `M:\AI\1work\clash-web\`
  - 等

### 2.4 仓库侧放大因素

```text
M:\AI\1work
  .git ~290 MB
  tracked files: 566（顶层索引规模看似不大，但含大量嵌套项目/worktree）
  git status --porcelain: 244 行脏状态
  config 曾将整个 monorepo 标为 trusted:
    [projects.'m:\ai\1work'] trust_level = "trusted"
```

单次 `rev-parse`/`write-tree` 约 40ms，但 **~2/s 连续失败重试** 会叠加到 Electron 主进程 + 多 renderer 的后台开销。

### 2.5 其它观察

- `~/.codex/logs_2.sqlite` ≈ **226 MB**（持续写入，放大磁盘/IO）
- 未发现经典 `HKCU\...\Run` 启动项；桌面由 explorer 用户启动（StartTime 当天 12:15）
- 存在旧版非 MSIX 残留: `%LOCALAPPDATA%\Codex\app-26.325.31654\`（非本次 CPU 主因）

## 3. 根因机制（简化）

```text
Codex Desktop (ChatGPT.exe)
  └─ git-repo-watcher
  └─ review_model subscribe-live-query
       └─ 高频 git 命令扫描 trusted 项目树 M:\AI\1work
            ├─ 多嵌套仓库 / worktree
            ├─ 大量 dirty 文件
            └─ 命令被 abort/waitFailed → 再触发 → CPU 空转
```

因此表现为「应用关到托盘/后台仍转 CPU」：watcher 不随窗口最小化而停。

## 4. 已执行处理

1. **结束 Codex 桌面端进程树**（`ChatGPT.exe` + 内嵌 `app-server`）
   - 验证: `Get-Process ChatGPT` 已无输出
2. **收紧 `~/.codex/config.toml` 信任范围**
   - 备份: `~/.codex/config.toml.bak-cpu-20260719-122214`
   - 删除:
     - `[projects.'m:\ai\1work'] trust_level = "trusted"`
     - `[projects.'c:\windows\system32'] trust_level = "trusted"`（异常信任）
   - 保留: `[projects.'m:\ai\1work\sglang'] trust_level = "trusted"`

3. **未强杀** 终端内 Codex CLI（含当前会话），避免中断正常工作。

## 5. 建议的长期策略

### 立刻（推荐）

| 动作 | 目的 |
|------|------|
| 不用时完全退出 Codex 桌面（托盘右键退出），优先用 CLI | 消灭 git-repo-watcher |
| 工作区打开**具体子仓库**（如 `sglang`），不要打开整个 `M:\AI\1work` | 缩小 watcher 范围 |
| 设置 → 应用 → 启动：关闭 OpenAI Codex / ChatGPT 开机启动（若启用） | 避免登录后后台驻留 |
| 可选: 清理/轮转 `~/.codex/logs_2.sqlite`（226MB） | 降 IO |

### 仓库卫生（降低 git 成本）

- 不要把大量无关项目放进**同一个** git 根 `M:\AI\1work`
- 将二进制、coverage、worktree 噪音加入 `.gitignore`
- 避免在 monorepo 根长期保持 200+ dirty 文件

### 若必须常开桌面

1. 仅信任小仓库路径（已做）
2. 桌面设置里关闭与 Review / 实时 git / 多项目索引相关的选项（以当前 UI 为准）
3. 升级到最新 Codex 桌面（包版本 `26.707.*`）；若仍复现，向 OpenAI 反馈 `git-repo-watcher` + `review_model` 轮询风暴日志

### 可选激进手段

- 不用桌面时卸载 MSIX Codex，仅保留 npm `@openai/codex` CLI
- 清理旧 Electron 残留 `%LOCALAPPDATA%\Codex\app-*`

## 6. 复现/验证命令

```powershell
# 当前 ChatGPT/codex 进程
Get-Process ChatGPT,codex -ErrorAction SilentlyContinue |
  Select-Object Id,ProcessName,CPU,WS,StartTime

# 3 秒 CPU 增量
$n=@('ChatGPT','codex'); $a=Get-Process $n -EA 0|select Id,ProcessName,CPU
Start-Sleep 3; $b=Get-Process $n -EA 0|select Id,ProcessName,CPU
foreach($x in $a){ $y=$b|? Id -eq $x.Id; if($y){ '{0} {1} +{2}s ~{3}%' -f $x.Id,$x.ProcessName,[math]::Round($y.CPU-$x.CPU,3),[math]::Round((($y.CPU-$x.CPU)/3)*100,1) } }

# 最新桌面日志里的 git 风暴
Get-ChildItem "$env:LOCALAPPDATA\Codex\Logs" -Recurse -File |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1 |
  ForEach-Object { Select-String -Path $_.FullName -Pattern 'git-repo-watcher|subscribe-live-query|warning \[git\]' | Measure-Object }

# 配置信任范围
Get-Content $env:USERPROFILE\.codex\config.toml
```

## 7. 验收结果

| 检查项 | 结果 |
|--------|------|
| 桌面 ChatGPT.exe 是否仍驻留 | 否（已停止） |
| monorepo 全局 trust 是否移除 | 是 |
| CLI 会话是否保留 | 是 |
| 根因是否有日志证据 | 是（~2 git ops/s，source=review_model） |

## 8. 测试命令与结果摘要

```text
命令:
  Get-Process ChatGPT,codex
  3s/4s CPU delta 采样
  解析 %LOCALAPPDATA%\Codex\Logs\2026\07\19\codex-desktop-*-21444-*.log
  git -C M:\AI\1work rev-parse / write-tree / status --porcelain
  修改 %USERPROFILE%\.codex\config.toml 后复读

结果摘要:
  - 桌面前: ChatGPT 多进程 + 高频 git 日志 + main ~27% 单核
  - 桌面后: ChatGPT 进程清零；仅剩 CLI codex（会话相关）
  - 配置: 删除 m:\ai\1work 与 c:\windows\system32 trust；保留 sglang
```
