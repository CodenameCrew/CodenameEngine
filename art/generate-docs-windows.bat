@ECHO OFF
cd ..
echo Generating documentation...
echo Platform is based on Windows
haxelib run lime build windows --haxeflag="-xml docs/doc.xml" -D doc-gen -D DOCUMENTATION --no-output

echo The XML file for the API documentation has been generated at docs/doc.xml.
echo For updating the API documentation hosted at the website, please replace codename-website/api-generator/api/doc.xml with the file listed above.
