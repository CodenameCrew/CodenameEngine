package funkin.backend.assets;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.backend.assets.ModsFolder;
import funkin.backend.scripting.Script;
import haxe.io.Path;
import lime.utils.AssetLibrary;
import openfl.utils.Assets as OpenFlAssets;
import animate.FlxAnimateFrames;
#if sys
import sys.FileSystem;
#end
#if android
import extension.androidtools.content.Context;
import extension.androidtools.os.Build;
#end

using StringTools;

class Paths
{
	public static var assetsTree:AssetsLibraryList;
	public static var tempFramesCache:Map<String, FlxFramesCollection> = [];
	public static var pathCache:Map<String, String> = new Map();
	public static var folderContentCache:Map<String, Array<String>> = new Map();

	#if sys
	public static var fileModTimes:Map<String, Float> = new Map();
	#end

	public static function init() {
		FlxG.signals.preStateSwitch.add(function() {
			tempFramesCache.clear();
		});
	}

	public static function checkFileChanged(path:String):Bool {
		#if sys
		if (path == null) return false;
		
		if (FileSystem.exists(path)) {
			var currentModTime = FileSystem.stat(path).mtime.getTime();
			
			if (fileModTimes.exists(path)) {
				if (currentModTime > fileModTimes.get(path)) {
					fileModTimes.set(path, currentModTime);
					return true;
				}
			} else {
				fileModTimes.set(path, currentModTime);
			}
		}
		#end
		return false;
	}
	
	public static function cacheImage(key:String, ?library:String):FlxGraphic {
		var path = image(key, library);
		if (!FlxG.bitmap.checkCache(path)) {
			var graph = FlxG.bitmap.add(path, false, path);
			if (graph != null) {
				graph.persist = true;
			}
			return graph;
		}
		return FlxG.bitmap.get(path);
	}

	public static function getPath(file:String, ?library:String) {
		var cacheKey = library != null ? '$library:$file' : file;
		if (pathCache.exists(cacheKey)) return pathCache.get(cacheKey);

		var returnedPath:String = library != null ? '$library:assets/$library/$file' : 'assets/$file';
		#if (sys && !windows)
		returnedPath = Path.normalize(returnedPath);
		if (OpenFlAssets.exists(returnedPath)) {
			pathCache.set(cacheKey, returnedPath);
			return returnedPath;
		}
		var fixedPath:String = library != null ? '$library:assets/$library/' : 'assets/';
		var parts:Array<String> = returnedPath.split("/");
		for (it=>part in parts) {
			if (it == 0) continue;
			var entries:Array<String> = null;
			if (Path.extension(part) == "") entries = assetsTree.getFolders(fixedPath);
			else entries = assetsTree.getFiles(fixedPath);
			
			if (entries != null) {
				for (entry in entries) {
					if (entry.toLowerCase() == part.toLowerCase()) {
						fixedPath += entry + (it != parts.length - 1 ? "/" : "");
						break;
					}
				}
			}
		}
		if (returnedPath.toLowerCase() == fixedPath.toLowerCase()) returnedPath = fixedPath;
		#end
		
		pathCache.set(cacheKey, returnedPath);
		return returnedPath;
	}

	public static inline function video(key:String, ?ext:String)
		return getPath('videos/$key.${ext != null ? ext : Flags.VIDEO_EXT}');

	public static inline function ndll(key:String)
		return getPath('ndlls/$key.ndll');

	public static inline function file(file:String, ?library:String)
		return getPath(file, library);

	public static inline function txt(key:String, ?library:String)
		return getPath('data/$key.txt', library);

	public static inline function pack(key:String, ?library:String)
		return getPath('data/$key.pack', library);

	public static inline function ini(key:String, ?library:String)
		return getPath('data/$key.ini', library);

	public static inline function fragShader(key:String, ?library:String)
		return getPath('shaders/$key.frag', library);

	public static inline function vertShader(key:String, ?library:String)
		return getPath('shaders/$key.vert', library);

	public static inline function xml(key:String, ?library:String)
		return getPath('data/$key.xml', library);

	public static inline function json(key:String, ?library:String)
		return getPath('data/$key.json', library);

	public static inline function ps1(key:String, ?library:String)
		return getPath('data/$key.ps1', library);

	static public function sound(key:String, ?library:String, ?ext:String)
		return getPath('sounds/$key.${ext != null ? ext : Flags.SOUND_EXT}', library);

	public static inline function soundRandom(key:String, min:Int, max:Int, ?library:String)
		return sound(key + FlxG.random.int(min, max), library);

	inline static public function music(key:String, ?library:String, ?ext:String)
		return getPath('music/$key.${ext != null ? ext : Flags.SOUND_EXT}', library);

	inline static public function voices(song:String, ?difficulty:String, ?suffix:String = "", ?ext:String) {
		if (difficulty == null) difficulty = Flags.DEFAULT_DIFFICULTY;
		if (ext == null) ext = Flags.SOUND_EXT;
		var diff = getPath('songs/$song/song/Voices$suffix-${difficulty}.${ext}', null);
		return OpenFlAssets.exists(diff) ? diff : getPath('songs/$song/song/Voices$suffix.${ext}', null);
	}

