# SGLang CANN 8.5 构建验收报告

日期: 2026-07-19  
仓库: https://github.com/lim12137/sglang  
成功 Run: https://github.com/lim12137/sglang/actions/runs/29673519513  
结论: **success**（resolve-tags / build-base / build-asr 全部成功）

## 策略（已实现）

1. **基础镜像**：跟踪 `lmsysorg/sglang` 的 **CANN 8.5 最新动态**上游（本次解析到 `main-cann8.5.0-910b`）
2. **时间 tag**：`YYYYMMDD-HHMMSS`（UTC）
3. **ASR 镜像**：同一 CANN 8.5 后端，tag 后缀 `-asr`
4. **推送**：GHCR + 阿里云 ACR（`ALIYUN_ACR_PWD` 已配置）

## 本次解析结果

```
TIME_TAG=20260719-043424
SGLANG_BASE=lmsysorg/sglang:main-cann8.5.0-910b
DIGEST=sha256:cc1e4a3b5a1c3ca9bf48c48fb1f8f365e6e49bbb3bf4dc41497defd0b5d8242b
HAS_ACR=true
```

## 已发布镜像

### 基础（linux/arm64）

| Registry | Tags |
|----------|------|
| GHCR | `ghcr.io/lim12137/sglang:20260719-043424` / `latest` / `cann8.5-latest` |
| ACR | `crpi-fs24haezdztsodhc.cn-guangzhou.personal.cr.aliyuncs.com/hopemyl/sglang:20260719-043424` / `latest` / `cann8.5-latest` |

Digest（GHCR 已核对）: `sha256:f69654d5ed707d50255ce10ee6792b0911be7b93a82eb937aa7ee23c949a9485`

### ASR（linux/arm64）

| Registry | Tags |
|----------|------|
| GHCR | `ghcr.io/lim12137/sglang:20260719-043424-asr` / `latest-asr` / `cann8.5-latest-asr` |
| ACR | `.../hopemyl/sglang:20260719-043424-asr` / `latest-asr` / `cann8.5-latest-asr` |

Digest（GHCR 已核对）: `sha256:f098dac5b2e9cda77064f8a3dcd6e4a83bf74db1f760b91548a4cf51c957dc70`

## 验收命令与结果

```text
命令: gh run view 29673519513 -R lim12137/sglang
结果: conclusion=success; jobs resolve-tags/build-base/build-asr 全部 success

命令: docker buildx imagetools inspect ghcr.io/lim12137/sglang:20260719-043424
结果: OK（Digest sha256:f69654d5...，platform linux/arm64）

命令: docker buildx imagetools inspect ghcr.io/lim12137/sglang:20260719-043424-asr
结果: OK（Digest sha256:f098dac5...，platform linux/arm64）

ACR 推送: Actions 日志含 pushing manifest for crpi-.../hopemyl/sglang:... done（base+asr 均成功）
```

## 拉取示例

```bash
# 基础（按时间锁定）
docker pull crpi-fs24haezdztsodhc.cn-guangzhou.personal.cr.aliyuncs.com/hopemyl/sglang:20260719-043424

# ASR
docker pull crpi-fs24haezdztsodhc.cn-guangzhou.personal.cr.aliyuncs.com/hopemyl/sglang:20260719-043424-asr
```

## 本地 git

- 远程: `origin` → https://github.com/lim12137/sglang.git
- 成功提交: `31f56ca`（fix workflow）及之前 CANN 8.5 时间 tag 策略提交
