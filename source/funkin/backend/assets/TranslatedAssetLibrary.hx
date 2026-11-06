package funkin.backend.assets;

import lime.utils.AssetLibrary as LimeAssetLibrary;
import openfl.utils.AssetLibrary;
import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.text.Font;
import lime.utils.Bytes;

class TranslatedAssetLibrary extends AssetLibrary implements IModsAssetLibrary {
	public var libName:String;
	public var modName:String;
	public var basePath:String;
	public var prefix:String = TranslationUtil.LANG_FOLDER + "/";

	public var forLibrary:IModsAssetLibrary;

	public var langFolder(get, set):String;
	@:noCompletion private inline function get_langFolder():String {
		return libName;
	}
	@:noCompletion private inline function set_langFolder(value:String):String {
		basePath = prefix + (libName = modName = (value != null ? value : Flags.DEFAULT_LANGUAGE)) + "/";
		return libName;
	}

	public function new(lib:IModsAssetLibrary, ?langFolder:String) {
		super();
		this.forLibrary = lib;
		this.langFolder = langFolder;
	}

	function toString():String
		return '(TranslatedAssetLibrary: Lang: $libName | For: ${forLibrary})';

	private inline function getAssetPath():String  // because of the IModsAssetLibrary  - Nex
		return basePath;

	private inline function formatPath(?asset:String):String
		return (forLibrary.prefix.charCodeAt(forLibrary.prefix.length - 1) == '/'.code ? forLibrary.prefix : '${forLibrary.prefix}/')
			+ getAssetPath() + (asset == null ? "" : asset);

	public override function getAudioBuffer(id:String):AudioBuffer
		return (forLibrary is AssetLibrary) ? cast(forLibrary, AssetLibrary).getAudioBuffer(formatPath(id)) : null;

	public override function getBytes(id:String):Bytes
		return (forLibrary is AssetLibrary) ? cast(forLibrary, AssetLibrary).getBytes(formatPath(id)) : null;

	public override function getText(id:String):String
		return (forLibrary is AssetLibrary) ? cast(forLibrary, AssetLibrary).getText(formatPath(id)) : null;

	public override function getFont(id:String):Font
		return (forLibrary is AssetLibrary) ? cast(forLibrary, AssetLibrary).getFont(formatPath(id)) : null;

	public override function getImage(id:String):Image
		return (forLibrary is AssetLibrary) ? cast(forLibrary, AssetLibrary).getImage(formatPath(id)) : null;

	public override function getPath(id:String):String
		return (forLibrary is AssetLibrary) ? cast(forLibrary, AssetLibrary).getPath(formatPath(id)) : null;

	#if MOD_SUPPORT
	public var _parsedAsset:String = null;  // Theres no need to actually make this work  - Nex

	public function getFiles(folder:String):Array<String>
		return forLibrary.getFiles(formatPath(folder));

	public function getFolders(folder:String):Array<String>
		return forLibrary.getFolders(formatPath(folder));

	private function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocal:Bool = false):Bool {
		if (!(forLibrary is AssetLibrary)) return false;

		final lib = cast(forLibrary, AssetLibrary);
		final libCache = (cache == cachedAudioBuffers) ? lib.cachedAudioBuffers :
			(cache == cachedBytes) ? lib.cachedBytes :
			(cache == cachedFonts) ? lib.cachedFonts :
			(cache == cachedImages) ? lib.cachedImages :
			(cache == cachedText) ? lib.cachedText : cache;

		return forLibrary.__isCacheValid(libCache, formatPath(asset), isLocal);
	}

	private function __parseAsset(asset:String):Bool
		return forLibrary.__parseAsset(formatPath(asset));
	#end

	public override function exists(id:String, type:String):Bool
		return (forLibrary is AssetLibrary) && cast(forLibrary, AssetLibrary).exists(formatPath(id), type);
}