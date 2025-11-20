#!/bin/bash

set -e

function fail {
    echo "$@" >&2
    exit 1
}

RESOLVER=$(awk '/^nameserver/ {print $2; exit}' /etc/resolv.conf)
if [ -n "$RESOLVER" ]; then
  rendered_default=$(LISTEN_PORT=8080 \
    SERVER_NAME="example.com" \
    HEALTHCHECK_PATH="/health" \
    NO_ACCESS_LOGS=0 \
    PROXY_UWSGI=0 \
    STATIC_LOCATIONS= \
    UPSTREAM_SERVER="service.internal:8080" \
    UPSTREAM_RESOLVE=1 \
    NGINX_RESOLVER="$RESOLVER valid=60s" \
    gomplate < /etc/nginx/conf.d/default.conf.template)

  echo "$rendered_default" | grep -F "server service.internal:8080 resolve;" \
    || fail "expected resolve parameter when UPSTREAM_RESOLVE=1"

  rendered_nginx=$(LISTEN_PORT=8080 \
    SERVER_NAME="example.com" \
    HEALTHCHECK_PATH="/health" \
    NO_ACCESS_LOGS=0 \
    PROXY_UWSGI=0 \
    STATIC_LOCATIONS= \
    UPSTREAM_SERVER="service.internal:8080" \
    UPSTREAM_RESOLVE=1 \
    NGINX_RESOLVER="$RESOLVER valid=60s" \
    gomplate < /etc/nginx/nginx.conf.template)

  echo "$rendered_nginx" | grep -F "resolver $RESOLVER valid=60s;" \
    || fail "expected resolver directive in nginx.conf"

  fallback_nginx=$(LISTEN_PORT=8080 \
    SERVER_NAME="example.com" \
    HEALTHCHECK_PATH="/health" \
    NO_ACCESS_LOGS=0 \
    PROXY_UWSGI=0 \
    STATIC_LOCATIONS= \
    UPSTREAM_SERVER="service.internal:8080" \
    UPSTREAM_RESOLVE=1 \
    NGINX_RESOLVER="" \
    gomplate < /etc/nginx/nginx.conf.template)

  echo "$fallback_nginx" | grep -F "resolver 169.254.169.253 valid=60s;" \
    || fail "expected default resolver when UPSTREAM_RESOLVE=1 and NGINX_RESOLVER is empty"
fi

LISTEN_PORT="8080" \
KEEPALIVE_TIMEOUT="65" \
PROXY_REVERSE_URL="http://localhost:8081" \
SERVER_NAME="localhost" \
HEALTHCHECK_PATH="/health" \
STATIC_LOCATIONS="/static/:/test/static/" \
  /docker-entrypoint.sh

go build -o app main.go

# Start test server
LISTEN_PORT=8081 /test/app &
app=$!

# Start reverse proxy
nginx -g "daemon off;" &
nginx=$!

sleep 1

cleanup() {
  kill $nginx
  kill $app
}

trap cleanup EXIT

TEST_URL="http://localhost:8080" go test

# Clean up, but leave this file if it fails
rm /etc/nginx/conf.d/default.conf
