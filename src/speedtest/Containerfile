# Builder
FROM alpine:latest AS builder

WORKDIR /app

RUN mkdir -p /speedtest/.config/ookla \
    && adduser -u 1000 -D -h /speedtest -s /sbin/nologin speedtest \
    && chown -R speedtest:speedtest /speedtest 

RUN apk add --no-cache curl html-xml-utils ca-certificates

RUN ARCH="$(archv="$(arch)"; case "$archv" in armv7l) echo armhf;; *) echo "$archv";; esac)" \
    && curl -sSL $(curl -s "https://www.speedtest.net/apps/cli" | hxwls | grep "linux-$ARCH.tgz") -o speedtest.tgz \
    && tar -xvf speedtest.tgz \
    && update-ca-certificates

# App
FROM alpine:latest AS app

LABEL maintainer="mukhumaev <47594681+mukhumaev@users.noreply.github.com>"
LABEL version="latest"

COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /app/speedtest /bin/speedtest
COPY --from=builder --chown=speedtest:speedtest /speedtest /speedtest

VOLUME /speedtest
USER speedtest

ENTRYPOINT ["/bin/speedtest"]

