#!/usr/bin/env sh
cd "$(dirname "$0")/.."
haxe -cp commandline -D analyzer-optimize --run Main $@