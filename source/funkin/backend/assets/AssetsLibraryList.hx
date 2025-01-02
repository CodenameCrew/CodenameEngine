package funkin.backend.assets;

import funkin.backend.assets.IModsAssetLibrary;
import lime.utils.AssetLibrary;
import lime.utils.AssetType;

class AssetsLibraryList extends AssetLibrary {
	public var libraries:Array<AssetLibrary> = [];

	@:allow(funkin.backend.system.Main)
	@:allow(funkin.backend.system.MainState)
	private var __defaultLibraries:Array<AssetLibrary> = [];
	public var base:AssetLibrary;

	public function removeLibrary(lib:AssetLibrary) {
		if (lib == null) return lib;
		libraries.remove(lib);
		return lib;
	}
	public function existsSpecific(id:String, type:String, source:AssetSource = BOTH) {
		if (!id.startsWith("assets/") && exists('assets/$id', type))
			return true;
		for(k=>e in libraries) {
			if (shouldSkipLib(k, source)) continue;
			if (e.exists(id, type))
				return true;
		}
		return false;
	}
	public override inline function exists(id:String, type:String):Bool
		return existsSpecific(id, type, BOTH);

	public function getSpecificPath(id:String, source:AssetSource = BOTH) {
		for(k=>e in libraries) {
			if (shouldSkipLib(k, source)) continue;

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
		for(k=>e in libraries) {
			if (shouldSkipLib(k, source)) continue;

			var l = e;

			if (l is openfl.utils.AssetLibrary) {
				@:privateAccess
				l = cast(l, openfl.utils.AssetLibrary).__proxy;
			}

			// TODO: do base folder scanning
			#if MOD_SUPPORT
			if (l is IModsAssetLibrary) {
				var lib = cast(l, IModsAssetLibrary);
				for(e in lib.getFiles(folder))
					content.push(e);
			}
			#end
		}
		return content;
	}

	public function getFolders(folder:String, source:AssetSource = BOTH):Array<String> {
		var content:Array<String> = [];
		for(k=>e in libraries) {
			if (shouldSkipLib(k, source)) continue;

			var l = e;

			if (l is openfl.utils.AssetLibrary) {
				@:privateAccess
				l = cast(l, openfl.utils.AssetLibrary).__proxy;
			}

			// TODO: do base folder scanning
			#if MOD_SUPPORT
			if (l is IModsAssetLibrary) {
				var lib = cast(l, IModsAssetLibrary);
				for(e in lib.getFolders(folder))
					content.push(e);
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
			for(k=>e in libraries) {
				if (shouldSkipLib(k, source)) continue;

				@:privateAccess
				if (e.exists(id, e.types.get(id))) {
					var asset = e.getAsset(id, type);
					if (asset != null) {
						return asset;
					}
				}
			}
			return null;
		} catch(e) {
			throw e;
		}
		return null;
	}

	private function shouldSkipLib(k:Int, source:AssetSource) {
		return switch(source) {
			case BOTH:	  false;
			case SOURCE:	k < libraries.length - __defaultLibraries.length;
			case MODS:	  k >= libraries.length - __defaultLibraries.length;
		};
	}
	public override inline function getAsset(id:String, type:String):Dynamic
		return getSpecificAsset(id, type, BOTH);

	public override function isLocal(id:String, type:String) {
		return true;
	}

	public function new(?base:AssetLibrary) {
		super();
		if (base == null)
			base = Assets.getLibrary("default");
		addLibrary(this.base = base);
		__defaultLibraries.push(base);
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
		for(d in __defaultLibraries)
			addLibrary(d);
	}

	public function addLibrary(lib:AssetLibrary) {
		libraries.insert(0, lib);
		return lib;
	}

	override public function list(type:String):Array<String>
	{
		var items = [];

		for (library in libraries)
		{
			var libraryItems = library.list(type);

			if (libraryItems != null)
			{
				items = items.concat(libraryItems);
			}
		}

		return items;
	}
}

enum abstract AssetSource(Null<Bool>) from Bool from Null<Bool> to Null<Bool> {
	var SOURCE = true;
	var MODS = false;
	var BOTH = null;
}
