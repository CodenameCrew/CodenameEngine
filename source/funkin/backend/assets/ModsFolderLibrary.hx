package funkin.backend.assets;

import openfl.utils.AssetLibrary;
import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.text.Font;
import lime.utils.Bytes;

#if MOD_SUPPORT
import sys.FileStat;
import sys.FileSystem;
#end

using StringTools;

class ModsFolderLibrary extends AssetLibrary implements IModsAssetLibrary {
	public var basePath:String;
	public var modName:String;
	public var libName:String;
	//public var useImageCache:Bool = true;
	public var prefix = 'assets/';

	public function new(basePath:String, libName:String, ?modName:String) {
		this.basePath = basePath;
		this.libName = libName;
		this.prefix = 'assets/$libName/';
		this.modName = modName == null ? libName : modName;
		super();
	}

	function toString():String {
		return '(ModsFolderLibrary: $modName)';
	}

	#if MOD_SUPPORT
	private var editedTimes:Map<String, Float> = [];
	public var _parsedAsset:String = null;

	public function getEditedTime(asset:String):Null<Float> {
		return editedTimes[asset];
	}

	public override function getAudioBuffer(id:String):AudioBuffer {
		if (!exists(id, "SOUND"))
			return null;
		var path = getAssetPath();
		editedTimes[id] = FileSystem.stat(path).mtime.getTime();
		var e = AudioBuffer.fromFile(path);
		// LimeAssets.cache.audio.set('$libName:$id', e);
		return e;
	}

	public override function getBytes(id:String):Bytes {
		if (!exists(id, "BINARY"))
			return null;
		var path = getAssetPath();
		editedTimes[id] = FileSystem.stat(path).mtime.getTime();
		var e = Bytes.fromFile(path);
		return e;
	}

	public override function getFont(id:String):Font {
		if (!exists(id, "FONT"))
			return null;
		var path = getAssetPath();
		editedTimes[id] = FileSystem.stat(path).mtime.getTime();
		return ModsFolder.registerFont(Font.fromFile(path));
	}

	public override function getImage(id:String):Image {
		if (!exists(id, "IMAGE"))
			return null;
		var path = getAssetPath();
		editedTimes[id] = FileSystem.stat(path).mtime.getTime();

		var e = Image.fromFile(path);
		return e;
	}

	public override function getPath(id:String):String {
		if (!__parseAsset(id)) return null;
		return getAssetPath();
	}

	public inline function getFolders(folder:String):Array<String>
		return __getFiles(folder, true);

	public inline function getFiles(folder:String):Array<String>
		return __getFiles(folder, false);

	public function __getFiles(folder:String, folders:Bool = false) {
		if (!folder.endsWith("/")) folder += "/";
		if (!__parseAsset(folder)) return [];
		var path = getAssetPath();
		try {
			var result:Array<String> = [];
			for(e in FileSystem.readDirectory(path))
				if (FileSystem.isDirectory('$path$e') == folders)
					result.push(e);
			return result;
		} catch(e) {
			// woops!!
		}
		return [];
	}

	public override function exists(asset:String, type:String):Bool {
		if(!__parseAsset(asset)) return false;
		return FileSystem.exists(getAssetPath());
	}

	private function getAssetPath() {
		return '$basePath/$_parsedAsset';
	}

	private function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocalCache:Bool = false) {
		if (!editedTimes.exists(asset))
			return false;
		var editedTime = editedTimes[asset];
		if (editedTime == null || editedTime < FileSystem.stat(getPath(asset)).mtime.getTime()) {
			// destroy already existing to prevent memory leak!!!
			/*var asset = cache[asset];
			if (asset != null) {
				switch(Type.getClass(asset)) {
					case lime.graphics.Image:
						trace("getting rid of image cause replaced");
						cast(asset, lime.graphics.Image);
				}
			}*/
			return false;
		}

		if (!isLocalCache) asset = '$libName:$asset';

		return cache.exists(asset) && cache[asset] != null;
	}

	private function __parseAsset(asset:String):Bool {
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
		return true;
	}
	#end

	// Backwards compat

	@:noCompletion public var folderPath(get, set):String;
	@:noCompletion private inline function get_folderPath():String {
		return basePath;
	}
	@:noCompletion private inline function set_folderPath(value:String):String {
		return basePath = value;
	}
}