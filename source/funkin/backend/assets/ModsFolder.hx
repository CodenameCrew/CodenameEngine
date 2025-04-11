package funkin.backend.assets;

import funkin.backend.system.MainState;
import funkin.menus.TitleState;
import funkin.backend.system.Main;
import openfl.utils.AssetCache;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.utils.AssetManifest;
import openfl.utils.AssetLibrary;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxSignal.FlxTypedSignal;

import lime.text.Font;
import openfl.text.Font as OpenFLFont;

#if MOD_SUPPORT
import sys.FileSystem;
#end

import flixel.FlxState;
import haxe.io.Path;

using StringTools;

class ModsFolder {
	/**
	 * INTERNAL - Only use when editing source mods!!
	 */
	@:dox(hide) public static var onModSwitch:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	/**
	 * Current mod folder. Will affect `Paths`.
	 */
	public static var currentModFolder:String = null;
	/**
	 * Path to the `mods` folder.
	 */
	public static var modsPath:String = "./mods/";
	/**
	 * Path to the `addons` folder.
	 */
	public static var addonsPath:String = "./addons/";

	/**
	 * If accessing a file as assets/data/global/LIB_mymod.hx should redirect to mymod:assets/data/global.hx
	 */
	public static var useLibFile:Bool = true;

	/**
	 * Whenever its the first time mods has been reloaded.
	 */
	private static var __firstTime:Bool = true;
	/**
	 * Initialises `mods` folder.
	 */
	public static function init() {
		if(!getModsList().contains(Options.lastLoadedMod))
			Options.lastLoadedMod = null;
	}

	/**
	 * Switches mod - unloads all the other mods, then load this one.
	 * @param libName
	 */
	public static function switchMod(mod:String) {
		Options.lastLoadedMod = currentModFolder = mod;
		reloadMods();
	}

	public static function reloadMods() {
		if (!__firstTime)
			FlxG.switchState(new MainState());
		__firstTime = false;
	}

	/**
	 * Loads a mod library from the specified path. Supports folders and zips.
	 * @param modName Name of the mod
	 * @param force Whenever the mod should be reloaded if it has already been loaded
	 */
	public static function loadModLib(path:String, force:Bool = false, ?modName:String) {
		#if MOD_SUPPORT
		if (FileSystem.exists('$path.zip'))
			return loadLibraryFromZip('$path'.toLowerCase(), '$path.zip', force, modName);
		else
			return loadLibraryFromFolder('$path'.toLowerCase(), '$path', force, modName);

		#else
		return null;
		#end
	}

	public static function getModsList():Array<String> {
		var mods:Array<String> = [];
		#if MOD_SUPPORT
		final modsList:Array<String> = FileSystem.readDirectory(modsPath);

		if (modsList == null || modsList.length <= 0)
			return mods;

		for (modFolder in modsList) {
			if (FileSystem.isDirectory('${modsPath}${modFolder}')) {
				mods.push(modFolder);
			} else {
				var ext = Path.extension(modFolder).toLowerCase();
				switch(ext) {
					case 'zip':
						// is a zip mod!!
						mods.push(Path.withoutExtension(modFolder));
				}
			}
		}
		#end
		return mods;
	}
	public static function getLoadedMods():Array<String> {
		var libs = [];
		for (i in Paths.assetsTree.libraries) {
			var l = i;
			if (l is openfl.utils.AssetLibrary) {
				var al = cast(l, openfl.utils.AssetLibrary);
				@:privateAccess
				if (al.__proxy != null) l = al.__proxy;
			}
			var libString:String;
			if (l is ScriptedAssetLibrary || l is IModsAssetLibrary) libString = cast(l, IModsAssetLibrary).modName;
			else continue;
			libs.push(libString);
		}
		return libs;
	}
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

	public static function prepareModLibrary(libName:String, lib:IModsAssetLibrary, force:Bool = false) {
		var openLib = prepareLibrary(libName, force);
		lib.prefix = 'assets/';
		@:privateAccess
		openLib.__proxy = cast(lib, lime.utils.AssetLibrary);
		return openLib;
	}

	#if MOD_SUPPORT
	public static function loadLibraryFromFolder(libName:String, folder:String, force:Bool = false, ?modName:String) {
		return prepareModLibrary(libName, new ModsFolderLibrary(folder, libName, modName), force);
	}

	public static function loadLibraryFromZip(libName:String, zipPath:String, force:Bool = false, ?modName:String) {
		return prepareModLibrary(libName, new ZipFolderLibrary(zipPath, libName, modName), force);
	}
	#end
}
