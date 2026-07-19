# SGLang 基础镜像：跟踪 CANN 8.5 最新上游，构建产物按时间打 tag
ARG SGLANG_BASE=lmsysorg/sglang:main-cann8.5.0-910b
FROM ${SGLANG_BASE}

LABEL org.opencontainers.image.title="sglang-cann-base" \
      org.opencontainers.image.description="SGLang Ascend base (latest CANN 8.5 upstream; publish with time tag)" \
      cann.line="8.5" \
      sglang.image.role="base"

WORKDIR /sgl-workspace
CMD ["/bin/bash"]
