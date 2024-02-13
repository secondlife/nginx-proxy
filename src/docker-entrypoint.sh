#!/bin/bash

set -e

# Transform legacy PROXY_REVERSE_URL to UPSTREAM_SERVER
if [[ -n $PROXY_REVERSE_URL ]]; then
  export UPSTREAM_SERVER=${PROXY_REVERSE_URL#http://}
fi

run-parts --exit-on-error /docker-entrypoint.d

exec "$@"
