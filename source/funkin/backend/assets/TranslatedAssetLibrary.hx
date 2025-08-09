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

	public inline function formatPath(mainPath:String, ?asset:String):String {
		if(!mainPath.endsWith('/')) mainPath += '/';
		return mainPath + getAssetPath() + (asset == null ? "" : asset);
	}

	public override function getAudioBuffer(id:String):AudioBuffer
	{
		// TODO: rewrite this, once it works
		var libs = [forLibrary];
		for(lib in libs) {
			if(!(lib is AssetLibrary)) continue;
			var val = cast(lib, AssetLibrary).getAudioBuffer(formatPath(lib.prefix, id));
			if(val != null) return val;
		}
		return null;
	}

	public override function getBytes(id:String):Bytes
	{
		var libs = [forLibrary];
		for(lib in libs) {
			if(!(lib is AssetLibrary)) continue;
			var val = cast(lib, AssetLibrary).getBytes(formatPath(lib.prefix, id));
			if(val != null) return val;
		}
		return null;
	}

	public override function getText(id:String):String
	{
		var libs = [forLibrary];
		for(lib in libs) {
			if(!(lib is AssetLibrary)) continue;
			var val = cast(lib, AssetLibrary).getText(formatPath(lib.prefix, id));
			if(val != null) return val;
		}
		return null;
	}

	public override function getFont(id:String):Font
	{
		var libs = [forLibrary];
		for(lib in libs) {
			if(!(lib is AssetLibrary)) continue;
			var val = cast(lib, AssetLibrary).getFont(formatPath(lib.prefix, id));
			if(val != null) return val;
		}
		return null;
	}

	public override function getImage(id:String):Image
	{
		var libs = [forLibrary];
		for(lib in libs) {
			if(!(lib is AssetLibrary)) continue;
			var val = cast(lib, AssetLibrary).getImage(formatPath(lib.prefix, id));
			if(val != null) return val;
		}
		return null;
	}

	public override function getPath(id:String):String
	{
		var libs = [forLibrary];
		for(lib in libs) {
			if(!(lib is AssetLibrary)) continue;
			var val = cast(lib, AssetLibrary).getPath(formatPath(lib.prefix, id));
			if(val != null) return val;
		}
		return null;
	}

	#if MOD_SUPPORT
	public var _parsedAsset:String = null;  // Theres no need to actually make this work  - Nex

	public function getFiles(folder:String):Array<String>
	{
		var libs = [forLibrary];
		for(lib in libs) {
			if(!(lib is AssetLibrary)) continue;
			var val = lib.getFiles(formatPath(lib.prefix, folder));
			if(val != null && val.length > 0) return val;
		}
		return [];
	}

	public function getFolders(folder:String):Array<String>
	{
		var libs = [forLibrary];
		for(lib in libs) {
			if(!(lib is AssetLibrary)) continue;
			var val = lib.getFolders(formatPath(lib.prefix, folder));
			if(val != null && val.length > 0) return val;
		}
		return [];
	}

	private function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocal:Bool = false):Bool
	{
		var libs = [forLibrary];
		for(lib in libs) {
			if(!(lib is AssetLibrary)) continue;

			// are you fucking serious (no the fucking switch doesnt work here)  - Nex
			var _lib = cast(lib, AssetLibrary);
			var libCache = (cache == cachedAudioBuffers) ? _lib.cachedAudioBuffers :
				(cache == cachedBytes) ? _lib.cachedBytes :
				(cache == cachedFonts) ? _lib.cachedFonts :
				(cache == cachedImages) ? _lib.cachedImages :
				(cache == cachedText) ? _lib.cachedText : cache;

			@:privateAccess if(lib.__isCacheValid(libCache, formatPath(lib.prefix, asset), isLocal)) return true;
		}
		return false;
	}

	private function __parseAsset(asset:String):Bool
	{
		@:privateAccess
		var libs = [forLibrary];
		for(lib in libs) {
			if(!(lib is AssetLibrary)) continue;
			if(lib.__parseAsset(formatPath(lib.prefix, asset))) return true;
		}
		return false;
	}
	#end

	public override function exists(id:String, type:String):Bool
	{
		for(lib in ModsFolder.getLoadedModsLibs(true)) if(lib is AssetLibrary && cast(lib, AssetLibrary).exists(formatPath(lib.prefix, id), type)) return true;
		return false;
	}
}