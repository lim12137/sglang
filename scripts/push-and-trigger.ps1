# 一键：登录检查 → 建仓 → 推送 → 设 ACR secret → 触发 Action
# 用法（PowerShell）:
#   $env:HTTP_PROXY='http://127.0.0.1:7890'
#   $env:HTTPS_PROXY='http://127.0.0.1:7890'
#   gh auth login -h github.com -p https -w
#   .\scripts\push-and-trigger.ps1

$ErrorActionPreference = 'Stop'
$Repo = 'lim12137/sglang-cann'
$Root = Split-Path -Parent $PSScriptRoot
if (-not $Root) { $Root = 'M:\AI\1work\sglang' }
Set-Location $Root

if (-not $env:HTTP_PROXY) { $env:HTTP_PROXY = 'http://127.0.0.1:7890' }
if (-not $env:HTTPS_PROXY) { $env:HTTPS_PROXY = 'http://127.0.0.1:7890' }
$env:ALL_PROXY = $env:HTTP_PROXY

Write-Host '== gh auth =='
$st = gh auth status 2>&1 | Out-String
Write-Host $st
if ($st -notmatch 'Logged in') {
  throw "请先执行: gh auth login -h github.com -p https -w"
}

$user = gh api user --jq .login
Write-Host "login as $user"

Write-Host '== ensure remote repo =='
$exists = $true
try { gh repo view $Repo | Out-Null } catch { $exists = $false }
if (-not $exists) {
  gh repo create $Repo --public --description 'SGLang CANN 8.5 base + ASR images (time tags)' --source . --remote origin --push
} else {
  $url = "https://github.com/$Repo.git"
  if (-not (git remote get-url origin 2>$null)) {
    git remote add origin $url
  } else {
    git remote set-url origin $url
  }
  git -c http.sslBackend=openssl -c http.proxy=$env:HTTP_PROXY -c https.proxy=$env:HTTPS_PROXY push -u origin main
}

Write-Host '== ACR secret (skip if already set) =='
if ($env:ALIYUN_ACR_PWD) {
  $env:ALIYUN_ACR_PWD | gh secret set ALIYUN_ACR_PWD -R $Repo
  Write-Host 'ALIYUN_ACR_PWD set from env'
} else {
  Write-Host '提示: 若仓库还没有 ALIYUN_ACR_PWD，请执行: gh secret set ALIYUN_ACR_PWD -R lim12137/sglang-cann'
}

Write-Host '== trigger workflow =='
gh workflow run build.yml -R $Repo
Start-Sleep -Seconds 3
gh run list -R $Repo --limit 5
Write-Host 'DONE'
