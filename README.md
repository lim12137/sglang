# SGLang 镜像：基础 + ASR 专用（MOSS-Transcribe-Diarize）

对照官方 cookbook：
https://sgl-project.github.io/sglang-omni/cookbook/moss_transcribe_diarize.html

## 两套镜像

| 角色 | Dockerfile | 默认上游 | 默认平台 | Tag |
|------|------------|----------|----------|-----|
| **基础** | `Dockerfile` | `lmsysorg/sglang:main-cann8.5.0-910b` | `linux/arm64` | `<时间>` / `latest` |
| **ASR 专用** | `Dockerfile.asr` | `lmsysorg/sglang-omni:latest` | `linux/amd64` | `<时间>-asr` / `latest-asr` |

> ASR 专用镜像按 cookbook 对齐 **SGLang-Omni + MOSS-Transcribe-Diarize（NVIDIA CUDA）**。  
> 官方文档未提供 Ascend/CANN 版 MOSS 路径；CANN 基础镜像单独维护。

## 标签策略

- 每次构建 UTC 时间 tag：`YYYYMMDD-HHMMSS`
- ASR：`YYYYMMDD-HHMMSS-asr`、`latest-asr`
- 仓库：`ghcr.io/lim12137/sglang-cann`；配置 `ALIYUN_ACR_PWD` 后同步 ACR

## ASR 运行（对齐 cookbook）

```bash
docker pull ghcr.io/lim12137/sglang-cann:latest-asr

# 在线拉模型（需 HF 网络）
docker run --gpus all --shm-size 32g -p 30000:30000 \
  -e MODEL_PATH=OpenMOSS-Team/MOSS-Transcribe-Diarize \
  ghcr.io/lim12137/sglang-cann:latest-asr

# 或本地挂载模型目录
docker run --gpus all --shm-size 32g -p 30000:30000 \
  -v /path/to/MOSS-Transcribe-Diarize:/models/moss:ro \
  -e MODEL_PATH=/models/moss \
  ghcr.io/lim12137/sglang-cann:latest-asr
```

容器入口等价于 cookbook：

```bash
sglang serve --model-path "$MODEL_PATH" \
  --host 0.0.0.0 --port 30000 \
  --omni --keep-mm-feature \
  --chunked-prefill-size -1 --max-running-requests 1
```

客户端示例见 cookbook：`/v1/chat/completions` + `audio_url` + `sampling_params.audio_kwargs`（`ref_spk` / `ref_spk_audio`）。

## 与旧 FunASR 镜像的差异

| 项 | 旧方案 | 现方案（核对后） |
|----|--------|------------------|
| 框架 | FunASR + torch-npu | **SGLang-Omni** |
| 模型 | Fun-ASR-Nano / VAD / CAM++ | **OpenMOSS-Team/MOSS-Transcribe-Diarize** |
| 硬件文档 | Ascend CANN | **NVIDIA GPU（官方 cookbook）** |
| 启动 | `verify-npu-models` | `sglang serve --omni ...` |

## Actions

- 无 `ALIYUN_ACR_PWD` 时只推 GHCR
- 有 secret 时推 GHCR + ACR

```powershell
gh secret set ALIYUN_ACR_PWD -R lim12137/sglang-cann
gh workflow run build.yml -R lim12137/sglang-cann
```
