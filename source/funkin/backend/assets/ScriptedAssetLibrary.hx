package funkin.backend.assets;

import funkin.backend.scripting.Script;
import lime.utils.AssetLibrary;
import lime.utils.Assets as LimeAssets;

import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.text.Font;
import lime.utils.Bytes;

#if MOD_SUPPORT
import sys.FileStat;
import sys.FileSystem;
#end

using StringTools;

class ScriptedAssetLibrary extends ModsFolderLibrary {
	public var script:Script;
	public var scriptName:String;
	private static var nullValue:Dynamic = {};

	public function new(scriptName:String, args:Array<Dynamic> = null, folderPath:String, libName:String="assets", ?modName:String) {
		if(folderPath == null) folderPath = #if mobile MobileUtil.getStorageDirectory() + #end "assets/";
		if(modName == null) modName = scriptName;
		super(folderPath, libName, modName);
		this.scriptName = scriptName;
		script = Script.create(Paths.script("data/library/" + scriptName));
		script.setParent(this);
		script.set("NULL", nullValue); // hackyway
		script.load();
		if(args == null) args = [];
		script.call("create", args);
		trace(script);
	}

	#if MOD_SUPPORT
	public override function getEditedTime(asset:String):Null<Float> {
		var result:Dynamic = script.call("getEditedTime", [asset]);
		if(result != null) {
			return result == nullValue ? null : result;
		}
		return super.getEditedTime(asset);
	}

	public override function getAudioBuffer(id:String):AudioBuffer {
		var result:Dynamic = script.call("getAudioBuffer", [id]);
		if(result != null) {
			return result == nullValue ? null : result;
		}
		return super.getAudioBuffer(id);
	}

	public override function getBytes(id:String):Bytes {
		var result:Dynamic = script.call("getBytes", [id]);
		if(result != null) {
			return result == nullValue ? null : result;
		}
		return super.getBytes(id);
	}

	public override function getFont(id:String):Font {
		var result:Dynamic = script.call("getFont", [id]);
		if(result != null) {
			return result == nullValue ? null : result;
		}
		return super.getFont(id);
	}

	public override function getImage(id:String):Image {
		var result:Dynamic = script.call("getImage", [id]);
		if(result != null) {
			return result == nullValue ? null : result;
		}
		return super.getImage(id);
	}

	public override function getPath(id:String):String {
		var result:Dynamic = script.call("getPath", [id]);
		if(result != null) {
			return result == nullValue ? null : result;
		}
		return super.getPath(id);
	}

	public override function __getFiles(folder:String, folders:Bool = false) {
		var result:Dynamic = script.call("__getFiles", [folder, folders]);
		if(result != null) {
			return result == nullValue ? null : result;
		}
		return super.__getFiles(folder, folders);
	}

	public override function exists(asset:String, type:String):Bool {
		var result:Dynamic = script.call("exists", [asset, type]);
		if(result != null) {
			return result == nullValue ? false : result;
		}
		return super.exists(asset, type);
	}

	private override function getAssetPath() {
		var result:Dynamic = script.call("getAssetPath", []);
		if(result != null) {
			return result == nullValue ? null : result;
		}
		return super.getAssetPath();
	}

	public override function list(type:String) {
		var result:Dynamic = script.call("list", [type]);
		if(result != null) {
			return result == nullValue ? null : result;
		}
		return super.list(type);
	}

	private override function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocalCache:Bool = false) {
		var result:Dynamic = script.call("__isCacheValid", [cache, asset, isLocalCache]);
		if(result != null) {
			return result == nullValue ? false : result;
		}
		return super.__isCacheValid(cache, asset, isLocalCache);
	}

	private override function __parseAsset(asset:String):Bool {
		var result:Dynamic = script.call("__parseAsset", [asset]);
		if(result != null) {
			return result == nullValue ? false : result;
		}
		return super.__parseAsset(asset);
	}
	#end
}