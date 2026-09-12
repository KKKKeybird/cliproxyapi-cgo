FROM golang:1.26-alpine AS server-builder

ARG VERSION=latest-cgo
ARG COMMIT=unknown
ARG BUILD_DATE=unknown

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

FROM alpine:3.23 AS plugin-builder

RUN apk add --no-cache cmake g++ make

WORKDIR /plugin

COPY plugin/CMakeLists.txt ./
COPY plugin/src ./src

RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF && \
    cmake --build build --parallel && \
    cp build/codex-auto-ping.so /codex-auto-ping.so

FROM alpine:3.23

RUN apk add --no-cache ca-certificates tzdata libstdc++

RUN mkdir -p /CLIProxyAPI/plugins/linux/amd64

COPY --from=server-builder /out/CLIProxyAPI /CLIProxyAPI/CLIProxyAPI
COPY --from=plugin-builder /codex-auto-ping.so /CLIProxyAPI/plugins/linux/amd64/codex-auto-ping.so
COPY upstream/config.example.yaml /CLIProxyAPI/config.example.yaml

WORKDIR /CLIProxyAPI

EXPOSE 8317

ENV TZ=Asia/Shanghai

RUN cp /usr/share/zoneinfo/${TZ} /etc/localtime && echo "${TZ}" > /etc/timezone

CMD ["./CLIProxyAPI"]
