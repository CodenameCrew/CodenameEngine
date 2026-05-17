package funkin.backend.assets;

import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.backend.system.MainState;
import haxe.io.Path;
import lime.text.Font;
import openfl.text.Font as OpenFLFont;
import openfl.utils.AssetLibrary;
import openfl.utils.AssetManifest;
import lime.system.System;

using StringTools;
#if MOD_SUPPORT
import sys.FileSystem;
#end

class ModsFolder {
	@:dox(hide) public static var onModSwitch:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	public static var currentModFolder:String = null;

	/**
	 * Path to the `mods` folder. 
	 * Now initialized dynamically based on platform.
	 */
	public static var modsPath:String = "./mods/";
	public static var addonsPath:String = "./addons/";

	public static var useLibFile:Bool = true;
	private static var __firstTime:Bool = true;

	/**
	 * Initializes paths and the `mods` folder.
	 */
	public static function init() {
		// platform Specific Paths
		#if ios
		var root:String = Path.addTrailingSlash(System.documentsDirectory);
		modsPath = root + "mods/";
		addonsPath = root + "addons/";

		#elseif android
		var root:String = haxe.io.Path.addTrailingSlash(haxe.io.Path.normalize("/storage/emulated/0/.CodenameEngine-v1.0.1/"));
        modsPath = root + "mods/";
        addonsPath = root + "addons/";
		
		#else
		modsPath = "./mods/";
		addonsPath = "./addons/";
		#end

		// Ensure directories exist
		#if MOD_SUPPORT
		try {
			if (!FileSystem.exists(modsPath)) FileSystem.createDirectory(modsPath);
			if (!FileSystem.exists(addonsPath)) FileSystem.createDirectory(addonsPath);
		} catch(e:Dynamic) {
			Logs.error("Failed to create mods/addons folders: " + e);
		}
		#end

		if(!getModsList().contains(Options.lastLoadedMod)) {
			if(Options.lastLoadedMod != null)
				Logs.warn("Mod \"" + Options.lastLoadedMod + "\" not found in mods list, switching to base game!");
			Options.lastLoadedMod = null;
		}
	}

	public static function switchMod(mod:String) {
		Options.lastLoadedMod = currentModFolder = mod;
		reloadMods();
		if(mod == null) mod = "(default)";
		
		Logs.traceColored([
			Logs.logText('Switched to mod: '),
			Logs.logText(mod, GREEN)
		], VERBOSE);
	}

	public static function reloadMods() {
		if (!__firstTime)
			FlxG.switchState(new MainState());
		__firstTime = false;
	}

	public static function loadModLib(path:String, force:Bool = false, ?modName:String) {
		#if MOD_SUPPORT
		for (ext in Flags.ALLOWED_ZIP_EXTENSIONS) {
			if (!FileSystem.exists('$path.$ext')) continue;
			return loadLibraryFromZip('$path'.toLowerCase(), '$path.$ext', force, modName);
		}
		return loadLibraryFromFolder('$path'.toLowerCase(), '$path', force, modName);
		#else
		return null;
		#end
	}

	public static function getModsList():Array<String> {
		var mods:Array<String> = [];
		#if MOD_SUPPORT
		if (!FileSystem.exists(modsPath)) return mods;
		
		final modsList:Array<String> = FileSystem.readDirectory(modsPath);
		if (modsList == null || modsList.length <= 0) return mods;

		for (modFolder in modsList) {
			var fullPath = modsPath + modFolder;
			if (FileSystem.isDirectory(fullPath)) {
				mods.push(modFolder);
			} else if (Flags.ALLOWED_ZIP_EXTENSIONS.contains(Path.extension(modFolder))) {
				mods.push(Path.withoutExtension(modFolder));
			}
		}
		#end
		return mods;
	}

	public static function getLoadedModsLibs(skipTranslated:Bool = false):Array<IModsAssetLibrary> {
		var libs = [];
		for (i in Paths.assetsTree.libraries) {
			var l = AssetsLibraryList.getCleanLibrary(i);
			#if TRANSLATIONS_SUPPORT
			if(skipTranslated && (l is TranslatedAssetLibrary)) continue;
			#end
			if (l is IModsAssetLibrary) libs.push(cast(l, IModsAssetLibrary));
		}
		return libs;
	}

	public static function getLoadedMods(skipTranslated:Bool = false):Array<String>
		return [for (modLib in getLoadedModsLibs(skipTranslated)) modLib.modName];

	public static function prepareLibrary(libName:String, force:Bool = false) {
		var assets:AssetManifest = new AssetManifest();
		assets.name = libName;
		assets.version = 2;
		assets.libraryArgs = [];
		assets.assets = [];
		return AssetLibrary.fromManifest(assets);
	}

	public static function registerFont(font:Font) {
		var openflFont = new OpenFLFont();
		@:privateAccess
		openflFont.__fromLimeFont(font);
		OpenFLFont.registerFont(openflFont);
		return font;
	}

	public static function prepareModLibrary(libName:String, lib:IModsAssetLibrary, force:Bool = false, ?tag:AssetSource) {
		var openLib = prepareLibrary(libName, force);
		lib.prefix = 'assets/';
		@:privateAccess
		openLib.__proxy = cast(lib, lime.utils.AssetLibrary);
		if (tag != null) {
			openLib.tag = tag;
			cast(lib, lime.utils.AssetLibrary).tag = tag;
		}
		return openLib;
	}

	#if MOD_SUPPORT
	public static function loadLibraryFromFolder(libName:String, folder:String, force:Bool = false, ?modName:String, ?tag:AssetSource = MODS) {
		return prepareModLibrary(libName, new ModsFolderLibrary(folder, libName, modName), force, tag);
	}

	public static function loadLibraryFromZip(libName:String, zipPath:String, force:Bool = false, ?modName:String, ?tag:AssetSource = MODS) {
		return prepareModLibrary(libName, new ZipFolderLibrary(zipPath, libName, modName), force, tag);
	}
	#end
}
