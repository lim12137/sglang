# SGLang CANN 8.5 镜像（最新上游 + 时间 Tag）

本仓库产出两套镜像，推送到 **GHCR** 与 **阿里云 ACR**：

| 角色 | Dockerfile | 发布 Tag | 说明 |
|------|------------|----------|------|
| **SGLang 基础镜像** | `Dockerfile` | `<UTC时间>` / `latest` | 每次构建拉取 **最新** CANN 8.5 上游 SGLang 镜像 |
| **ASR 匹配镜像** | `Dockerfile.asr` | `<UTC时间>-asr` / `latest-asr` | 支持运行时指定 Nano/VAD/CAM++ 模型；后缀 `-asr` 区分 |

> Docker 镜像 tag 不允许字符 `+`，因此用 **`-asr`** 作为 ASR 区分后缀（语义同“+asr”）。

## 标签策略（按构建时间）

- 每次 Action 构建自动生成 UTC 时间 tag：`YYYYMMDD-HHMMSS`
- 基础镜像：`20260719-031522`、`latest`
- ASR 镜像：`20260719-031522-asr`、`latest-asr`
- 手动触发可覆盖 `time_tag`（仍建议用时间格式）
- **拉取时优先用时间 tag 锁定一次构建**；`latest` / `latest-asr` 仅作滚动指针

示例：

```text
# 基础（某次构建）
crpi-fs24haezdztsodhc.cn-guangzhou.personal.cr.aliyuncs.com/hopemyl/sglang-cann:20260719-031522

# ASR（同一次构建批次）
crpi-fs24haezdztsodhc.cn-guangzhou.personal.cr.aliyuncs.com/hopemyl/sglang-cann:20260719-031522-asr
```

## 上游默认（最新线）

| 用途 | 默认镜像 |
|------|----------|
| SGLang 基础 | `lmsysorg/sglang:main-cann8.5.0-910b` |
| ASR CANN | `ascendai/cann:8.5.1-910b-ubuntu22.04-py3.11` |

手动触发 workflow 时可覆盖 `sglang_base` / `cann_base`。

## GitHub Actions

- Workflow: `.github/workflows/build.yml`
- Jobs: `resolve-tags` → `build-base` / `build-asr`
- Secrets: `ALIYUN_ACR_PWD`

## ASR 运行时指定模型

| 环境变量 | 模型 |
|----------|------|
| `NANO_MODEL_DIR` | Fun-ASR-Nano-2512 |
| `VAD_MODEL_DIR` | FSMN VAD |
| `SPK_MODEL_DIR` | CAM++ |
| `TEST_AUDIO` | 可选测试音频 |
| `NPU_DEVICE` | 默认 `npu:0` |

```bash
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/devmm_svm \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver:ro \
  -v /path/to/Fun-ASR-Nano-2512:/models/nano:ro \
  -v /path/to/fsmn-vad:/models/vad:ro \
  -v /path/to/campplus:/models/spk:ro \
  -e NANO_MODEL_DIR=/models/nano \
  -e VAD_MODEL_DIR=/models/vad \
  -e SPK_MODEL_DIR=/models/spk \
  crpi-fs24haezdztsodhc.cn-guangzhou.personal.cr.aliyuncs.com/hopemyl/sglang-cann:latest-asr
```

## 本地检查

```powershell
D:\py311\python.exe -m py_compile verify/verify_npu_models.py
```
