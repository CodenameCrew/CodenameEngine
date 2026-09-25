package funkin.backend.assets;

#if TRANSLATIONS_SUPPORT
import funkin.backend.assets.TranslatedAssetLibrary;
#end
import funkin.backend.assets.IModsAssetLibrary;
import funkin.backend.assets.AssetSource;
import lime.utils.AssetLibrary;
import haxe.ds.Map;

class AssetsLibraryList extends AssetLibrary {
	public var libraries:Array<AssetLibrary> = [];
	public var cleanLibraries(get, never):Array<AssetLibrary>;
	function get_cleanLibraries():Array<AssetLibrary> {
		return [for (l in libraries) getCleanLibrary(l)];
	}

	public var rootDirectory:String = "./assets";
	
	// is true if any library in `libraries` contains some kind of compressed library. 
	public var hasCompressedLibrary(get, never):Bool;
	function get_hasCompressedLibrary():Bool {
		for (l in libraries) if (getCleanLibrary(l).isCompressed) return true;
		return false;
	}

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

	var assetPathCacheLibrary:Map<AssetSource, Map<Null<String>, Map<String, AssetLibrary>>> = [];
	var assetPathCacheTime:Map<AssetSource, Map<Null<String>, Map<String, Float>>> = [];

	private function shouldSkipLib(lib:AssetLibrary, source:AssetSource) {
		if (source == BOTH || lib.tag == BOTH) return false;
		return source != lib.tag;
	}

	public function getAssetPathLibrary(id:String, type:Null<String>, source:AssetSource = BOTH):Null<AssetLibrary> {
		var cacheLibraryPaths:Map<String, AssetLibrary> = null;
		if (Flags.PATHS_CACHE_LIFETIME != 0) {
			// Prevent massive lags on repetitive usage, primarily with getting note sprite sheets in mania charts (usually 2k+ notes)
			final time = haxe.Timer.stamp();

			var cacheLibraryTypes = assetPathCacheLibrary.get(source), cacheTimeTypes = assetPathCacheTime.get(source);
			if (cacheLibraryTypes == null) {
				assetPathCacheLibrary.set(source, cacheLibraryTypes = []);
				assetPathCacheTime.set(source, cacheTimeTypes = []);
			}

			cacheLibraryPaths = cacheLibraryTypes.get(type);
			var cacheTimePaths = cacheTimeTypes.get(type);
			if (cacheLibraryPaths == null) {
				cacheLibraryTypes.set(type, cacheLibraryPaths = []);
				cacheTimeTypes.set(type, cacheTimePaths = []);
			}

			if (cacheTimePaths.exists(id)) {
				final library = cacheLibraryPaths.get(id);

				if (Flags.PATHS_CACHE_LIFETIME != null) {
					final cacheSafeTime = cacheTimePaths.get(id) + Flags.PATHS_CACHE_LIFETIME;

					if (library != null) {
						if (time < cacheSafeTime) return library;
						else if (!shouldSkipLib(library, source)
							&& (type == null ? library.exists(id, @:privateAccess library.types.get(id)) : library.exists(id, type))
						) {
							cacheTimePaths.set(id, time);
							return library;
						}

						cacheLibraryPaths.remove(id);
					}
					else if (time < cacheSafeTime) {
						return null;
					}
				}
				else
					return library;
			}

			cacheTimePaths.set(id, time);
		}

		for (library in libraries) {
			if (shouldSkipLib(library, source)) continue;
			if (type == null ? library.exists(id, @:privateAccess library.types.get(id)) : library.exists(id, type)) {
				if (cacheLibraryPaths != null) cacheLibraryPaths.set(id, library);
				return library;
			}
		}

		return null;
	}

	public function existsSpecific(id:String, type:String, source:AssetSource = BOTH)
		return (!id.startsWith("assets/") && existsSpecific('assets/$id', type, source)) || getAssetPathLibrary(id, type, source) != null;

	public override inline function exists(id:String, type:String):Bool
		return existsSpecific(id, type, BOTH);

	public function getSpecificPath(id:String, source:AssetSource = BOTH):Null<String> {
		final library = getAssetPathLibrary(id, null, source);
		if (library != null) {
			final path = library.getPath(id);
			if (path != null) return path;
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
		if (!id.startsWith("assets/")) {
			final asset = getSpecificAsset('assets/$id', type, source);
			if (asset != null) return asset;
		}

		final library = getAssetPathLibrary(id, type, source);
		if (library != null) {
			final asset = library.getAsset(id, type);
			if (asset != null) return asset;
		}

		return null;
	}

	public override inline function getAsset(id:String, type:String):Dynamic
		return getSpecificAsset(id, type, BOTH);

	public override function list(type:String):Array<String> {
		// idk if there's a more efficient way tbh, correct if u find better
		var files:Map<String, Bool> = [];
		for(k=>l in libraries) {
			for(f in l.list(type))
				files.set(f, false);
		}
		return [for(k=>e in files) k];
	}

	public override function isLocal(id:String, type:String) {
		return true;
	}

	public function new(?base:AssetLibrary) {
		super();
		if (base == null) (this.base = Assets.getLibrary("default")).tag = SOURCE;
		else this.base = base;
		__defaultLibraries.push(this.base);

		#if sys

		#if TEST_BUILD
		Logs.infos("Used cne test / cne build. Switching into source assets.");
		switchToSourceAssets();
		#elseif USE_ADAPTED_ASSETS
		if (sys.FileSystem.exists('./${Main.pathBack}assets/') && !sys.FileSystem.exists('./assets/')) {
			Logs.infos("Source assets detected. Switching into source assets.");
			switchToSourceAssets();
		}
		#end

		__defaultLibraries.push(ModsFolder.loadLibraryFromFolder('assets', rootDirectory, true, null, SOURCE));

		#end

		for (d in __defaultLibraries) addLibrary(d);
	}

	#if sys
	inline function switchToSourceAssets() {
		#if MOD_SUPPORT
		ModsFolder.modsPath = './${Main.pathBack}mods/';
		ModsFolder.addonsPath = './${Main.pathBack}addons/';
		#end

		rootDirectory = './${Main.pathBack}assets/';
	}
	#end

	public function unloadLibraries() {
		for(l in libraries)
			if (!__defaultLibraries.contains(l))
				l.unload();
	}

	public function reset() {
		unloadLibraries();
		resetAssetPathCache();

		libraries.resize(0);

		// adds default libraries in again
		for (d in __defaultLibraries) addLibrary(d);
	}

	public function resetAssetPathCache() {
		for (source in [AssetSource.SOURCE, AssetSource.MODS, AssetSource.BOTH]) {
			assetPathCacheLibrary[source]?.clear();
			assetPathCacheTime[source]?.clear();
		}
		assetPathCacheLibrary.clear();
		assetPathCacheTime.clear();
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