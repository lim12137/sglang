# SGLang（CANN 8.5 最新动态 + 日期 Tag）

仓库：https://github.com/lim12137/sglang

## 标签策略

| 镜像 | 上游 | 发布 Tag |
|------|------|----------|
| **基础** | 自动解析 CANN 8.5 最新动态（优先 `main-cann8.5.0-910b`） | `YYYYMMDD-cann8.5` / `latest` / `cann8.5-latest` |
| **ASR** | 同一 CANN 8.5 后端 | `YYYYMMDD-cann8.5-asr` / `latest-asr` / `cann8.5-latest-asr` |

示例：

```text
ghcr.io/lim12137/sglang:20260719-cann8.5
ghcr.io/lim12137/sglang:20260719-cann8.5-asr
crpi-fs24haezdztsodhc.cn-guangzhou.personal.cr.aliyuncs.com/hopemyl/sglang:20260719-cann8.5
```

同一天多次构建会覆盖同日 tag（按日期锁定 + cann8.5 标识）。

## 触发

**仅手动** workflow_dispatch，push **不会**自动构建。


```powershell
gh workflow run build.yml -R lim12137/sglang
# 指定日期：
gh workflow run build.yml -R lim12137/sglang -f time_tag=20260719
```
