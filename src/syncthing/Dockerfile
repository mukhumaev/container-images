ARG GO_VERSION=1

# Builder
FROM golang:${GO_VERSION}-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

RUN git clone https://github.com/syncthing/syncthing .        && \
    git checkout $(git rev-list --tags --max-count=1) && \
    CGO_ENABLED=0 go run build.go -no-upgrade build syncthing


# App
FROM alpine

LABEL maintainer="mukhumaev <47594681+mukhumaev@users.noreply.github.com>"
LABEL version="latest"


COPY --from=builder /app/syncthing /bin/syncthing
COPY --from=builder /app/script/docker-entrypoint.sh /bin/entrypoint.sh

RUN chmod 755 /bin/entrypoint.sh
RUN apk add --no-cache ca-certificates curl libcap su-exec tzdata

ENV STHOMEDIR=/var/syncthing/config
ENV PUID=1000 PGID=1000 HOME=/var/syncthing
ENV STGUIADDRESS=0.0.0.0:8384

EXPOSE 8384 22000/tcp 22000/udp 21027/udp

VOLUME ["/var/syncthing"]

HEALTHCHECK --interval=1m --timeout=10s \
  CMD curl -fkLsS -m 2 127.0.0.1:8384/rest/noauth/health | grep -o --color=never OK || exit 1

ENTRYPOINT ["/bin/entrypoint.sh", "/bin/syncthing"]

