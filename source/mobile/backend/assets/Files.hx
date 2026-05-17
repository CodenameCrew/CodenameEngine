package mobile.backend.assets;

using StringTools;

import haxe.io.Path;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import lime.utils.Assets;
import lime.utils.Bytes;
import funkin.backend.assets.Paths;

#if android
import lime.app.Application;
import extension.androidtools.os.Build;
import extension.androidtools.os.Build.VERSION;
import extension.androidtools.os.Build.VERSION_CODES;
#end
/**
 * class made to handle copying the files to the needed place.
**/
#if mobile
class Files
{
	#if android
	private static var _androidDir:String = null;

	private static function getAndroidStorageDir():String
	{
		if (_androidDir != null) return _androidDir;

		var pkg:String = "com.yoshman29.codenameengine"; // fallback
		if (Application.current != null && Application.current.meta.get("packageName") != null) {
			pkg = Application.current.meta.get("packageName");
		}

		if (VERSION.SDK_INT >= VERSION_CODES.R) {
			_androidDir = "/storage/emulated/0/Android/obb/" + pkg + "/files/";
		} else {
			_androidDir = "/storage/emulated/0/Android/data/" + pkg + "/files/";
		}
		
		return _androidDir;
	}
	#end

	public static function getAssetsDir():String
	{
		#if android
		return getAndroidStorageDir();
		#elseif ios
		var dir = System.documentsDirectory;
		if (dir != null && !dir.endsWith("/")) dir += "/";
		return dir;
		#else
		return Sys.getCwd();
		#end
	}

	public static function getModsDir():String
	{
		#if android
		return getAndroidStorageDir();
		#elseif ios
		var dir = System.documentsDirectory;
		if (dir != null && !dir.endsWith("/")) dir += "/";
		return dir;
		#else
		return Sys.getCwd();
		#end
	}
	
	public static function init():Void
	{
		var assetsBase = Path.addTrailingSlash(getAssetsDir());
		var modsBase = Path.addTrailingSlash(getModsDir());

		trace("Assets target path: " + assetsBase);
		trace("Mods target path: " + modsBase);

		copyFolderOnce("assets", assetsBase + "assets/");
	}

	static function copyFolderOnce(folder:String, target:String):Void
	{
		#if sys
		if (FileSystem.exists(target))
		{
			trace(folder + " already exists, skipping.");
			return;
		}
		#end

		trace("Copying " + folder + "...");
		copyAssets(folder, target);
	}

	static function copyAssets(source:String, target:String):Void
	{
		var list:Array<String> = Assets.list();

		for (asset in list)
		{
			if (!asset.startsWith(source)) continue;

			var relative = asset.substr(source.length);
			if (relative.startsWith("/")) relative = relative.substr(1);

			var outPath = Path.addTrailingSlash(target) + relative;

			createDirRecursive(Path.directory(outPath));

			try {
				var bytes:Bytes = Assets.getBytes(asset);

				if (bytes != null)
					File.saveBytes(outPath, bytes);
				else
					File.saveContent(outPath, Paths.externalGetText(asset));

			} catch (e:Dynamic) {
				trace("Failed: " + asset + " -> " + e);
			}
		}

		trace("Finished copying " + source);
	}

	static function createDirRecursive(path:String):Void
	{
		#if sys
		if (path == null || path == "") return;

		path = Path.normalize(path);

		if (!FileSystem.exists(path))
			FileSystem.createDirectory(path);
		#end
	}
}
#end
