package funkin.backend.assets;

#if TRANSLATIONS_SUPPORT
import funkin.backend.assets.TranslatedAssetLibrary;
#end
import funkin.backend.assets.IModsAssetLibrary;
import lime.utils.AssetLibrary;

class AssetsLibraryList extends AssetLibrary {
	public var libraries:Array<AssetLibrary> = [];

	@:allow(funkin.backend.system.Main)
	@:allow(funkin.backend.system.MainState)
	private var __defaultLibraries:Array<AssetLibrary> = [];
	public var base:AssetLibrary;

	#if TRANSLATIONS_SUPPORT
	public var transLib:TranslatedAssetLibrary;
	#end

	public function removeLibrary(lib:AssetLibrary) {
		if (lib != null) {
			libraries.remove(lib);
			#if TRANSLATIONS_SUPPORT
			// TODO: improve this code
			for(k=>l in libraries) {
				if(l == null) continue;
				if(l is TranslatedAssetLibrary) {
					var tlib = cast(l, TranslatedAssetLibrary);
					var lib:Dynamic = lib;
					if(tlib.forLibrary == lib) {
						libraries.remove(tlib);
						break;
					}
				}
			}
			#end
		}
		return lib;
	}
	public function existsSpecific(id:String, type:String, source:AssetSource = BOTH) {
		if (!id.startsWith("assets/") && existsSpecific('assets/$id', type, source))
			return true;
		for(k=>l in libraries) {
			if (shouldSkipLib(l, source)) continue;
			if (l.exists(id, type)) {
				return true;
			}
		}
		return false;
	}
	public override inline function exists(id:String, type:String):Bool
		return existsSpecific(id, type, BOTH);

	public function getSpecificPath(id:String, source:AssetSource = BOTH) {
		for(k=>e in libraries) {
			if (shouldSkipLib(e, source)) continue;

			@:privateAccess
			if (e.exists(id, e.types.get(id))) {
				var path = e.getPath(id);
				if (path != null)
					return path;
			}
		}
		return null;
	}

	public override inline function getPath(id:String)
		return getSpecificPath(id, BOTH);

	public function getFiles(folder:String, source:AssetSource = BOTH):Array<String> {
		var content:Array<String> = [];
		for(k=>l in libraries) {
			if (shouldSkipLib(l, source)) continue;

			l = getCleanLibrary(l);

			// TODO: do base folder scanning
			#if MOD_SUPPORT
			if (l is IModsAssetLibrary) {
				var lib = cast(l, IModsAssetLibrary);
				for(e in lib.getFiles(folder))
					content.pushOnce(e);
			}
			#end
		}
		return content;
	}

	public function getFolders(folder:String, source:AssetSource = BOTH):Array<String> {
		var content:Array<String> = [];
		for(k=>l in libraries) {
			if (shouldSkipLib(l, source)) continue;

			l = getCleanLibrary(l);

			// TODO: do base folder scanning
			#if MOD_SUPPORT
			if (l is IModsAssetLibrary) {
				var lib = cast(l, IModsAssetLibrary);
				for(e in lib.getFolders(folder))
					content.pushOnce(e);
			}
			#end
		}
		return content;
	}

	public function getSpecificAsset(id:String, type:String, source:AssetSource = BOTH):Dynamic {
		try {
			if (!id.startsWith("assets/")) {
				var ass = getSpecificAsset('assets/$id', type, source);
				if (ass != null) {
					return ass;
				}
			}
			for(k=>l in libraries) {
				if (shouldSkipLib(l, source)) continue;

				@:privateAccess
				if (l.exists(id, l.types.get(id))) {
					var asset = l.getAsset(id, type);
					if (asset != null) {
						return asset;
					}
				}
			}
			return null;
		} catch(e) {
			// TODO: trace the error
			throw e;
		}
		return null;
	}

	private function shouldSkipLib(lib:AssetLibrary, source:AssetSource) {
		if (source == BOTH || lib.tag == BOTH) return false;
		return source != lib.tag;
	}
	public override inline function getAsset(id:String, type:String):Dynamic
		return getSpecificAsset(id, type, BOTH);

	public override function isLocal(id:String, type:String) {
		return true;
	}

	public function new(?base:AssetLibrary) {
		super();
		if (base == null) (this.base = Assets.getLibrary("default")).tag = SOURCE;
		else this.base = base;
		__defaultLibraries.push(this.base);

		#if (sys && TEST_BUILD)
		Logs.infos("Used cne test / cne build. Switching into source assets.");

		#if MOD_SUPPORT
		ModsFolder.modsPath = './${Main.pathBack}mods/';
		ModsFolder.addonsPath = './${Main.pathBack}addons/';
		#end

		__defaultLibraries.push(ModsFolder.loadLibraryFromFolder('assets', './${Main.pathBack}assets/', true, SOURCE));
		#elseif USE_ADAPTED_ASSETS
		__defaultLibraries.push(ModsFolder.loadLibraryFromFolder('assets', './assets/', true, SOURCE));
		#end
		for (d in __defaultLibraries) addLibrary(d);
	}

	public function unloadLibraries() {
		for(l in libraries)
			if (!__defaultLibraries.contains(l))
				l.unload();
	}

	public function reset() {
		unloadLibraries();

		libraries = [];

		// adds default libraries in again
		for (d in __defaultLibraries) addLibrary(d);
	}

	public function addLibrary(lib:AssetLibrary, ?tag:AssetSource, ?addTransLib:Bool = true) {
		libraries.insert(0, lib);
		if (tag != null) lib.tag = tag;
		else if (lib.tag == null) lib.tag = MODS;
		#if TRANSLATIONS_SUPPORT
		if(addTransLib) {
			var cleanLib = getCleanLibrary(lib);
			if(cleanLib != null && (cleanLib is IModsAssetLibrary)) {
				var transLib = new TranslatedAssetLibrary(cast(cleanLib, IModsAssetLibrary));
				transLib.tag = cleanLib.tag;
				libraries.insert(0, transLib);
			}
		}
		#end
		return lib;
	}

	public static function getCleanLibrary(e:AssetLibrary):AssetLibrary {
		var l = e;
		if (l is openfl.utils.AssetLibrary) {
			var al = cast(l, openfl.utils.AssetLibrary);
			@:privateAccess
			if (al.__proxy != null) l = al.__proxy;
		}
		return l;
	}
}