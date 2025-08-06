package external;

#if (mac && cpp)
@:build(external.LinkerMacro.xml('external_code.xml'))
@:include('Mac.h')
@:native('ExternalMac')
extern class ExternalMac
{
	@:native('ExternalMac::setCursorIcon')
	public static function setCursorIcon(icon:Int, customCursor:cpp.ConstCharStar, customX:Single, customY:Single):Bool;
}
#end
