ARG GO_VERSION=1

# Builder
FROM golang:${GO_VERSION}-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

RUN git clone https://github.com/syncthing/syncthing . && \
    git checkout $(git rev-list --tags --max-count=1) && \
    CGO_ENABLED=0 go run build.go -no-upgrade build strelaysrv


# App
FROM alpine

LABEL maintainer="mukhumaev <47594681+mukhumaev@users.noreply.github.com>"
LABEL version="latest"


COPY --from=builder /app/strelaysrv /bin/strelaysrv
COPY --from=builder /app/script/docker-entrypoint.sh /bin/entrypoint.sh

RUN chmod 755 /bin/entrypoint.sh
RUN apk add --no-cache ca-certificates su-exec

ENV STHOMEDIR=/var/syncthing/config
ENV PUID=1000 PGID=1000 HOME=/var/strelaysrv
ENV STGUIADDRESS=0.0.0.0:8384

EXPOSE 8384 22000/tcp 22000/udp 21027/udp

WORKDIR /var/strelaysrv
VOLUME ["/var/strelaysrv"]

HEALTHCHECK --interval=1m --timeout=10s \
  CMD nc -z localhost 22067 || exit 1

ENTRYPOINT ["/bin/entrypoint.sh", "/bin/strelaysrv"]

