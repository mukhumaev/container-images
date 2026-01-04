ARG GCC_VERSION=15

# Builder
FROM gcc:${GCC_VERSION} AS builder

WORKDIR /app

RUN git clone https://github.com/hufrea/byedpi .      && \
    git checkout $(git rev-list --tags --max-count=1) && \
    LDFLAGS=-static make

RUN useradd -u 1000 -M -d /nonexistent -s /sbin/nologin byedpi

# App
FROM scratch AS app

LABEL maintainer="mukhumaev <47594681+mukhumaev@users.noreply.github.com>"
LABEL version="latest"

COPY --from=builder /app/ciadpi /byedpi
COPY --from=builder /etc/passwd /etc/passwd

VOLUME [/etc/byedpi]

USER byedpi

EXPOSE 1080

ENTRYPOINT ["/byedpi"]


