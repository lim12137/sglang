# SGLang（CANN 8.5 最新动态 + 时间 Tag）

仓库：https://github.com/lim12137/sglang

## 策略

| 镜像 | 上游 | 发布 Tag |
|------|------|----------|
| **基础** | 自动解析 `lmsysorg/sglang` 的 **CANN 8.5 最新动态**（优先 `main-cann8.5.0-910b`） | `<UTC时间>` / `latest` / `cann8.5-latest` |
| **ASR** | **同一 CANN 8.5 后端** | `<UTC时间>-asr` / `latest-asr` / `cann8.5-latest-asr` |

示例：

```text
ghcr.io/lim12137/sglang:20260719-043000
ghcr.io/lim12137/sglang:20260719-043000-asr
crpi-fs24haezdztsodhc.cn-guangzhou.personal.cr.aliyuncs.com/hopemyl/sglang:20260719-043000
```

每次构建会记录上游 digest 到 label，便于追溯「当时的最新动态版本」。

## 本地触发

```powershell
gh workflow run build.yml -R lim12137/sglang
# 仅基础：
gh workflow run build.yml -R lim12137/sglang -f build_base=true -f build_asr=false
```

Secret：`ALIYUN_ACR_PWD`（已支持 GHCR+ACR）
