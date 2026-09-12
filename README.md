# CLIProxyAPI CGO image

This repository rebuilds `ghcr.io/caidaoli/cliproxyapi:latest` with CGO enabled so native CLIProxyAPI plugins can be loaded.

The workflow runs every six hours and:

1. resolves the source revision used by the current upstream `latest` image;
2. checks out that exact revision from `caidaoli/CLIProxyAPI`;
3. checks out the latest release of `KKKKeybird/cpa-codex-auto-ping`;
4. builds both with CGO enabled against Alpine/musl; and
5. publishes `ghcr.io/kkkkeybird/cliproxyapi-cgo:latest` for Linux AMD64.

## Docker Compose

```yaml
services:
  cli-proxy-api:
    image: ghcr.io/kkkkeybird/cliproxyapi-cgo:latest
```

The plugin is installed in the image at:

```text
/CLIProxyAPI/plugins/linux/amd64/codex-auto-ping.so
```

Enable it in `config.yaml`:

```yaml
plugins:
  enabled: true
  dir: "plugins"
  configs:
    codex-auto-ping:
      enabled: true
      priority: 1
```

