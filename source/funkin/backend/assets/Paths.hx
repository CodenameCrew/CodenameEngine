package funkin.backend.assets;

import haxe.io.Path;

import lime.utils.AssetLibrary;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.util.typeLimit.OneOfTwo;

import animate.FlxAnimateFrames;

import funkin.backend.assets.ModsFolder;
import funkin.backend.scripting.Script;

using StringTools;

class Paths
{
	public static var assetsTree:AssetsLibraryList;

	public static var tempFramesCache:Map<String, FlxFramesCollection> = [];

	public static function init() {
		FlxG.signals.preStateSwitch.add(function() {
			tempFramesCache.clear();
		});
	}

	static function getExistingPath(path:String, prefix:String, nullFail:Bool):Null<String> {
		var fixedPath = prefix + path;

		#if (sys && !windows)
		if (Assets.exists(fixedPath)) return fixedPath;
		else if (Flags.PATHS_UNIX_FIX) {
			final isFile = path.lastIndexOf(".") != -1, parts = path.split("/");
			final n = parts.length - 1;

			fixedPath = prefix;
			for (i => part in parts) {
				final partIsFile = isFile && i == n;
				final lower = part.toLowerCase(), entries = partIsFile ? assetsTree.getFiles(fixedPath) : assetsTree.getFolders(fixedPath);
				var pass = false;

				for (entry in entries) if (entry.toLowerCase() == lower) {
					pass = true;
					if (partIsFile) fixedPath += entry;
					else fixedPath += entry + "/";
					break;
				}

				if (!pass) {
					if (nullFail) return null;
					else fixedPath += part;
				}
			}

			return fixedPath;
		}
		else if (!nullFail) return fixedPath;
		#else
		if (!nullFail || Assets.exists(fixedPath)) return fixedPath;
		#end

		return null;
	}

	public static function getPath(file:String, ?library:String, ?exts:OneOfTwo<String, Array<String>>) {
		if (exts == null)
			return library == null ? getExistingPath(file, 'assets/', false) : getExistingPath('$library/$file', '$library:assets/', false);

		var idx = file.lastIndexOf("/");
		var p:Null<String> = idx == -1 ? "" : file.substr(0, idx);
		file = file.substr(idx + 1);

		final e:Array<String> = (exts is String) ? [exts] : (cast exts);

		idx = file.lastIndexOf(".");
		if (idx != -1) {
			e.unshift(file.substr(idx + 1));
			file = file.substr(0, idx);
		}

		p = library == null ? getExistingPath(p, 'assets/', true) : getExistingPath('$library/$p', '$library:assets/', true);
		if (p == null) return library == null ? 'assets/$file.${e[0]}' : '$library:assets/$library/$file.${e[0]}';
		else p += "/";

		for (extension in e) {
			final path = getExistingPath('$file.$extension', p, true);
			if (path != null) return path;
		}

		return '$p$file.${e[0]}';
	}

	public static inline function video(key:String, ?ext:OneOfTwo<String, Array<String>>)
		return getPath('videos/$key', null, ext != null ? ext : Flags.VIDEO_EXTS);

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

	static public function sound(key:String, ?library:String, ?ext:OneOfTwo<String, Array<String>>)
		return getPath('sounds/$key', library, ext != null ? ext : Flags.SOUND_EXTS);

	public static inline function soundRandom(key:String, min:Int, max:Int, ?library:String)
		return sound(key + FlxG.random.int(min, max), library);

	inline static public function music(key:String, ?library:String, ?ext:OneOfTwo<String, Array<String>>)
		return getPath('music/$key', library, ext != null ? ext : Flags.SOUND_EXTS);

	inline static public function voices(song:String, ?difficulty:String, ?suffix:String = "", ?ext:OneOfTwo<String, Array<String>>) {
		if (difficulty == null) difficulty = Flags.DEFAULT_DIFFICULTY;
		var diff = getPath('songs/$song/song/Voices$suffix-${difficulty}', null, ext != null ? ext : Flags.SOUND_EXTS);
		return Assets.exists(diff) ? diff : getPath('songs/$song/song/Voices$suffix', null, ext != null ? ext : Flags.SOUND_EXTS);
	}

	inline static public function inst(song:String, ?difficulty:String, ?suffix:String = "", ?ext:OneOfTwo<String, Array<String>>) {
		if (difficulty == null) difficulty = Flags.DEFAULT_DIFFICULTY;
		var diff = getPath('songs/$song/song/Inst$suffix-${difficulty}', null, ext != null ? ext : Flags.SOUND_EXTS);
		return Assets.exists(diff) ? diff : getPath('songs/$song/song/Inst$suffix', null, ext != null ? ext : Flags.SOUND_EXTS);
	}

