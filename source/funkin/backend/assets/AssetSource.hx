package funkin.backend.assets;

enum abstract AssetSource(Null<Int>)/* from Null<Bool>*/ from Null<Int> to Null<Int> {
	var SOURCE = 0;
	var MODS = 1;
	var BOTH = -1;

	@:from public static function fromString(str:String):AssetSource
	{
		return switch (StringTools.trim(str).toLowerCase())
		{
			case "source": SOURCE;
			case "mods": MODS;
			case "both": BOTH;
			default: MODS;
		}
	}

	/*@:from public static function fromBool(b:Null<Bool>):AssetSource
	{
		return switch (b)
		{
			case true: SOURCE;
			case false: MODS;
			case null: BOTH;
			default: MODS;
		}
	}*/

	@:to public inline function toString():String
	{
		return switch (this)
		{
			case SOURCE: "source";
			case MODS: "mods";
			case BOTH: "both";
			default: "mods";
		}
	}
}