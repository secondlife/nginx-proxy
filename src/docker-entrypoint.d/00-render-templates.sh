#!/bin/bash

set -eo pipefail

source /docker-entrypoint.d/functions

function render_templates {
  local src="$1"
  local dst="$2"
  for f in $src; do
    final=$(basename "$f")
    final=${final%.template}
    final="$dst/$final"
    cat "$f" | gomplate > "$final"
    log "$0: Rendered $f and moved it to $final"
  done
}

render_templates "/etc/nginx/*.template" "/etc/nginx"
render_templates "/etc/nginx/conf.d/*.template" "/etc/nginx/conf.d"
render_templates "/etc/nginx/includes/*.template" "/etc/nginx/includes"
