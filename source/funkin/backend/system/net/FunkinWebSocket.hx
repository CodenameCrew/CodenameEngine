package funkin.backend.system.net;

import haxe.io.Bytes;
import haxe.io.BytesOutput;

import flixel.util.FlxSignal.FlxTypedSignal;
import hx.ws.WebSocket;
import hx.ws.Log as LogWs;

class FunkinWebSocket implements IFlxDestroyable {
	private static var LOG_INFO(default, set):Bool = false;
	private static function set_LOG_INFO(value:Bool):Bool {
		LOG_INFO = value;
		if (LOG_INFO) LogWs.mask |= LogWs.INFO;
		else LogWs.mask &= ~LogWs.INFO;
		return value;
	}
	private static var LOG_DEBUG(default, set):Bool = false;
	private static function set_LOG_DEBUG(value:Bool):Bool {
		LOG_DEBUG = value;
		if (LOG_DEBUG) LogWs.mask |= LogWs.DEBUG;
		else LogWs.mask &= ~LogWs.DEBUG;
		return value;
	}
	private static var LOG_DATA(default, set):Bool = false;
	private static function set_LOG_DATA(value:Bool):Bool {
		LOG_DATA = value;
		if (LOG_DATA) LogWs.mask |= LogWs.DATA;
		else LogWs.mask &= ~LogWs.DATA;
		return value;
	}
	
	private var _ws:WebSocket;

	public var onOpen:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
	public var onMessage:FlxTypedSignal<Dynamic->Void> = new FlxTypedSignal<Dynamic->Void>();
	public var onClose:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
	public var onError:FlxTypedSignal<Dynamic->Void> = new FlxTypedSignal<Dynamic->Void>();

	public var url:String;
	public function new(_url:String) {
		this.url = _url;
		this._ws = new WebSocket(this.url, false);
		this._ws.onopen = () -> onOpen.dispatch();
		this._ws.onmessage = (message) -> onMessage.dispatch(message);
		this._ws.onclose = () -> onClose.dispatch();
		this._ws.onerror = (error) -> onError.dispatch(error);
	}

	public function open():FunkinWebSocket {
		Logs.traceColored([
			Logs.logText('[FunkinWebSocket] ', CYAN),
			Logs.logText('Opening WebSocket to ', NONE), Logs.logText(url, YELLOW),
		]);
		_ws.open();
		return this;
	}

	public function send(data:Dynamic):Bool {
		try {
			this._ws.send(data);
		} catch(e) {
			Logs.traceColored([
				Logs.logText('[FunkinWebSocket] ', CYAN),
				Logs.logText('Failed to send data: ${e}', NONE),
			]);
		}
		return false;
	}

	public function close():Void {
		Logs.traceColored([
			Logs.logText('[FunkinWebSocket] ', CYAN),
			Logs.logText('Closing WebSocket from ', NONE), Logs.logText(url, YELLOW),
		]);
		_ws.close();
	}
	public function destroy():Void { close(); }
}

class HeaderWs {
	public var head:String;
	public var fields:Map<String, String> = new Map<String, String>();
	public var content:String;

	public function new(_head:String, ?_content:String = "") {
		this.head = _head;
		this.content = _content;
	}

	public function set(name:String, value:String):HeaderWs {
		fields.set(name, value);
		return this;
	}
	inline public function get(name:String):String { return fields.get(name); }
	inline public function exists(name:String):Bool { return fields.exists(name); }
	inline public function remove(name:String):Bool { return fields.remove(name); }
	inline public function keys():Iterator<String> { return fields.keys(); }

	public function toBytes():Bytes {
		var bytes:BytesOutput = new BytesOutput();
		if (head.length > 0) bytes.writeString('$head\r\n');
		for (key in keys()) bytes.writeString('$key: ${get(key)}\r\n');
		bytes.writeString('\r\n');
		if (content.length > 0) bytes.writeString('$content\r\n');
		return bytes.getBytes();
	}
	public function toString():String { return toBytes().toString(); }
}