	static public function image(key:String, ?library:String, checkForAtlas:Bool = true, ?ext:OneOfTwo<String, Array<String>>) {
		if (checkForAtlas) {
			var atlasPath = getPath('images/$key/spritemap1', library, ext != null ? ext : Flags.IMAGE_EXTS);
			var multiplePath = getPath('images/$key/1', library, ext != null ? ext : Flags.IMAGE_EXTS);
			if (atlasPath != null && Assets.exists(atlasPath)) return atlasPath.substr(0, atlasPath.length - 14);
			if (multiplePath != null && Assets.exists(multiplePath)) return multiplePath;
		}
		return getPath('images/$key', library, ext != null ? ext : Flags.IMAGE_EXTS);
	}

	public static inline function script(key:String, ?library:String, isAssetsPath:Bool = false) {
		var scriptPath = isAssetsPath ? key : getPath(key, library);
		if (!Assets.exists(scriptPath)) {
			var p:String;
			for(ex in Script.scriptExtensions) {
				if (Assets.exists(p = scriptPath + '.' + ex)) {
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

	/**
	 * Gets the name of a registered font.
	 * @param font The font's path (if it's already passed as a font name, the same name will be returned)
	 */
	inline static public function getFontName(font:String) {
		return Assets.exists(font, FONT) ? Assets.getFont(font).fontName : font;
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

	inline static public function getSparrowAtlas(key:String, ?library:String, ?ext:OneOfTwo<String, Array<String>>)
		return FlxAtlasFrames.fromSparrow(image(key, library, ext), file('images/$key.xml', library));

	inline static public function getAnimateAtlasAlt(key:String, ?settings:FlxAnimateSettings)
		return FlxAnimateFrames.fromAnimate(key, null, null, null, false, settings);

	inline static public function getSparrowAtlasAlt(key:String, ?ext:OneOfTwo<String, Array<String>>)
		return FlxAtlasFrames.fromSparrow('$key.${ext != null ? ext : Flags.IMAGE_EXTS}', '$key.xml');

	inline static public function getPackerAtlas(key:String, ?library:String, ?ext:OneOfTwo<String, Array<String>>)
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, ext), file('images/$key.txt', library));

	inline static public function getPackerAtlasAlt(key:String, ?ext:OneOfTwo<String, Array<String>>)
		return FlxAtlasFrames.fromSpriteSheetPacker('$key.${ext != null ? ext : Flags.IMAGE_EXTS}', '$key.txt');

	inline static public function getAsepriteAtlas(key:String, ?library:String, ?ext:OneOfTwo<String, Array<String>>)
		return FlxAtlasFrames.fromAseprite(image(key, library, ext), file('images/$key.json', library));

	inline static public function getAsepriteAtlasAlt(key:String, ?ext:OneOfTwo<String, Array<String>>)
		return FlxAtlasFrames.fromAseprite('$key.${ext != null ? ext : Flags.IMAGE_EXTS}', '$key.json');

	static public function getAssetsRoot():String {
		return if (ModsFolder.currentModFolder != null) '${ModsFolder.modsPath}${ModsFolder.currentModFolder}';
			else assetsTree.rootDirectory;
	}

	/**
	 * Gets frames at specified path.
	 * @param key Path to the frames
	 * @param library (Additional) library to load the frames from.
	 */
	public static function getFrames(key:String, assetsPath:Bool = false, ?library:String, ?ext:OneOfTwo<String, Array<String>> = null, ?animateSettings:FlxAnimateSettings) {
		if (tempFramesCache.exists(key)) {
			var frames = tempFramesCache[key];
			if (frames != null && frames.parent != null && frames.parent.bitmap != null && frames.parent.bitmap.readable)
				return frames;
			else
				tempFramesCache.remove(key);
		}
		return tempFramesCache[key] = loadFrames(assetsPath ? key : Paths.image(key, library, true, ext), false, null, false, animateSettings);
	}

	/**
	 * Checks if the images needed for using getFrames() exist.
	 * @param key Path to the image
	 * @param checkAtlas Whenever to check for the Animation.json file (used in FlxAnimate)
	 * @param assetsPath Whenever to use the raw path or to pass it through Paths.image()
	 * @param library (Additional) library to load the frames from.
	 * @return True if the images exist, false otherwise.
	**/
	public static function framesExists(key:String, checkAtlas:Bool = false, checkMulti:Bool = true, assetsPath:Bool = false, ?library:String) {
		var path = assetsPath ? key : Paths.image(key, library, true);
		var noExt = Path.withoutExtension(path);
		var ext = Path.extension(path);
		if(checkAtlas && Assets.exists('$noExt/Animation.json'))
			return true;
		if(checkMulti && Assets.exists('$noExt/1.$ext'))
			return true;
		if(Assets.exists('$noExt.xml'))
			return true;
		if(Assets.exists('$noExt.txt'))
			return true;
		if(Assets.exists('$noExt.json'))
			return true;
		return false;
	}

	/*
	 * Loads frames from multiple specified image paths. Supports all atlas types.
	 * @param sheets An array of paths to the images
	 * @param unique (Additional) Whenever the image should be unique in the cache
	 * @param key (Additional) Key to the image in the cache
	 * @param ext (Additional) Extension of the images.
	 * @return FlxFramesCollection Frames
	 */
	public static function getMultiFrames(sheets:Array<String>, ?unique:Bool = true, ?key:String = null, ?skipMulti:Bool = false, ?ext:OneOfTwo<String, Array<String>> = null, ?animateSettings:FlxAnimateSettings):FlxFramesCollection {
		if (sheets.length == 1)
			return loadFrames(Paths.image(sheets[0], null, true, ext), unique, key, false, false, animateSettings);
		if (key == null) key = 'combo/' + sheets.join(',');

		var graphic = FlxG.bitmap.add("flixel/images/logo/default.png", unique, key);
		var sprFrames:FlxAtlasFrames = new FlxAtlasFrames(graphic);
		try {
			for (x => path in sheets) {
				final coolPath = Paths.image(path, null, true, ext);
				final noExt = haxe.io.Path.withoutExtension(coolPath);
				final ext = haxe.io.Path.extension(coolPath);
				@:privateAccess
				var newFrames = cast Paths.loadFrames('$noExt.$ext', true, key + '_$path', false, skipMulti, animateSettings);
				if (newFrames == null) {
					Logs.warn('There is no Bitmap asset for "$noExt". Skipping...');
					continue;
				}
				sprFrames = FlxAnimateFrames.combineAtlas(sprFrames, newFrames);
			}
		} catch(e:Dynamic) {
			Logs.error('Multisheet load error: ' + e.toString());
		}
		return sprFrames;
	}
	
	/**
	 * Loads frames from a specific image path. Supports Sparrow Atlases, Packer Atlases, and multiple spritesheets.
	 * @param path Path to the image
	 * @param Unique Whenever the image should be unique in the cache
	 * @param Key Key to the image in the cache
	 * @param SkipAtlasCheck Whenever the atlas check should be skipped.
	 * @param SkipMultiCheck Whenever the multi spritesheet check should be skipped.
	 * @param Ext Extension of the image.
	 * @return FlxFramesCollection Frames
	 */
	static function loadFrames(path:String, Unique:Bool = false, Key:String = null, SkipAtlasCheck:Bool = false, SkipMultiCheck:Bool = false, ?animateSettings:FlxAnimateSettings):FlxFramesCollection {
		var noExt = Path.withoutExtension(path);
		var ext = Path.extension(path);
		// there NEEDS to be a better way dude
		if (!SkipMultiCheck && noExt.endsWith('/1'))
			noExt = noExt.substr(0, noExt.length - 2);
		if (!SkipMultiCheck && Assets.exists('$noExt/1.${ext}')) {
			var cur:Int = 1;
			final finalFrames = [];
			while (Assets.exists('$noExt/$cur.${ext}')) {
				finalFrames.push('${noExt.substr(
					// there should be a Paths.unimage tbh
					'assets/images/'.length
				)}/$cur');
				cur++;
			}
			return getMultiFrames(finalFrames, true,
				'$noExt/mult', true, ext, animateSettings);
		} else if (!SkipAtlasCheck && Assets.exists('$noExt/Animation.json')) {
			// ???
			if (noExt.endsWith('/')) noExt = noExt.substr(0, noExt.length - 1);
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
		// designed to work both on windows and web
		if (!key.endsWith("/")) key += "/";
		var content = assetsTree.getFiles('assets/$key', source);
		for (k => e in content) {
			if (noExtension) e = Path.withoutExtension(e);
			content[k] = addPath ? '$key$e' : e;
		}
		return content;
	}

	// Used in Script.hx
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
