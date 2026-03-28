package funkin.backend.assets;

import funkin.backend.system.Flags;

import haxe.io.Path;
import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.text.Font;
import lime.utils.Bytes;
import openfl.utils.AssetLibrary;
import sys.io.File;

#if MOD_SUPPORT
import funkin.backend.utils.SysZip.SysZipEntry;
import funkin.backend.utils.SysZip;

class ZipFolderLibrary extends AssetLibrary implements IModsAssetLibrary {
	public var basePath:String;
	public var modName:String;
	public var libName:String;
	public var prefix = 'assets/';
	
	public var zip:SysZip;
	public var assets:Map<String, SysZipEntry> = [];
	public var lowerCaseAssets:Map<String, SysZipEntry> = [];
	public var nameMap:Map<String, String> = [];

	public var PRELOAD_VIDEOS:Bool = true;

	public function new(basePath:String, libName:String, ?modName:String, ?preloadVideos:Bool = true) {
		this.libName = libName;

		this.basePath = basePath;
		
		this.modName = (modName == null) ? libName : modName;

		zip = SysZip.openFromFile(basePath);
		for(entry in zip.entries) {
			if (entry.fileName.length < 0 || entry.fileName.endsWith("/")) continue;

			var name:String = entry.fileName.toLowerCase(); // calling .toLowerCase a million times is never the solution
			lowerCaseAssets[name] = assets[name] = assets[entry.fileName] = entry;
			nameMap.set(name, entry.fileName);
		}

		super();

		isCompressed = true;
		
		// don't override default value of true if the file exists.
		// by default `PRELOAD_VIDEOS` is true so you will never need to add this file, but in the case of it being false this is a backup method.
		PRELOAD_VIDEOS = (!PRELOAD_VIDEOS) ? exists("assets/data/PRECACHE_VIDEOS", "TEXT") : PRELOAD_VIDEOS;

		// if (PRELOAD_VIDEOS) precacheVideos(); // we do this in `MainState` now to handle for `Flags.VIDEO_EXT` :)
	}

	public function precacheVideos() {
		_videoExtensions = [Flags.VIDEO_EXT];
		
		videoCacheRemap = [];
		for (entry in zip.entries) {
			var name = entry.fileName.toLowerCase();
			if (_videoExtensions.contains(Path.extension(name))) getPath(prefix+name);
		}

		var count:Int = 0;
        for (_ in videoCacheRemap.keys()) count++;
		if (count <= 0) return;
		trace('Precached $count video${(count == 1) ? "" : "s"}');
	}

	// Now we have supports for videos in ZIP!!
	public var _videoExtensions:Array<String> = [Flags.VIDEO_EXT];
	public var videoCacheRemap:Map<String, String> = [];
	public function getVideoRemap(originalPath:String):String {
		if (!_videoExtensions.contains(Path.extension(_parsedAsset))) return originalPath;
		if (videoCacheRemap.exists(originalPath)) return videoCacheRemap.get(originalPath);

		// We adding the length of the string to counteract folder in folder naming duplicates.
		var newPath = './.temp/${_parsedAsset.length}-zipvideo-${_parsedAsset.split("/").pop()}';
		File.saveBytes(newPath, unzip(assets[_parsedAsset]));
		videoCacheRemap.set(originalPath, newPath);
		return newPath;
	}

	function toString():String {
		return '(ZipFolderLibrary: $libName/$modName | ${zip.entries.length} entries | Detected Video Extensions: ${_videoExtensions.join(", ")})';
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

	public inline function unzip(f:SysZipEntry) return (f == null) ? null : zip.unzipEntry(f);

	public function __parseAsset(asset:String):Bool {
		if (!asset.startsWith(prefix)) return false;
		_parsedAsset = asset.substr(prefix.length);
		if (ModsFolder.useLibFile) {
			var file = new haxe.io.Path(_parsedAsset);
			if(file.file.startsWith("LIB_")) {
				var library = file.file.substr(4);
				if(library != modName) return false;

				_parsedAsset = file.dir + "." + file.ext;
			}
		}

		_parsedAsset = _parsedAsset.toLowerCase();
		if (nameMap.exists(_parsedAsset)) _parsedAsset = nameMap.get(_parsedAsset);
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

	private inline function getAssetPath() {
		return getVideoRemap('$basePath/$_parsedAsset');
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

	public override function list(type:String):Array<String> { return [for(k=>e in nameMap) '$prefix$e']; }
}
#end