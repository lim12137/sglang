# Windows Defender / Firewall High CPU Deep Dive (2026-07-19)

## 1. Conclusion

| Component | High CPU? | Notes |
|-----------|-----------|-------|
| Microsoft Defender Antivirus (MsMpEng) | YES | Real-time on-access scan of files touched by ChatGPT/Codex git; sampled 110-230% Processor Time, IO up to hundreds of MB/s |
| Windows Firewall (mpssvc + BFE) | NO | Running but idle; ~30MB svchost; only profile-switch events in 24h |
| Network Inspection (NisSrv) | NO | ~0% in samples |
| Trigger | ChatGPT/Codex + git | Parent ChatGPT.exe launches `git ls-files --others` on huge monorepo; Defender scans every file read |

Root cause is not the firewall. Causal chain:

```
ChatGPT/Codex git-repo-watcher / review
  -> high-frequency git on M:\AI\1work
    -> mass file open/read
      -> Defender real-time protection (MsMpEng)
        -> high CPU + disk IO
```

## 2. Evidence

### 2.1 Services

| Name | State | PID | Role |
|------|-------|-----|------|
| WinDefend | Running | 6288 MsMpEng | AV engine |
| WdNisSvc | Running | 4772 NisSrv | Network inspection |
| mpssvc | Running | 3404 svchost | Firewall |
| BFE | Running | 3404 svchost | Base Filtering Engine |

MsMpEng working set ~740-770 MB, ~64 threads.

### 2.2 Defender status

- RealTimeProtectionEnabled = True
- OnAccessProtectionEnabled = True
- IoavProtectionEnabled = True
- BehaviorMonitorEnabled = True
- Tamper protection = True
- Quick scan age = 3 days; full scan not recorded
- Signatures updated 2026-07-18
- Viewing/adding exclusions requires Administrator (current session denied)

### 2.3 typeperf samples (peak while git/Codex active)

```
MsMpEng % Processor Time : 119, 110, 121, 158, 230
MsMpEng IO Data Bytes/sec: ~679MB/s, 461MB/s, then tens of MB/s
NisSrv % Processor Time  : 0
git % Processor Time     : ~99-101 (one core saturated)
```

### 2.4 Process chain (smoking gun)

```
ChatGPT.exe (OpenAI.Codex MSIX)
  -> git.exe -c core.hooksPath=NUL -c core.fsmonitor= ls-files --others --exclude-standard -z
```

4s CPU delta top included git ~101% single-core and codex ~20%.

### 2.5 Event logs (48h Defender Operational)

| Id | Count | Meaning |
|----|-------|---------|
| 1150/1151 | many | hourly health, normal |
| 2010 | few | cloud protection intelligence |
| 1000/1002 | 2 | scheduled quick scan start / stopped incomplete |
| 1116/1117 | 0 | no threat-detection storm |
| Firewall 24h | 9 | Public/Private profile flips only |

Not malware thrashing; IO-driven real-time scanning.

### 2.6 Why it looks like "firewall"

Task Manager labels are easy to confuse: Antimalware Service Executable = MsMpEng (AV), not mpssvc. Firewall service host is quiet.

## 3. Actions taken

1. Confirmed firewall low load; Defender high load with git parent = ChatGPT.exe
2. Stopped ChatGPT desktop processes again to break the loop
3. Added admin script: `scripts/add-defender-dev-exclusions.ps1` (does not disable RTP/firewall)
4. Could NOT add exclusions without elevation (Access Denied)

## 4. Recommended fix order

### A. Immediate (no admin)

1. Fully quit ChatGPT desktop (tray exit)
2. Do not open whole `M:\AI\1work` as Codex workspace
3. Keep `~/.codex/config.toml` trusting only small projects (monorepo trust already removed earlier)

### B. Admin exclusions (recommended)

```powershell
# Elevated PowerShell
Set-ExecutionPolicy -Scope Process Bypass -Force
& M:\AI\1work\sglang\scripts\add-defender-dev-exclusions.ps1
```

Excludes trusted dev paths (`M:\AI\1work`, codex dirs, nodejs, Git) and processes (`git.exe`, `ChatGPT.exe`, `codex.exe`, `node.exe`, `rg.exe`).

### C. Do NOT

- Disable Windows Firewall (won't fix this CPU)
- Permanently disable real-time protection (prefer exclusions)

## 5. Validation commands

```powershell
typeperf "\Process(MsMpEng)\% Processor Time" "\Process(MsMpEng)\IO Data Bytes/sec" "\Process(git)\% Processor Time" -sc 10
Get-CimInstance Win32_Process -Filter "Name='git.exe'" | Select ProcessId,ParentProcessId,CommandLine
# admin:
Get-MpPreference | Select ExclusionPath,ExclusionProcess
```

## 6. Test commands and result summary

```
Commands:
  Get-Service WinDefend,mpssvc,BFE,WdNisSvc
  Get-MpComputerStatus / Get-MpPreference
  typeperf MsMpEng / NisSrv / git
  Get-WinEvent Defender Operational + Firewall
  Get-CimInstance git parent chain
  Add-MpPreference (FAILED: access denied)

Results:
  - Firewall: idle, not the culprit
  - MsMpEng: peak 110-230% Processor Time, IO up to ~679MB/s
  - Trigger: ChatGPT.exe -> git ls-files on monorepo
  - No threat detection storm
  - Exclusions need elevated script
```

## 7. Relation to ChatGPT CPU report

Same causal chain in two stages:

1. docs/chatgpt-desktop-cpu-investigation-2026-07-19.md — desktop git polling
2. this report — Defender multiplies that IO into system CPU

Best fix: quit/limit ChatGPT project scope AND add Defender exclusions.
