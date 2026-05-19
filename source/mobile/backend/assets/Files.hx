package mobile.backend.assets;

using StringTools;
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
        if (_androidDir != null)
            return _androidDir;

        if (VERSION.SDK_INT >= VERSION_CODES.R)
        {
            _androidDir = haxe.io.Path.addTrailingSlash(extension.androidtools.content.Context.getObbDir());
        }
        else
        {
            _androidDir = haxe.io.Path.addTrailingSlash(extension.androidtools.content.Context.getExternalFilesDir());
        }

        trace("ANDROID STORAGE DIR: " + _androidDir);

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
					File.saveContent(outPath, lime.utils.Assets.getText(asset));

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
