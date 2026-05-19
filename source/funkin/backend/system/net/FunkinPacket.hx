package funkin.backend.system.net;

import flixel.util.typeLimit.OneOfTwo;

import haxe.io.Bytes;
import haxe.io.BytesOutput;

class FunkinPacket implements haxe.Constraints.IMap<String, Dynamic> {
	// Status of the packet. 200 is an OK response.
	public var status:Int = -1;

	// The JSON fields of the packet, as a Map.
	private var fields:Map<String, Dynamic> = [];

	// If the recieved data is binary or contains binary, this will contain the raw bytes.
	public var bytes:Bytes = null;

	public function new() {}

	public static function fromJson(json:OneOfTwo<String, haxe.DynamicAccess<Dynamic>>):FunkinPacket { return (new FunkinPacket().appendJson(json)); }

	public function appendJson(json:OneOfTwo<String, haxe.DynamicAccess<Dynamic>>):FunkinPacket {
		var parsedJson:haxe.DynamicAccess<Dynamic> = (json is String) ? haxe.Json.parse(json) : json;
		if (parsedJson == null) return this;
		
		for (key => value in parsedJson) this.set(key, value);
		return this;
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
		copy.fields = this.fields.copy();
		copy.status = this.status;
		return copy;
	}

	inline public function clear():Void { fields.clear(); }
	inline public function toString():String { return 'FunkinPacket (Status: $status)'; }
}