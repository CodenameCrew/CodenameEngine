package funkin.backend.system.net;

import flixel.util.typeLimit.OneOfThree;

import haxe.io.Bytes;

import flixel.util.FlxSignal.FlxTypedSignal;
import hx.ws.Log as LogWs;
import hx.ws.WebSocket;
import hx.ws.Types.MessageType;

/**
* This is a wrapper for hxWebSockets. Used in-tangem with `FunkinPacket` and `Metrics`.
* You can override how `haxe.io.Bytes` is decoded by setting `AUTO_DECODE_PACKETS`. By default it will attempt to deserialize the packet into a `FunkinPacket`.
* It also has `Metrics` which keeps track of the amount of bytes sent and received.
**/
class FunkinWebSocket implements IFlxDestroyable {
	/**
	* This interacts with the hxWebSockets logging system, probably the best way to get the debug info.
	* Although, it's not in the format of CodenameEngine's logs so it might look weird.
	**/
	private static var LOG_INFO(default, set):Bool = false;
	private static function set_LOG_INFO(value:Bool):Bool {
		LOG_INFO = value;
		if (LOG_INFO) LogWs.mask |= LogWs.INFO;
		else LogWs.mask &= ~LogWs.INFO;
		return value;
	}
	/**
	* Ditto to LOG_INFO
	**/
	private static var LOG_DEBUG(default, set):Bool = false;
	private static function set_LOG_DEBUG(value:Bool):Bool {
		LOG_DEBUG = value;
		if (LOG_DEBUG) LogWs.mask |= LogWs.DEBUG;
		else LogWs.mask &= ~LogWs.DEBUG;
		return value;
	}
	/**
	* Ditto to LOG_INFO
	**/
	private static var LOG_DATA(default, set):Bool = false;
	private static function set_LOG_DATA(value:Bool):Bool {
		LOG_DATA = value;
		if (LOG_DATA) LogWs.mask |= LogWs.DATA;
		else LogWs.mask &= ~LogWs.DATA;
		return value;
	}
	
	@:dox(hide) private var _ws:WebSocket;

	/**
	* This keeps track of the amount of bytes sent and received.
	* You can set the logging state directly in the class.
	**/
	public var metrics:Metrics = new Metrics();

	/**
	* This signal is only called once when the connection is opened.
	**/
	public var onOpen:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
	/**
	* This signal is called every time a message is received.
	* It can be one of three types: String, Bytes, or FunkinPacket.
	* If you have AUTO_DECODE_PACKETS set to true, It will attempt to deserialize the packet into a FunkinPacket.
	* If it fails to deserialize or AUTO_DECODE_PACKETS is false, it will just return the Bytes directly.
	**/
	public var onMessage:FlxTypedSignal<OneOfThree<String, Bytes, FunkinPacket>->Void> = new FlxTypedSignal<OneOfThree<String, Bytes, FunkinPacket>->Void>(); // cursed 😭😭
	/**
	* This signal is only called once when the connection is closed.
	**/
	public var onClose:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
	/**
	* This signal is only called when an error occurs. Useful for debugging and letting the user know something has gone wrong.
	**/
	public var onError:FlxTypedSignal<Dynamic->Void> = new FlxTypedSignal<Dynamic->Void>();

	/**
	* The URL to connect to, including the protocol (ws:// or wss://). Currently wss:// (Secure WebSocket) is not supported.
	**/
	public var url:String;

	/**
	* This just allows you to override or add custom headers when the handshake happens, as this is the first and last time we use proper HTTP Headers.
	**/
	public var handshakeHeaders(get, null):Map<String, String>;
	public function get_handshakeHeaders():Map<String, String> { return this._ws.additionalHeaders; }

	/**
	* If true, the packets will be automatically deserialized into a `FunkinPacket` if possible.
	* Otherwise you will handle everything manually.
	**/
	public var AUTO_DECODE_PACKETS:Bool = true;

