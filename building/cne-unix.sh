#!/usr/bin/env sh
cd ..
haxe -cp commandline -D analyzer-optimize --run Main $@
