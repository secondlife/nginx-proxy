#!/bin/bash

set -e

function fail {
    echo "$@" >&2
    exit 1
}

LISTEN_PORT="8080" \
KEEPALIVE_TIMEOUT="65" \
PROXY_REVERSE_URL="http://localhost:8081" \
SERVER_NAME="localhost" \
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
