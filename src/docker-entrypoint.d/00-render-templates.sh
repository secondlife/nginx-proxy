#!/bin/bash

set -eo pipefail

source /docker-entrypoint.d/functions

for f in /etc/nginx/templates/*.template
do
  final=$(basename "$f")
  final=${final%.template}
  final="/etc/nginx/conf.d/$final"
  cat "$f" | gomplate > "$final"
  log "$0: Rendered $f and moved it to $final"
done
