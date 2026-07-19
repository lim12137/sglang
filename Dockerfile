# SGLang 基础镜像：跟踪上游最新（可覆盖）
# CANN 线默认：lmsysorg/sglang:main-cann8.5.0-910b
# CUDA 线可覆盖为：lmsysorg/sglang:latest
ARG SGLANG_BASE=lmsysorg/sglang:main-cann8.5.0-910b
FROM ${SGLANG_BASE}

LABEL org.opencontainers.image.title="sglang-base" \
      org.opencontainers.image.description="SGLang base image (upstream latest line; publish with time tag)" \
      sglang.image.role="base"

WORKDIR /sgl-workspace
CMD ["/bin/bash"]
