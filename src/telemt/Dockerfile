ARG REGISTRY=docker.io

# Builder
FROM ${REGISTRY}/rust:alpine AS builder

ENV GIT_URL="https://github.com/telemt/telemt"

COPY tmp /app

WORKDIR /app

RUN apk add --no-cache ca-certificates git pkgconf \
    && update-ca-certificates

RUN test -d '.git' && git pull || git clone --depth=1 "${GIT_URL}" . 

RUN adduser -u 1000 -D -h /nonexistent -s /sbin/nologin telemt

RUN cargo build --release \
    && strip target/release/telemt

# APP
FROM scratch AS app

STOPSIGNAL SIGINT

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/target/release/telemt /telemt
COPY --from=builder /etc/passwd /etc/passwd

VOLUME ["/etc/telemt"]

USER telemt

EXPOSE 443/tcp 9090/tcp

ENTRYPOINT ["/telemt"]
CMD ["/etc/telemt/config.toml"]