	/**
	* @param _url The URL to connect to, including the protocol (ws:// or wss://). Currently wss:// (SSH) is not supported.
	**/
	public function new(_url:String) {
		this.url = _url;

		this._ws = new WebSocket(this.url, false);
		this._ws.onopen = _onOpen;
		this._ws.onmessage = _onMessage;
		this._ws.onclose = _onClose;
		this._ws.onerror = _onError;
	}

	/**
	* Internal function for handling the onMessage event.
	* @param message The message to handle from hxWebSockets.
	**/
	private function _onMessage(message:MessageType):Void {
		var data:OneOfThree<String, Bytes, FunkinPacket> = "";

		switch(message) {
			case StrMessage(content):
				data = content;
				metrics.updateBytesReceived(Bytes.ofString(content).length);
				// Can we just have a switch break in Haxe for the life of me bro 💔💔💔
				if (AUTO_DECODE_PACKETS) {
					var packet:FunkinPacket = FunkinPacket.fromJson(cast(data, String));
					if (packet != null) {		
						packet.status = 200;

						data = packet;
					}
				}
			case BytesMessage(buffer):
				metrics.updateBytesReceived(buffer.length);
				if (AUTO_DECODE_PACKETS) {
					var packet:FunkinPacket = new FunkinPacket();
					packet.bytes = buffer.readAllAvailableBytes();
					packet.status = 200;
					data = packet;
				} else
					data = buffer.readAllAvailableBytes();
			default: trace('Unknown message type: ${message}');
		}

		onMessage.dispatch(data);
	}

	/**
	* Internal function for handling the onOpen event.
	**/
	private function _onOpen():Void {
		onOpen.dispatch();
	}

	/**
	* Internal function for handling the onClose event.
	**/
	private function _onClose():Void {
		onClose.dispatch();
	}

	/**
	* Internal function for handling the onError event.
	**/
	private function _onError(error:Dynamic):Void {
		onError.dispatch(error);
	}

	/**
	* Opens the WebSocket connection.
	**/
	public function open():FunkinWebSocket {
		Logs.traceColored([
			Logs.logText('[FunkinWebSocket] ', CYAN),
			Logs.logText('Opening WebSocket to ', NONE), Logs.logText(url, YELLOW),
		]);
		try {
			this._ws.open();
		} catch(e) {
			Logs.traceColored([
				Logs.logText('[FunkinWebSocket] ', CYAN),
				Logs.logText('Failed to open WebSocket: ${e}', NONE),
			]);
			onError.dispatch(e);
		}
		return this;
	}

	/**
	* Sends data to the server.
	* @param data The data to send.
	* @return true if the data was sent successfully, false if it failed.
	**/
	public function send(data:Dynamic):Bool {
		try {
			if (data is FunkinPacket)
				this._ws.send(data.stringify());
			else
				this._ws.send(data);

			// Do an outside check to see if it wants to log before we try decoding stuff into raw bytes, to save on some unnecessary work.
			if (metrics.IS_LOGGING) {
				if (data is String) metrics.updateBytesSent(Bytes.ofString(data).length);
				else if (data is Bytes) metrics.updateBytesSent(data.length);
				else if (data is FunkinPacket) metrics.updateBytesSent(data.toBytes().length);
			}

			return true;
		} catch(e) {
			Logs.traceColored([
				Logs.logText('[FunkinWebSocket] ', CYAN),
				Logs.logText('Failed to send data: ${e}', NONE),
			]);
		}
		return false;
	}

	/**
	* Closes the WebSocket connection.
	* Once you close the connection, you cannot reopen it, you must create a new instance.
	**/
	public function close():Void {
		Logs.traceColored([
			Logs.logText('[FunkinWebSocket] ', CYAN),
			Logs.logText('Closing WebSocket from ', NONE), Logs.logText(url, YELLOW),
		]);
		this._ws.close();
	}

	/**
	* Basically the same as close(), but if a class is handling it and expects it to be IFlxDestroyable compatable, it will call this.
	**/
	public function destroy():Void { close(); }
}