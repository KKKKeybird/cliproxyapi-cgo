ARG UPSTREAM_IMAGE=ghcr.io/caidaoli/cliproxyapi:latest

FROM golang:1.26-alpine AS builder

ARG VERSION=latest-cgo
ARG COMMIT=unknown
ARG BUILD_DATE=unknown
ARG PLUGIN_VERSION=dev

RUN apk add --no-cache build-base git

WORKDIR /src

ENV GOPROXY=https://proxy.golang.org,direct

COPY upstream/go.mod upstream/go.sum ./
RUN --mount=type=cache,target=/root/.cache/go-mod go mod download

COPY upstream/ ./

RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/.cache/go-mod \
    CGO_ENABLED=1 go build \
    -buildvcs=false \
    -trimpath \
    -ldflags="-s -w \
      -X 'main.Version=${VERSION}' \
      -X 'main.Commit=${COMMIT}' \
      -X 'main.BuildDate=${BUILD_DATE}'" \
    -o /out/CLIProxyAPI ./cmd/server/

WORKDIR /plugin

COPY plugin/go.mod plugin/go.sum ./
RUN --mount=type=cache,target=/root/.cache/go-mod go mod download

COPY plugin/ ./

RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/.cache/go-mod \
    CGO_ENABLED=1 go build \
    -buildvcs=false \
    -trimpath \
    -buildmode=c-shared \
    -ldflags="-s -w -X main.pluginVersion=${PLUGIN_VERSION}" \
    -o /out/codex-auto-ping.so .

FROM ${UPSTREAM_IMAGE}

RUN mkdir -p /CLIProxyAPI/plugins/linux/amd64

COPY --from=builder /out/CLIProxyAPI /CLIProxyAPI/CLIProxyAPI
COPY --from=builder /out/codex-auto-ping.so /CLIProxyAPI/plugins/linux/amd64/codex-auto-ping.so
