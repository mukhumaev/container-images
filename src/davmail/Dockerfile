
ARG JAVA_VERSION=17

# Preparing
FROM alpine AS builder

ENV MAIN_URL="https://sourceforge.net/projects/davmail/files"

RUN apk add --no-cache ca-certificates curl

RUN RAW_VERSION=$(\
        curl -sLI -o /dev/null -w '%{url_effective}\n' "${MAIN_URL}/latest/download" | \
        grep -oE 'davmail-[0-9].[0-9].[0-9]-[0-9]{1,9}' | tail -n 1 \
    ) && \
    VERSION="$(echo ${RAW_VERSION} | cut -d '-' -f 2)" && \
    echo "Downloading latest davmail version $VERSION ..." && \
    curl -SL "${MAIN_URL}/davmail/${VERSION}/${RAW_VERSION}.zip/download" -o /tmp/davmail.zip


RUN adduser davmail -D && \
  mkdir /usr/local/davmail && \
  unzip -q /tmp/davmail.zip -d /usr/local/davmail && \
  rm /tmp/davmail.zip


# Building image
FROM eclipse-temurin:${JAVA_VERSION}-jre-noble AS app

LABEL maintainer="mukhumaev <47594681+mukhumaev@users.noreply.github.com>"
LABEL version="latest"

COPY --from=builder /usr/local/davmail /usr/local/davmail
COPY --from=builder /etc/passwd /etc/passwd

WORKDIR /usr/local/davmail

VOLUME /etc/davmail /var/log/davmail

EXPOSE 1080/tcp 1143/tcp 1389/tcp 1110/tcp 1025/tcp

USER davmail

ENTRYPOINT ["/usr/local/davmail/davmail"]

CMD ["/etc/davmail/davmail.properties"]


