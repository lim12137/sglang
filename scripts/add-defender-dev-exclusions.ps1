#Requires -RunAsAdministrator
# Reduce Windows Defender CPU when ChatGPT/Codex + git scan large repos.
# Does NOT disable realtime protection or Windows Firewall.

$ErrorActionPreference = 'Stop'
Write-Host '== Before ==' -ForegroundColor Cyan
Get-MpComputerStatus | Select-Object AMProductVersion,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated | Format-List
$pref = Get-MpPreference
Write-Host ('ExclusionPath count: {0}' -f @($pref.ExclusionPath).Count)
Write-Host ('ExclusionProcess count: {0}' -f @($pref.ExclusionProcess).Count)

$paths = @(
  'M:\AI\1work',
  'M:\AI\1work\sglang',
  "$env:USERPROFILE\.codex",
  "$env:APPDATA\Codex",
  "$env:LOCALAPPDATA\Codex",
  'C:\Users\hopemyl\tools\nodejs',
  'D:\Program Files\Git'
) | Select-Object -Unique

$procs = @('git.exe','ChatGPT.exe','codex.exe','node.exe','rg.exe')

foreach ($p in $paths) {
  if (-not (Test-Path -LiteralPath $p)) {
    Write-Host "SKIP missing path: $p" -ForegroundColor Yellow
    continue
  }
  Add-MpPreference -ExclusionPath $p
  Write-Host "OK ExclusionPath: $p" -ForegroundColor Green
}

foreach ($p in $procs) {
  Add-MpPreference -ExclusionProcess $p
  Write-Host "OK ExclusionProcess: $p" -ForegroundColor Green
}

Write-Host ''
Write-Host '== After ==' -ForegroundColor Cyan
$pref2 = Get-MpPreference
$pref2.ExclusionPath
$pref2.ExclusionProcess
Write-Host 'Done. Realtime protection left ENABLED. Firewall untouched.' -ForegroundColor Cyan
