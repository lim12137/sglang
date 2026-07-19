#!/usr/bin/env bash
# 默认尝试以 omni 方式启动；若当前 CANN 镜像无 omni 支持，会失败并打印提示。
set -euo pipefail

MODEL_PATH="${MODEL_PATH:-OpenMOSS-Team/MOSS-Transcribe-Diarize}"
HOST="${SGLANG_HOST:-0.0.0.0}"
PORT="${SGLANG_PORT:-30000}"

echo "SGLang CANN 8.5 ASR entry"
echo "  MODEL_PATH=${MODEL_PATH}"
echo "  HOST=${HOST} PORT=${PORT}"

if ! command -v sglang >/dev/null 2>&1; then
  echo "ERROR: sglang CLI not found in image" >&2
  exit 127
fi

# 优先 omni 参数（对齐官方 cookbook）；后端为 CANN 8.5 动态上游
exec sglang serve \
  --model-path "${MODEL_PATH}" \
  --host "${HOST}" \
  --port "${PORT}" \
  --omni \
  --keep-mm-feature \
  --chunked-prefill-size -1 \
  --max-running-requests 1 \
  "$@"
