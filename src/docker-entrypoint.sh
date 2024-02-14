#!/bin/bash

set -e

# Transform legacy PROXY_REVERSE_URL to UPSTREAM_SERVER
if [[ -n $PROXY_REVERSE_URL ]]; then
  export UPSTREAM_SERVER=${PROXY_REVERSE_URL#http://}
fi

# Add EC2 IPv4 address to allowed hosts so that load balancers can talk to us
if [[ "$SERVER_NAME" != "_" ]]; then
  local_ipv4=$(curl --connect-timeout 2 -s http://169.254.169.254/2009-04-04/meta-data/local-ipv4 || true 2>/dev/null)
  if [[ -n "$local_ipv4" ]]
  then
    export SERVER_NAME="$SERVER_NAME $local_ipv4"
  fi
fi

run-parts --exit-on-error /docker-entrypoint.d

exec "$@"
