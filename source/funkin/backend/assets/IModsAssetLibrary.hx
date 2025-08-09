package funkin.backend.assets;

interface IModsAssetLibrary {
	public var prefix:String;
	public var modName:String;
	public var libName:String;
	public var basePath:String;

	#if MOD_SUPPORT
	public var _parsedAsset:String;

	private function getAssetPath():String;

	private function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocal:Bool = false):Bool;

	private function __parseAsset(asset:String):Bool;

	public function getFiles(folder:String):Array<String>;

	public function getFolders(folder:String):Array<String>;
	#end
}