	inline static public function inst(song:String, ?difficulty:String, ?suffix:String = "", ?ext:String) {
		if (difficulty == null) difficulty = Flags.DEFAULT_DIFFICULTY;
		if (ext == null) ext = Flags.SOUND_EXT;
		var diff = getPath('songs/$song/song/Inst$suffix-${difficulty}.${ext}', null);
		return OpenFlAssets.exists(diff) ? diff : getPath('songs/$song/song/Inst$suffix.${ext}', null);
	}

	static public function image(key:String, ?library:String, checkForAtlas:Bool = false, ?ext:String) {
		if (ext == null) ext = Flags.IMAGE_EXT;
		if (checkForAtlas) {
			var atlasPath = getPath('images/$key/spritemap.$ext', library);
			var multiplePath = getPath('images/$key/1.$ext', library);
			if (atlasPath != null && OpenFlAssets.exists(atlasPath)) return atlasPath.substr(0, atlasPath.length - 14);
			if (multiplePath != null && OpenFlAssets.exists(multiplePath)) return multiplePath.substr(0, multiplePath.length - 6);
		}
		return getPath('images/$key.$ext', library);
	}

	public static inline function script(key:String, ?library:String, isAssetsPath:Bool = false) {
		var scriptPath = isAssetsPath ? key : getPath(key, library);
		if (!OpenFlAssets.exists(scriptPath)) {
			var p:String;
			for(ex in Script.scriptExtensions) {
				if (OpenFlAssets.exists(p = scriptPath + '.' + ex)) {
					scriptPath = p;
					break;
				}
			}
		}
		return scriptPath;
	}

	static public function chart(song:String, ?difficulty:String, ?variant:String):String
	{
		difficulty = (difficulty != null ? difficulty : Flags.DEFAULT_DIFFICULTY);
		return getPath('songs/$song/charts/${variant != null ? variant + "/" : ""}$difficulty.json', null);
	}

	public static function character(character:String):String {
		return getPath('data/characters/$character.xml', null);
	}

	inline static public function getFontName(font:String) {
		return OpenFlAssets.exists(font, FONT) ? OpenFlAssets.getFont(font).fontName : font;
	}

	public static inline function font(key:String) {
		return getPath('fonts/$key');
	}

	public static inline function obj(key:String) {
		return getPath('models/$key.obj');
	}

	public static inline function dae(key:String) {
		return getPath('models/$key.dae');
	}

	public static inline function md2(key:String) {
		return getPath('models/$key.md2');
	}

	public static inline function md5(key:String) {
		return getPath('models/$key.md5');
	}

	public static inline function awd(key:String) {
		return getPath('models/$key.awd');
	}

	inline static public function getSparrowAtlas(key:String, ?library:String, ?ext:String)
		return FlxAtlasFrames.fromSparrow(image(key, library, ext), file('images/$key.xml', library));

	inline static public function getAnimateAtlasAlt(key:String, ?settings:FlxAnimateSettings)
		return FlxAnimateFrames.fromAnimate(key, null, null, null, false, settings);

	inline static public function getSparrowAtlasAlt(key:String, ?ext:String)
		return FlxAtlasFrames.fromSparrow('$key.${ext != null ? ext : Flags.IMAGE_EXT}', '$key.xml');

