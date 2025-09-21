cd "$(dirname "$(cd "$(dirname "$0")" && pwd)")"
haxe -cp commandline -D analyzer-optimize --run Main setup