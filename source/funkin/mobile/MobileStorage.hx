package funkin.mobile;

import haxe.io.Path;
import sys.FileSystem;
#if android
import lime.system.JNI;
#end

class MobileStorage {
	public static var root(default, null):String = "";
	public static var mods(default, null):String = "./mods/";
	public static var addons(default, null):String = "./addons/";
	public static var saves(default, null):String = "./saves/";
	public static var extraMods(default, null):Array<String> = [];
	public static var extraAddons(default, null):Array<String> = [];

	public static function prepare() {
		#if android
		if (root.length > 0) return;
		var path = resolveRoot();
		if (path.length == 0) {
			var storage = lime.system.System.applicationStorageDirectory;
			if (storage != null && storage.length > 0) path = Path.addTrailingSlash(storage);
		}
		if (path.length > 0) useRoot(path);
		#end
	}

	public static function apply() {
		#if android
		if (root.length == 0) prepare();
		if (root.length == 0) return;

		funkin.backend.assets.ModsFolder.modsPath = mods;
		funkin.backend.assets.ModsFolder.addonsPath = addons;
		funkin.backend.assets.ModsFolder.extraModsPaths = extraMods;
		funkin.backend.assets.ModsFolder.extraAddonsPaths = extraAddons;
		ensure(mods);
		ensure(addons);
		ensure(saves);
		if (!listening) {
			listening = true;
			lime.app.Application.current.window.onFocusIn.add(refresh);
		}
		Logs.verbose('Mobile storage: mods=$mods saves=$saves');
		#end
	}

	public static function refresh() {
		#if android
		var path = resolveRoot();
		if (path.length == 0 || path == root) return;
		useRoot(path);
		apply();
		#end
	}

	public static function hasPublicFolder():Bool {
		#if android
		try {
			if (hasAccess == null)
				hasAccess = activityMethod("hasStorageAccess", "()Z");
			return hasAccess();
		} catch (e:Dynamic) Logs.warn('Could not check storage access: $e');
		return false;
		#else
		return true;
		#end
	}

	public static function requestPublicFolder() {
		#if android
		try {
			if (requestAccess == null)
				requestAccess = activityMethod("requestStorageAccess", "()V");
			requestAccess();
		} catch (e:Dynamic) Logs.warn('Could not request storage access: $e');
		#end
	}

	#if android
	static var listening:Bool = false;
	static var storagePath:Dynamic;
	static var extraStoragePath:Dynamic;
	static var hasAccess:Dynamic;
	static var requestAccess:Dynamic;

	static function useRoot(path:String) {
		root = path;
		try Sys.setCwd(root) catch (e:Dynamic) Logs.warn('Could not set working directory: $e');
		mods = root + "mods/";
		addons = root + "addons/";
		saves = root + "saves/";
		ensure(mods);
		ensure(addons);
		ensure(saves);
		extraMods = [];
		extraAddons = [];
		for (extra in resolveExtras()) {
			if (extra == path) continue;
			var extraModDir = extra + "mods/";
			var extraAddonDir = extra + "addons/";
			ensure(extraModDir);
			ensure(extraAddonDir);
			extraMods.push(extraModDir);
			extraMods.push(extra);
			extraAddons.push(extraAddonDir);
		}
	}

	static function resolveRoot():String {
		var path:String = null;
		try {
			if (storagePath == null)
				storagePath = activityMethod("storagePath", "()Ljava/lang/String;");
			path = storagePath();
		} catch (e:Dynamic) Logs.warn('Could not read storage path: $e');
		if (path == null || path.length == 0) return "";
		return Path.addTrailingSlash(path);
	}

	static function resolveExtras():Array<String> {
		var folders:Array<String> = [];
		var raw:String = null;
		try {
			if (extraStoragePath == null)
				extraStoragePath = activityMethod("extraStoragePaths", "()Ljava/lang/String;");
			raw = extraStoragePath();
		} catch (e:Dynamic) Logs.warn('Could not read extra storage paths: $e');
		if (raw == null || raw.length == 0) return folders;
		for (piece in raw.split("|")) {
			if (piece == null || piece.length == 0) continue;
			folders.push(Path.addTrailingSlash(piece));
		}
		return folders;
	}

	static function ensure(path:String) {
		if (path == null || path.length == 0 || FileSystem.exists(path)) return;
		try FileSystem.createDirectory(path) catch (e:Dynamic) Logs.warn('Could not create $path: $e');
	}

	static function activityMethod(name:String, signature:String):Dynamic
		return JNI.createStaticMethod("com/yoshman29/codenameengine/MobileActivity", name, signature);
	#end
}
