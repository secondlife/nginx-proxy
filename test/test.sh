#!/bin/bash

set -e

function fail {
    echo "$@" >&2
    exit 1
}

LISTEN_PORT="8080" PROXY_REVERSE_URL="http://localhost:8081" /docker-entrypoint.sh

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
