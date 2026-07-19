# 核对报告：MOSS-Transcribe-Diarize 专用镜像

日期: 2026-07-19  
对照文档: https://sgl-project.github.io/sglang-omni/cookbook/moss_transcribe_diarize.html

## 官方 cookbook 要点

1. 安装：`docker pull lmsysorg/sglang-omni:latest`（或从源码 `pip install -e "[omni]"`）
2. 模型：`OpenMOSS-Team/MOSS-Transcribe-Diarize`
3. 启动：
   ```bash
   sglang serve --model-path OpenMOSS-Team/MOSS-Transcribe-Diarize \
     --host 0.0.0.0 --port 30000 --omni --keep-mm-feature \
     --chunked-prefill-size -1 --max-running-requests 1
   ```
4. 硬件：文档写 **至少 1× GPU 80GB**（H100/A100 等），未写 Ascend
5. 依赖提示：需要 `torchaudio` 处理本地音频

## 本地旧 ASR 镜像偏差

| 项 | 旧 Dockerfile.asr | 官方 cookbook |
|----|-------------------|---------------|
| Base | `ascendai/cann:8.5.1...` | `lmsysorg/sglang-omni:latest` |
| 模型 | Fun-ASR-Nano + VAD + CAM++ | MOSS-Transcribe-Diarize |
| 入口 | `verify-npu-models` | `sglang serve --omni` |
| 平台 | linux/arm64 NPU | NVIDIA CUDA |

## 已做对齐

- `Dockerfile.asr` → `FROM lmsysorg/sglang-omni:latest`
- `scripts/serve-moss-transcribe-diarize.sh` → 启动参数与 cookbook 一致
- 默认 `MODEL_PATH=OpenMOSS-Team/MOSS-Transcribe-Diarize`，支持挂载本地路径
- Action 中 ASR 平台默认 `linux/amd64`；基础 CANN 镜像仍为 `linux/arm64`
- Tag 仍用时间戳 + `-asr`

## 未对齐 / 风险

1. **CANN/昇腾**：官方 cookbook 无 NPU 路径；若目标机是 910B，本 ASR 专用镜像不能直接当 NPU 方案
2. **模型权重**：不打入镜像（与 cookbook 一致，运行时下载或挂载）
3. **ACR secret**：`lim12137/sglang-cann` 需 `ALIYUN_ACR_PWD` 才推 ACR；缺失时仅 GHCR

## 测试

```text
# 脚本存在性 / 入口参数静态检查
Select-String -Path scripts/serve-moss-transcribe-diarize.sh -Pattern 'keep-mm-feature|chunked-prefill-size|-1|max-running-requests|1'
# 期望：均命中
```

未在本机 GPU 上做真实推理。
