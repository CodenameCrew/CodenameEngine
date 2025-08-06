package funkin.backend.assets;

import haxe.io.Path;
import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.text.Font;
import lime.utils.Bytes;
import openfl.utils.AssetLibrary;

#if MOD_SUPPORT
import funkin.backend.utils.SysZip.SysZipEntry;
import funkin.backend.utils.SysZip;

class ZipFolderLibrary extends AssetLibrary implements IModsAssetLibrary {
	public var basePath:String;
	public var modName:String;
	public var libName:String;
	public var useImageCache:Bool = false;
	public var prefix = 'assets/';

	public var zip:SysZip;
	public var assets:Map<String, SysZipEntry> = [];
	public var lowerCaseAssets:Map<String, SysZipEntry> = [];
	public var nameMap:Map<String, String> = [];

	public function new(basePath:String, libName:String, ?modName:String) {
		this.libName = libName;

		this.basePath = basePath;
		
		this.modName = (modName == null) ? libName : modName;

		zip = SysZip.openFromFile(basePath);
		zip.read();
		for(entry in zip.entries) {
			lowerCaseAssets[entry.fileName.toLowerCase()] = assets[entry.fileName.toLowerCase()] = assets[entry.fileName] = entry;
			nameMap.set(entry.fileName.toLowerCase(), entry.fileName);
		}

		super();
	}

	function toString():String {
		return '(ZipFolderLibrary: $libName/$modName)';
	}

	public var _parsedAsset:String;

	public override function getAudioBuffer(id:String):AudioBuffer {
		__parseAsset(id);
		return AudioBuffer.fromBytes(unzip(assets[_parsedAsset]));
	}
	public override function getBytes(id:String):Bytes {
		__parseAsset(id);
		return Bytes.fromBytes(unzip(assets[_parsedAsset]));
	}
	public override function getFont(id:String):Font {
		__parseAsset(id);
		return ModsFolder.registerFont(Font.fromBytes(unzip(assets[_parsedAsset])));
	}
	public override function getImage(id:String):Image {
		__parseAsset(id);
		return Image.fromBytes(unzip(assets[_parsedAsset]));
	}

	public override function getPath(id:String):String {
		if (!__parseAsset(id)) return null;
		return getAssetPath();
	}



	public inline function unzip(f:SysZipEntry)
		return f == null ? null : zip.unzipEntry(f);

	public function __parseAsset(asset:String):Bool {
		if (!asset.startsWith(prefix)) return false;
		_parsedAsset = asset.substr(prefix.length);
		if(ModsFolder.useLibFile) {
			var file = new haxe.io.Path(_parsedAsset);
			if(file.file.startsWith("LIB_")) {
				var library = file.file.substr(4);
				if(library != modName) return false;

				_parsedAsset = file.dir + "." + file.ext;
			}
		}

		_parsedAsset = _parsedAsset.toLowerCase();
		if(nameMap.exists(_parsedAsset))
			_parsedAsset = nameMap.get(_parsedAsset);
		return true;
	}

	public function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocal:Bool = false) {
		if (cache.exists(isLocal ? '$libName:$asset': asset)) return true;
		return false;
	}

	public override function exists(asset:String, type:String):Bool {
		if(!__parseAsset(asset)) return false;

		return assets[_parsedAsset] != null;
	}

	private function getAssetPath() {
		trace('[ZIP]$basePath/$_parsedAsset');
		return '[ZIP]$basePath/$_parsedAsset';
	}

	// TODO: rewrite this to 1 function, like ModsFolderLibrary
	public function getFiles(folder:String):Array<String> {
		if (!folder.endsWith("/")) folder += "/";
		if (!__parseAsset(folder)) return [];

		var content:Array<String> = [];

		var checkPath = _parsedAsset.toLowerCase();

		@:privateAccess
		for(k=>e in lowerCaseAssets) {
			if (k.toLowerCase().startsWith(checkPath)) {
				if(nameMap.exists(k))
					k = nameMap.get(k);
				var fileName = k.substr(_parsedAsset.length);
				if (!fileName.contains("/") && fileName.length > 0)
					content.pushOnce(fileName);
			}
		}
		return content;
	}

	public function getFolders(folder:String):Array<String> {
		if (!folder.endsWith("/")) folder += "/";
		if (!__parseAsset(folder)) return [];

		var content:Array<String> = [];

		var checkPath = _parsedAsset.toLowerCase();

		@:privateAccess
		for(k=>e in lowerCaseAssets) {
			if (k.toLowerCase().startsWith(checkPath)) {
				if(nameMap.exists(k))
					k = nameMap.get(k);
				var fileName = k.substr(_parsedAsset.length);
				var index = fileName.indexOf("/");
				if (index != -1 && fileName.length > 0) {
					var s = fileName.substr(0, index);
					content.pushOnce(s);
				}
			}
		}
		return content;
	}

	// Backwards compat

	@:noCompletion public var zipPath(get, set):String;
	@:noCompletion private inline function get_zipPath():String {
		return basePath;
	}
	@:noCompletion private inline function set_zipPath(value:String):String {
		return basePath = value;
	}
}
#end