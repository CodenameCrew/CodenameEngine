@ECHO OFF
cd ..
echo Building Game...
lime build windows --haxeflag="-xml docs/doc.xml" -D doc-gen -D DOCUMENTATION --no-output
echo art

echo Generated the api xml file at docs/doc.xml
echo Please put this in codename-website/api-generator/api/doc.xml