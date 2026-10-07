package funkin.backend.assets;

import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.text.Font;
import lime.utils.AssetLibrary;
import lime.utils.Bytes;

using StringTools;

class PackedAssetLibrary extends AssetLibrary implements IModsAssetLibrary {
	public var basePath:String = "";
	public var modName:String;
	public var libName:String;
	public var prefix = 'assets/';

	var source:AssetLibrary;
	var fileIndex:Map<String, Array<String>>;
	var folderIndex:Map<String, Array<String>>;

	public function new(source:AssetLibrary, libName:String, ?modName:String) {
		this.source = source;
		this.libName = libName;
		this.modName = modName == null ? libName : modName;
		super();
		@:privateAccess {
			types = source.types;
			paths = source.paths;
		}
	}

	function toString():String {
		return '(PackedAssetLibrary: $modName)';
	}

	public override function exists(id:String, type:String):Bool
		return source.exists(id, type);

	public override function getPath(id:String):String
		return source.getPath(id);

	public override function getAudioBuffer(id:String):AudioBuffer
		return source.getAudioBuffer(id);

	public override function getBytes(id:String):Bytes
		return source.getBytes(id);

	public override function getFont(id:String):Font
		return source.getFont(id);

	public override function getImage(id:String):Image
		return source.getImage(id);

	public override function getText(id:String):String
		return source.getText(id);

	public override function list(type:String):Array<String>
		return source.list(type);

	#if MOD_SUPPORT
	public var _parsedAsset:String = null;

	public function getFiles(folder:String):Array<String>
		return __getFiles(folder, false);

	public function getFolders(folder:String):Array<String>
		return __getFiles(folder, true);

	function __getFiles(folder:String, folders:Bool):Array<String> {
		if (fileIndex == null) buildIndex();
		if (!folder.endsWith("/")) folder += "/";
		var index = folders ? folderIndex : fileIndex;
		var entries = index.get(folder);
		#if android
		if (entries == null) {
			var folded = folder.toLowerCase();
			if (folded != folder) entries = index.get(folded);
		}
		#end
		return entries != null ? entries.copy() : [];
	}

	function buildIndex() {
		fileIndex = [];
		folderIndex = [];
		for (id in source.list(null)) {
			var start = 0;
			var slash = id.indexOf("/");
			while (slash != -1) {
				var parent = id.substr(0, start);
				var name = id.substring(start, slash);
				var entries = folderIndex.get(parent);
				if (entries == null) folderIndex.set(parent, entries = []);
				if (!entries.contains(name)) entries.push(name);
				start = slash + 1;
				slash = id.indexOf("/", start);
			}
			var parent = id.substr(0, start);
			var entries = fileIndex.get(parent);
			if (entries == null) fileIndex.set(parent, entries = []);
			entries.push(id.substr(start));
		}
	}

	private function getAssetPath():String
		return _parsedAsset;

	private function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocal:Bool = false):Bool {
		if (!isLocal) asset = '$libName:$asset';
		return cache.exists(asset) && cache[asset] != null;
	}

	private function __parseAsset(asset:String):Bool {
		if (!asset.startsWith(prefix)) return false;
		_parsedAsset = asset.substr(prefix.length);
		return true;
	}
	#end
}
