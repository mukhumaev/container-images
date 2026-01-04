ARG RUST_VERSION=1

# Builder
FROM rust:${RUST_VERSION} AS builder

WORKDIR /app

RUN useradd -u 1000 -M -d /nonexistent -s /sbin/nologin tun2proxy && \
    git clone https://github.com/tun2proxy/tun2proxy . && \
    git checkout $(git rev-list --tags --max-count=1)

RUN cargo build --release


# App
FROM scratch AS app

LABEL maintainer="mukhumaev <47594681+mukhumaev@users.noreply.github.com>"
LABEL version="latest"

COPY --from=builder /app/target/release/tun2proxy-bin /tun2proxy
COPY --from=builder /etc/passwd /etc/passwd

VOLUME [/etc/tun2proxy]

USER tun2proxy

EXPOSE 1080

ENTRYPOINT ["/tun2proxy"]


