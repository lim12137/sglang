#!/usr/bin/env bash
# 对齐官方 cookbook 启动参数：
# https://sgl-project.github.io/sglang-omni/cookbook/moss_transcribe_diarize.html
set -euo pipefail

MODEL_PATH="${MODEL_PATH:-OpenMOSS-Team/MOSS-Transcribe-Diarize}"
HOST="${SGLANG_HOST:-0.0.0.0}"
PORT="${SGLANG_PORT:-30000}"

# 允许本地挂载目录作为 model path，例如 -v /models/MOSS:/models/MOSS -e MODEL_PATH=/models/MOSS
echo "Starting MOSS-Transcribe-Diarize"
echo "  MODEL_PATH=${MODEL_PATH}"
echo "  HOST=${HOST} PORT=${PORT}"

exec sglang serve \
  --model-path "${MODEL_PATH}" \
  --host "${HOST}" \
  --port "${PORT}" \
  --omni \
  --keep-mm-feature \
  --chunked-prefill-size -1 \
  --max-running-requests 1 \
  "$@"
