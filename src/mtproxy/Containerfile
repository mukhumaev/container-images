FROM debian:stable AS builder

WORKDIR /MTProxy

RUN apt update && apt install -y git curl build-essential libssl-dev zlib1g-dev

RUN git clone https://github.com/TelegramMessenger/MTProxy .

RUN make

RUN cat > entrypoint.sh <<'EOF'
#!/bin/env bash

pubIp(){
    local host="${1:-ifconfig.me}"
    local port="${2:-80}"
    local agent="${3:-curl/8.15.0}"

    exec 3<>/dev/tcp/$host/$port
    echo -e "GET / HTTP/1.1\r\nHost: ${host}\r\nUser-Agent: ${agent}\r\nAccept: */*\r\nConnection: close\r\n\r\n" >&3
    cat <&3 2>/dev/null | grep -E '^([0-9]{1,3}\.)[0-9]{1,3}' | tr -d '\r\n'

    exec 3>&- 3<&-
}

qrGen(){
    local ip="$1"
    local port="$2"
    local secret="$3"

    local uri="proxy?server=$ip&port=$port&secret=$secret"
    local tg_proxy_url="tg://$uri"
    local https_proxy_url="https://$uri"

    echo
    echo "HTTPS URL:       $https_proxy_url"
    echo "Telegram URL:    $tg_proxy_url"
    echo "QR code for Telegram mobile apps:"
    echo
    qrencode -t UTF8 -o - "$tg_proxy_url"
    echo
}

mtproto(){
    /app/mtproto-proxy "$@"
}

prepare(){
  local main_url="https://core.telegram.org"
  case "${1:-}" in
    secret-file|config-file)
      local type="${1%-*}"
      local url="${main_url}/getProxy${type^}"
      local result_file="/tmp/mtproto-${type}"

      curl -sSL --fail --max-time 10 "$url" -o "$result_file"
      [ -s "$result_file" ] || (echo "Failed to fetch $url" >&2; exit 2)
      echo "$result_file"
    ;;
    secret)
      od -An -N16 -tx1 /dev/urandom | tr -d ' \n' | tr 'A-F' 'a-f'
    ;;
    *)
      echo "Invalid prepare param" >&2
      exit 2
    ;;
  esac
}

main(){
    local port="${PORT:-443}"
    local external_port="${EXT_PORT:-$port}"
    local secret="${SECRET:-$(prepare secret)}"
    local secret_file="$(prepare secret-file)"
    local config_file="$(prepare config-file)"
    local ip="$(pubIp)"

    qrGen "$ip" "$external_port" "$secret" 

    mtproto \
      -u nobody \
      -p 8888 \
      -H "$port" \
      -S "$secret" \
      --aes-pwd "$secret_file" \
      "$config_file" -M 1 \
      "$@"
}

main "$@"
EOF
RUN chmod +x entrypoint.sh

FROM debian:stable-slim AS app

LABEL maintainer="mukhumaev <47594681+mukhumaev@users.noreply.github.com>"
LABEL version="latest"

WORKDIR /app

COPY --from=builder /MTProxy/objs/bin/mtproto-proxy /app/mtproto-proxy
COPY --from=builder /MTProxy/entrypoint.sh          /app/entrypoint.sh

RUN apt update \
    && apt install -y curl qrencode libssl-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && chmod +x /app/entrypoint.sh \
    && chmod +x /app/mtproto-proxy

ENTRYPOINT ["/app/entrypoint.sh"]

