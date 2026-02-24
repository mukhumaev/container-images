ARG GO_VERSION=1
ARG REGISTRY=docker.io

# Builder
FROM ${REGISTRY}/golang:${GO_VERSION}-alpine AS builder

ENV GIT_URL="https://github.com/XTLS/Xray-core"

COPY tmp /app

WORKDIR /app

RUN apk add --no-cache git

RUN test -d '.git' && git pull -f || git clone "${GIT_URL}" . \
    && git reset --hard $(git rev-list --tags --max-count=1) \
    && go mod download -x \
    && CGO_ENABLED=0 go build \
        -o xray            \
        -trimpath          \
        -buildvcs=false    \
        -ldflags="-s -w -buildid=" \
        -v ./main

RUN adduser -u 1000 -D -h /nonexistent -s /sbin/nologin xray

# App
FROM scratch AS app

LABEL maintainer="mukhumaev <47594681+mukhumaev@users.noreply.github.com>"
LABEL version="latest"

COPY --from=builder /app/xray   /xray
COPY --from=builder /etc/passwd /etc/passwd

VOLUME [/etc/xray]

USER xray

ENTRYPOINT ["/xray"]

CMD ["-confdir", "/etc/xray/"]

