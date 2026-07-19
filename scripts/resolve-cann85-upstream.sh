#!/usr/bin/env bash
# Resolve latest dynamic lmsysorg/sglang CANN 8.5 upstream + time tags.
# Outputs github actions style key=value lines on stdout for GITHUB_OUTPUT append.
set -euo pipefail

EVENT_NAME="${EVENT_NAME:-push}"
INPUT_TIME_TAG="${INPUT_TIME_TAG:-}"
INPUT_CANN_LINE="${INPUT_CANN_LINE:-cann8.5}"
INPUT_DEVICE="${INPUT_DEVICE:-910b}"
INPUT_SGLANG_BASE="${INPUT_SGLANG_BASE:-}"
FALLBACK="${FALLBACK:-lmsysorg/sglang:main-cann8.5.0-910b}"
ACR_PWD="${ACR_PWD:-}"

if [ "$EVENT_NAME" = "workflow_dispatch" ] && [ -n "$INPUT_TIME_TAG" ]; then
  TIME_TAG="$INPUT_TIME_TAG"
else
  TIME_TAG="$(date -u +%Y%m%d-%H%M%S)"
fi
TIME_TAG="$(echo "$TIME_TAG" | tr -cd 'A-Za-z0-9._-')"
[ -n "$TIME_TAG" ] || TIME_TAG="$(date -u +%Y%m%d-%H%M%S)"

CANN_LINE="${INPUT_CANN_LINE:-cann8.5}"
DEVICE="${INPUT_DEVICE:-910b}"
[ -n "$CANN_LINE" ] || CANN_LINE="cann8.5"
[ -n "$DEVICE" ] || DEVICE="910b"

if [ "$EVENT_NAME" = "workflow_dispatch" ] && [ -n "$INPUT_SGLANG_BASE" ]; then
  SGLANG_BASE="$INPUT_SGLANG_BASE"
else
  TOKEN="$(curl -fsSL "https://auth.docker.io/token?service=registry.docker.io&scope=repository:lmsysorg/sglang:pull" | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')"
  curl -fsSL -H "Authorization: Bearer ${TOKEN}" https://registry-1.docker.io/v2/lmsysorg/sglang/tags/list -o /tmp/sglang-tags.json
  export CANN_LINE DEVICE FALLBACK
  SGLANG_BASE="$(python3 - <<'PY'
import json, os, re
cann = os.environ["CANN_LINE"]
device = os.environ["DEVICE"]
fallback = os.environ.get("FALLBACK", "lmsysorg/sglang:main-cann8.5.0-910b")
with open("/tmp/sglang-tags.json", encoding="utf-8") as f:
    tags = json.load(f).get("tags") or []
main_pat = re.compile(rf"^main-{re.escape(cann)}[0-9.]*-{re.escape(device)}$")
mains = sorted(t for t in tags if main_pat.match(t))
if mains:
    print(f"lmsysorg/sglang:{mains[-1]}")
    raise SystemExit(0)
ver_pat = re.compile(rf"^v(.+?)-{re.escape(cann)}[0-9.]*-{re.escape(device)}$")
cands = [t for t in tags if ver_pat.match(t)]
if not cands:
    print(fallback)
    raise SystemExit(0)

def score(tag: str):
    body = tag[1:].split("-", 1)[0]
    nums = []
    for part in re.split(r"[^0-9]+", body):
        if part.isdigit():
            nums.append(int(part))
    return nums

best = sorted(cands, key=score)[-1]
print(f"lmsysorg/sglang:{best}")
PY
)"
fi

DIGEST="unknown"
if command -v docker >/dev/null 2>&1; then
  DIGEST="$(docker buildx imagetools inspect "$SGLANG_BASE" --format '{{json .Manifest}}' 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin).get("digest","") or "unknown")' || true)"
  [ -n "$DIGEST" ] || DIGEST="unknown"
fi

if [ -n "$ACR_PWD" ]; then HAS_ACR=true; else HAS_ACR=false; fi

cat <<EOF
time_tag=${TIME_TAG}
base_tag=${TIME_TAG}
asr_tag=${TIME_TAG}-asr
sglang_base=${SGLANG_BASE}
base_platform=linux/arm64
has_acr=${HAS_ACR}
upstream_digest=${DIGEST}
EOF

echo "Resolved TIME_TAG=${TIME_TAG} SGLANG_BASE=${SGLANG_BASE} DIGEST=${DIGEST} HAS_ACR=${HAS_ACR}" >&2