	inline static public function getPackerAtlas(key:String, ?library:String, ?ext:String)
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, ext), file('images/$key.txt', library));

	inline static public function getPackerAtlasAlt(key:String, ?ext:String)
		return FlxAtlasFrames.fromSpriteSheetPacker('$key.${ext != null ? ext : Flags.IMAGE_EXT}', '$key.txt');

	inline static public function getAsepriteAtlas(key:String, ?library:String, ?ext:String)
		return FlxAtlasFrames.fromAseprite(image(key, library, ext), file('images/$key.json', library));

	inline static public function getAsepriteAtlasAlt(key:String, ?ext:String)
		return FlxAtlasFrames.fromAseprite('$key.${ext != null ? ext : Flags.IMAGE_EXT}', '$key.json');

	inline static public function getAssetsRoot():String {
        #if android

        if (ModsFolder.currentModFolder != null) {
            // Hardcoded path requested by user
            var basePath:String = "/storage/emulated/0/.CodenameEngine-v1.0.1";
            return Path.normalize(basePath + "/mods/" + ModsFolder.currentModFolder);
        }

        var dataPath:String = Path.normalize(lime.system.System.applicationStorageDirectory);

        if (!dataPath.endsWith("files"))
            dataPath += "/files";

        return Path.normalize(dataPath + "/assets");

        #else

        if (ModsFolder.currentModFolder != null)
            return "./mods/" + ModsFolder.currentModFolder;

        return #if (sys && TEST_BUILD)
            "./" + Main.pathBack + "assets/"
        #else
            "./assets"
        #end;

        #end
	}

	public static function getFrames(key:String, assetsPath:Bool = false, ?library:String, ?ext:String = null, ?animateSettings:FlxAnimateSettings) {
		var path = assetsPath ? key : Paths.image(key, library, true, ext);

		#if sys
		if (tempFramesCache.exists(key) || FlxG.bitmap.checkCache(path)) {
			var noExt = Path.withoutExtension(path);
			if (checkFileChanged(path) || checkFileChanged(noExt + ".xml") || checkFileChanged(noExt + ".json")) {
				tempFramesCache.remove(key);
				
				if (FlxG.bitmap.checkCache(path)) {
					var graphicToClear = FlxG.bitmap.get(path);
					FlxG.bitmap.remove(graphicToClear);
				}
				
				@:privateAccess OpenFlAssets.cache.removeBitmapData(path);
			}
		}
		#end

		if (tempFramesCache.exists(key)) {
			var frames = tempFramesCache[key];
			if (frames != null && frames.parent != null && frames.parent.bitmap != null && frames.parent.bitmap.readable)
				return frames;
			else
				tempFramesCache.remove(key);
		}
		
		var loadedFrames = loadFrames(path, false, null, false, false, ext, animateSettings);
		tempFramesCache[key] = loadedFrames;
		return loadedFrames;
	}

	public static function framesExists(key:String, checkAtlas:Bool = false, checkMulti:Bool = true, assetsPath:Bool = false, ?library:String) {
		var path = assetsPath ? key : Paths.image(key, library, true);
		var noExt = Path.withoutExtension(path);
		if(checkAtlas && Assets.exists('$noExt/Animation.json'))
			return true;
		if(checkMulti && Assets.exists('$noExt/1.png'))
			return true;
		if(Assets.exists('$noExt.xml'))
			return true;
		if(Assets.exists('$noExt.txt'))
			return true;
		if(Assets.exists('$noExt.json'))
			return true;
		return false;
	}

	static function loadFrames(path:String, Unique:Bool = false, Key:String = null, SkipAtlasCheck:Bool = false, SkipMultiCheck:Bool = false, ?Ext:String = null, ?animateSettings:FlxAnimateSettings):FlxFramesCollection {
		var noExt = Path.withoutExtension(path);
		var ext = Ext != null ? Ext : Flags.IMAGE_EXT;

		if (!SkipMultiCheck && Assets.exists('$noExt/1.${ext}')) {
			var graphic = FlxG.bitmap.add("flixel/images/logo/default.png", false, '$noExt/mult');
			var frames = MultiFramesCollection.findFrame(graphic);
			if (frames != null)
				return frames;

			var cur = 1;
			var finalFrames = new MultiFramesCollection(graphic);
			while(Assets.exists('$noExt/$cur.${ext}')) {
				var spr = loadFrames('$noExt/$cur.${ext}', false, null, false, true);
				finalFrames.addFrames(spr);
				cur++;
			}
			return finalFrames;
		} else if (Assets.exists('$noExt/Animation.json')) {
			return Paths.getAnimateAtlasAlt(noExt, animateSettings);
		} else if (Assets.exists('$noExt.xml')) {
			return Paths.getSparrowAtlasAlt(noExt, ext);
		} else if (Assets.exists('$noExt.txt')) {
			return Paths.getPackerAtlasAlt(noExt, ext);
		} else if (Assets.exists('$noExt.json')) {
			return Paths.getAsepriteAtlasAlt(noExt, ext);
		}

		var graph:FlxGraphic = FlxG.bitmap.add(path, Unique, Key);
		if (graph == null)
			return null;
		return graph.imageFrame;
	}

	public static function getFolderDirectories(key:String, addPath:Bool = false, source:AssetSource = BOTH):Array<String> {
		if (!key.endsWith("/")) key += "/";
		var content = assetsTree.getFolders('assets/$key', source);
		if (addPath) {
			for(k=>e in content)
				content[k] = '$key$e';
		}
		return content;
	}
	
	static public function getFolderContent(key:String, addPath:Bool = false, source:AssetSource = BOTH, noExtension:Bool = false):Array<String> {
	    if (!key.endsWith("/")) key += "/";

	    var cacheKey = key + ":" + source + ":" + addPath + ":" + noExtension;
    
	    if (folderContentCache.exists(cacheKey)) {
		    return folderContentCache.get(cacheKey);
	    }
  
	    var content = assetsTree.getFiles('assets/$key', source);

	    for (k => e in content) {
	    	if (noExtension) e = Path.withoutExtension(e);
		    content[k] = addPath ? '$key$e' : e;
	}

	folderContentCache.set(cacheKey, content);
	return content;
	}

	@:noCompletion public static function getFilenameFromLibFile(path:String) {
		var file = new haxe.io.Path(path);
		if(file.file.startsWith("LIB_")) {
			return file.dir + "." + file.ext;
		}
		return path;
	}

	@:noCompletion public static function getLibFromLibFile(path:String) {
		var file = new haxe.io.Path(path);
		if(file.file.startsWith("LIB_")) {
			return file.file.substr(4);
		}
		return "";
	}
}

class ScriptPathInfo {
	public var file:String;
	public var library:AssetLibrary;

	public function new(file:String, library:AssetLibrary) {
		this.file = file;
		this.library = library;
	}
}
