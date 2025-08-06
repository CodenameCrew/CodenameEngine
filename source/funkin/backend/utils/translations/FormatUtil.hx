package funkin.backend.utils.translations;

/**
 * The class used to format strings based on parameters.
 *
 * For example if the parameter list is just an `Int` which is `9`, `You have been blue balled {0} times` becomes `You have been blue balled 9 times`.
 */
final class FormatUtil {
	private static var cache:Map<String, IFormatInfo> = new Map();
	private static var cacheStr:Map<String, IFormatInfo> = new Map();

	public static function get(id:String):IFormatInfo {
		if (cache.exists(id))
			return cache.get(id);

		var fi:IFormatInfo = ParamFormatInfo.returnOnlyIfValid(id);
		if(fi == null) fi = new StrFormatInfo(id);
		cache.set(id, fi);
		return fi;
	}

	public static function getStr(id:String):IFormatInfo {
		if (cacheStr.exists(id))
			return cacheStr.get(id);

		var fi:IFormatInfo = new StrFormatInfo(id);
		cacheStr.set(id, fi);
		return fi;
	}

	public inline static function clear():Void {
		cache.clear();
		cacheStr.clear();
	}
}

class StrFormatInfo implements IFormatInfo {
	public var string:String;

	public function new(str:String) {
		this.string = str;
	}

	public function format(params:Array<Dynamic>):String {
		return string;
	}

	public function toString():String {
		return "StrFormatInfo(" + string + ")";
	}
}

// TODO: add support for @:({0}==1?(Hello):(World))
class ParamFormatInfo implements IFormatInfo {
	public var strings:Array<String> = [];
	public var indexes:Array<Int> = [];

	public function new(str:String) {
		var i = 0;

		while (i < str.length) {
			var fi = str.indexOf("{", i); // search from the start of i

			if (fi == -1) {
				// if there are no more parameters, just add the rest of the string
				this.strings.push(str.substring(i));
				break;
			}

			var fe = str.indexOf("}", fi);

			this.strings.push(str.substring(i, fi));
			this.indexes.push(Std.parseInt(str.substring(fi+1, fe)));
			i = fe + 1;
		}
	}

	public static function isValid(str:String):Bool {
		var fi = new ParamFormatInfo(str);
		return fi.indexes.length > 0;
	}
	public static function returnOnlyIfValid(str:String):IFormatInfo {
		var fi = new ParamFormatInfo(str);
		return fi.indexes.length > 0 ? fi : null;
	}

	public function format(params:Array<Dynamic>):String {
		if (params == null) params = [];

		var lenStr = strings.length;
		var lenInd = indexes.length;

		var arr = new haxe.ds.Vector<String>(lenStr + ((lenStr < lenInd) ? lenStr : lenInd));
		var i = 0;
		for (idx=>s in strings) {
			arr[i++] = s;
			if (idx < lenInd)
				arr[i++] = Std.string(params[indexes[idx]]);
		}
		return arr.join("");
	}

	public function toString():String {
		return 'ParamFormatInfo([${strings.join(", ")}] [${indexes.join(", ")}])';
	}
}

interface IFormatInfo {
	public function format(params:Array<Dynamic>):String;
}