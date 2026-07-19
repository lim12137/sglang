# ChatGPT 桌面端「共存」方案（低 CPU 常开）

目标：**ChatGPT / Codex 桌面可以一直开着**，但不要对巨型 monorepo 做 git 风暴。

## 原理

桌面端高 CPU 主要来自：

- `electron-saved-workspace-roots` / `active-workspace-roots` 挂了 **十几个大仓**
- `review_model` + `subscribe-live-query` + `git-repo-watcher` 对每个 root 高频 git
- Defender（MsMpEng）扫 git 读再放大

**共存 = 缩小监视面 + 排除扫描 + 用完别挂整棵 monorepo**，不是必须杀进程。

## 已替你做好的

| 项 | 状态 |
|----|------|
| monorepo trust 移除，只 trust `sglang` | `~\.codex\config.toml` |
| 侧栏工作区 17 → **仅 `M:\AI\1work\sglang`** | `~\.codex\.codex-global-state.json` |
| 备份（可恢复） | `~\.codex\.codex-global-state.json.bak-cpu-slim-20260719-124910` |
| 空壳 `gstak\.git` 隔离 | `M:\AI\1work\gstak\.git.bak-empty-*` |

## 推荐用法（日常共存）

### 1. 开桌面没问题

可以开机/托盘常驻 ChatGPT。

### 2. 侧栏只留当前要用的 1～2 个项目

- ✅ `M:\AI\1work\sglang`
- ❌ 不要加 `M:\AI\1work` 整树
- ❌ 不要同时挂 llm / gstak / clash-web / 十几个仓

需要别的项目时：**换项目**（替换当前 root），不要「全部钉在侧栏」。

### 3. 写代码时开 Codex；纯聊天可开着但少绑大仓

绑的 root 越少，后台 git 越少。

### 4. 管理员做一次 Defender 排除（强烈建议）

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
& 'M:\AI\1work\sglang\scripts\add-defender-dev-exclusions.ps1'
```

排除 `M:\AI\1work`、`%USERPROFILE%\.codex` 后，即使偶发 git，MsMpEng 也不会一起狂转。

### 5. 可选：日志库轮转（退出 App 后）

`logs_2.sqlite` 已 >200MB 时，退出 ChatGPT 后重命名备份，减少磁盘 IO。

## 恢复侧栏项目列表（如果后悔）

```powershell
Copy-Item "$env:USERPROFILE\.codex\.codex-global-state.json.bak-cpu-slim-20260719-124910" `
  "$env:USERPROFILE\.codex\.codex-global-state.json" -Force
# 然后重启 ChatGPT 桌面
```

## 验收（共存是否成功）

1. 打开 ChatGPT 桌面  
2. 侧栏应主要是 `sglang`（或你主动换的小仓）  
3. 任务管理器：`ChatGPT` 可有数百 MB 内存（Electron 正常），**CPU 应接近 0～数 %**  
4. 不应再持续刷出大量 `git.exe` 子进程  
5. 日志 `%LOCALAPPDATA%\Codex\Logs\今天\` 里 `abortedBeforeStart` / `subscribe-live-query` 应明显变少  

## 做不到的（产品限制）

- 目前 **没有** 稳定的官方开关「彻底关闭 git-repo-watcher 但仍用 Codex 改代码」  
- Electron 桌面端 **内存基线** 仍会偏高（几百 MB），这不等于 CPU 风暴  
- 若再次「Add project」把 `M:\AI\1work` 加回侧栏，问题会复发  

## 一句话

**可以共存：桌面常开 + 只挂小工作区 + Defender 排除。**  
不能共存的是：**桌面常开 + 侧栏钉死整个 monorepo 十几个仓**。
