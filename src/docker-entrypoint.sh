#!/bin/bash

set -e

run-parts --exit-on-error /docker-entrypoint.d

exec "$@"
