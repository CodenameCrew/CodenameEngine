#!/usr/bin/env sh
cd "$(dirname "$0")/.."
echo Generating documentation...
if [ $(uname) == "Linux" ]; then
    echo "Platform is based on Linux"
    haxelib run lime build linux --haxeflag="-xml docs/doc.xml" -D doc-gen -D DOCUMENTATION --no-output
elif [ $(uname) == "Darwin" ]; then
    echo "Platform is macOS"
    haxelib run lime build mac --haxeflag="-xml docs/doc.xml" -D doc-gen -D DOCUMENTATION --no-output
else
    echo "Platform $(uname) is incompatible with documentation generation, exiting..."
    exit 126
fi

echo "The XML file for the API documentation has been generated at docs/doc.xml."
echo "For updating the API documentation hosted at the website, please replace codename-website/api-generator/api/doc.xml with the file listed above."
