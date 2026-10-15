#!/bin/sh
set -eu
module_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
build_file=$(mktemp "$module_dir/.portfolio_underline.XXXXXX.so")
trap 'rm -f "$build_file"' EXIT HUP INT TERM
cc -std=c11 -O2 -Wall -Wextra -Werror -fPIC -shared \
    "$module_dir/portfolio_underline.c" \
    -o "$build_file" \
    $(pkg-config --cflags --libs gtk+-3.0) -lm
chmod 644 "$build_file"
mv -f "$build_file" "$module_dir/portfolio_underline.so"
