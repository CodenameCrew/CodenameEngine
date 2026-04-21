package funkin.backend.system.net;

import flixel.util.typeLimit.OneOfTwo;

import haxe.io.Bytes;
import haxe.io.BytesOutput;

class FunkinPacket implements haxe.Constraints.IMap<String, Dynamic> {
	public var status:Int = -1;
	private var fields:Map<String, Dynamic> = [];

	public function new() { }

	public static function fromJson(json:OneOfTwo<String, haxe.DynamicAccess<Dynamic>>):Null<FunkinPacket> {		
		var packet = new FunkinPacket();
		packet.appendJson(json);
		return packet;
	}

	public function appendJson(json:OneOfTwo<String, haxe.DynamicAccess<Dynamic>>):Void {
		var parsedJson:haxe.DynamicAccess<Dynamic> = (json is String) ? haxe.Json.parse(json) : json;
		if (parsedJson == null) return;
		
		for (key => value in parsedJson) this.set(key, value);
	}

	public function toJson():haxe.DynamicAccess<Dynamic> {
		var json:haxe.DynamicAccess<Dynamic> = {};
		for (key => value in fields) json[key] = value;
		return json;
	}

	inline public function stringify():String { return haxe.Json.stringify(toJson()); }

	public function toBytes():Bytes {
		var output = new BytesOutput();
		output.writeString(haxe.Json.stringify(toJson()));
		return output.getBytes();
	}

	inline public function get(key:String):Null<Dynamic> { return fields.get(key); }
	inline public function set(key:String, value:Dynamic):Void { fields.set(key, value); }
	inline public function exists(key:String):Bool { return fields.exists(key); }
	inline public function remove(key:String):Bool { return fields.remove(key); }

	inline public function keys():Iterator<String> { return fields.keys(); }
	inline public function iterator():Iterator<Dynamic> { return fields.iterator(); }
	inline public function keyValueIterator():KeyValueIterator<String, Dynamic> { return fields.keyValueIterator(); }

	public function copy():FunkinPacket { 
		var copy = new FunkinPacket();
		for (key => value in fields) copy.set(key, value);
		copy.status = this.status;
		return copy;
	}

	inline public function clear():Void { fields.clear(); }
	inline public function toString():String { return 'FunkinPacket (Status: $status)'; }
}