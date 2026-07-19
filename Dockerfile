# SGLang 基础镜像：跟踪 CANN 8.5 线「最新动态」上游
# 默认上游滚动 tag：lmsysorg/sglang:main-cann8.5.0-910b
# 发布时由 CI 打 UTC 时间 tag（YYYYMMDD-HHMMSS）+ latest
ARG SGLANG_BASE=lmsysorg/sglang:main-cann8.5.0-910b
FROM ${SGLANG_BASE}

ARG UPSTREAM_REF=lmsysorg/sglang:main-cann8.5.0-910b
ARG BUILD_TIME_TAG=unknown

LABEL org.opencontainers.image.title="sglang-cann85-base" \
      org.opencontainers.image.description="SGLang CANN 8.5 latest dynamic base; published with time tags" \
      sglang.image.role="base" \
      sglang.cann.line="8.5" \
      sglang.upstream.ref="${UPSTREAM_REF}" \
      sglang.build.time_tag="${BUILD_TIME_TAG}"

WORKDIR /sgl-workspace
CMD ["/bin/bash"]
