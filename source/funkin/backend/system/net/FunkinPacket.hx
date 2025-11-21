package funkin.backend.system.net;

import flixel.util.typeLimit.OneOfTwo;

import haxe.io.Bytes;
import haxe.io.BytesOutput;

class FunkinPacket {
	public var status:Int = -1;
	public var head:String;
	public var fields:Map<String, String> = new Map<String, String>();
	public var body:OneOfTwo<String, Bytes>;

	public function new(_head:String, ?_body:OneOfTwo<String, Bytes> = "", ?_status:Int = -1) {
		this.head = _head.trim();
		this.body = (_body is String) ? _body.trim() : _body;
		this.status = _status;
	}

	public function set(name:String, value:String):FunkinPacket { fields.set(name, value); return this; }
	inline public function get(name:String):String { return fields.get(name); }
	inline public function exists(name:String):Bool { return fields.exists(name); }
	inline public function remove(name:String):Bool { return fields.remove(name); }
	inline public function keys():Iterator<String> { return fields.keys(); }

	public function toString(?includeBody:Bool = true):String {
		var str:String = '';
		if (head.length > 0) str += '$head\r\n';
		for (key in keys()) str += '$key: ${get(key)}\r\n';
		if (!includeBody) return str;
		if (body is String) str += body;
		else str += (cast body : Bytes).toString();
		return str;
	}
	public function toBytes():Bytes {
		var bytes:BytesOutput = new BytesOutput();
		bytes.writeString(toString(false)); // Absolute Cinema, thanks AbstractAndrew for the Revolutionary Idea 🔥🔥
		if (body is String) bytes.writeString(body);
		else if (body is Bytes) bytes.write(body);
		return bytes.getBytes();
	}

	public static function fromBytes(bytes:Bytes):Null<FunkinPacket> {
		var status:Int = -1;

		var header_length:Int = -1;
		var header:String = "";

		var body_is_string:Bool = false;
		var body_length:Int = -1;
		var body:OneOfTwo<String, Bytes> = null;

		try {
			var offset:Int = 0;
			status = bytes.getInt32(0); offset += 4;
			header_length = bytes.getInt32(offset); offset += 4;
			header = bytes.getString(offset, header_length); offset += header_length;
			body_is_string = (bytes.get(offset) == 1); offset += 1;
			body_length = bytes.getInt32(offset); offset += 4;
			if (body_is_string) body = bytes.getString(offset, body_length);
			else body = bytes.sub(offset, body_length);
		} catch(e) {
			FlxG.log.error('FunkinPacket.fromBytes() failed to parse packet: $e');
			return null;
		}
		var packet:FunkinPacket = new FunkinPacket(null, body, status);
		for (line in header.split("\r\n")) {
			var data = line.split(": ");
			if (data.length < 2) continue;
			var key:String = data.shift().trim();
			var value:String = data.shift().trim();
			packet.set(key, value);
		}
		return packet;
	}
}