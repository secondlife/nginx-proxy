#!/bin/bash

set -e

function fail {
    echo "$@" >&2
    exit 1
}

LISTEN_PORT="8080" \
KEEPALIVE_TIMEOUT="65" \
UPSTREAM_SERVER="localhost:8081" \
SERVER_NAME="localhost" \
PROXY_UWSGI="1" \
STATIC_LOCATIONS="/static/:/test/static/" \
  /docker-entrypoint.sh

# Start test server
uwsgi --socket ":8081" --master --plugin python --wsgi-file app.py &
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

curl -fs http://localhost:8080/ || fail "Failed to get /"
