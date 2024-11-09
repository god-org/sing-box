FROM --platform=$BUILDPLATFORM golang:alpine AS builder
WORKDIR /go/src/github.com/sagernet/sing-box
ARG TARGETOS TARGETARCH BRANCH
ENV CGO_ENABLED=0 \
    GOOS=$TARGETOS \
    GOARCH=$TARGETARCH
RUN set -ex \
    && apk add --no-cache git build-base \
    && git clone -b $BRANCH --single-branch --depth=1 https://github.com/sagernet/sing-box /go/src/github.com/sagernet/sing-box \
    && go version \
    && go mod tidy \
    && export COMMIT=$(git rev-parse --short HEAD) \
    && export VERSION=$(go run ./cmd/internal/read_tag) \
    && go build -v -trimpath -tags "with_quic,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor" \
    -o /go/bin/sing-box \
    -ldflags "-X \"github.com/sagernet/sing-box/constant.Version=$VERSION\" -s -w -buildid=" \
    ./cmd/sing-box
FROM alpine AS dist
COPY --from=builder /go/bin/sing-box /usr/local/bin/sing-box
ENTRYPOINT ["sing-box"]
