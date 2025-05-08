package funkin.backend.system.net;

import hx.ws.*;

import funkin.backend.system.net.WebSocketPacket.ServerPacketData;
import funkin.backend.system.Logs;
import haxe.Unserializer;

import flixel.util.FlxTimer;

/**
* Basically a Utility for HScript to use WebSockets. Adds safeguards, error handling, and logging to debug your WebSockets.
* YOU WILL NEED TO HANDLE HOW THE WEBSOCKETS ARE CLOSED!!! calling `destroy` will close the WebSocket.
* ItsLJcool wanted to make CodenameEngine Online / Multiplayer. This will make it easier to do so.
*
* This does NOT support making a Server Side WebSocket. Its only for Client Side WebSockets. If you want to make a Server you need to that yourself.
* I'd suggest using JavaScript for it. Though any program will do.
*
* Check out the WebSocket Server Template for Codename Engine here:
* https://github.com/ItsLJcool/WebSocket-Server-Template-for-CNE
**/
class WebSocketUtil implements IFlxDestroyable {
	/**
	* Used for the `toggleLogging` function. this is more of a data handler for the function.
	**/
	static var loggingEnabled:Bool = false;

	/**
	* Call this function to toggle debugging for the WebSocket.
	**/
	static function toggleLogging(?INFO:Bool = true, ?DEBUG:Bool = true, ?DATA:Bool = true) {
		loggingEnabled = !loggingEnabled;
		if (!loggingEnabled) return Log.mask = 0;

		var _mask = Log.mask;
		if (INFO) _mask = _mask | Log.INFO;
		if (DEBUG) _mask = _mask | Log.DEBUG;
		if (DATA) _mask = _mask | Log.DATA;
		Log.mask = _mask;

		return Log.mask;
	}

	/**
	* Function calls after the WebSocket has been opened.
	* @param webSocket Returns the instance of the WebSocket.
	**/
	public var onOpen:WebSocketUtil->Void = (webSocket)->{};

	/**
	* Whenever the WebSocket receives a message sent from the server.
	* @param message Returns the message sent from the server.
	**/
	public var onMessage:Dynamic->Void = (message)->{};

	/**
	* Runs whenever the WebSocket closes.
	**/
	public var onClose:Void->Void = ()->{};

	/**
	* Runs whenever the WebSocket encounters an error.
	**/
	public var onError(default, set):Dynamic->Void = (error)->{};
	private function set_onError(_errorFunc):Dynamic->Void {
		var func = (error)->{
			Logs.traceColored([
				Logs.logText("[WebSocket Error] ", RED),
				Logs.logText('${error}'),
			], ERROR);
			if (_errorFunc != null) _errorFunc(error);
			if (this.closeOnError) this.close();
		};
		return this.onError = func;
	}

	/**
	* If true, the WebSocket will close when an error occurs.
	**/
	public var closeOnError:Bool = false;

	@:dox(hide) private var url:String;
	@:dox(hide) private var webSocket:WebSocket;
	
	/**
	* If true, when you call `open` the WebSocket will attempt to connect in a new thread.
	* Usefull for trying to connect to a WebSocket Server whilst the game is running.
	* WARNING: CAN CAUSE ERRORS IN HSCRIPT!!
	**/
	public var _threadedConnection:Bool = false;

	/**
	* If true, when you call `send` the WebSocket will attempt to send in a new thread.
	* WARNING: CAN CAUSE ERRORS IN HSCRIPT!!
	**/
	public var _threadedSend:Bool = false;
	
	@:dox(hide) public var __packets:Array<Dynamic> = [];

	/**
	* @param url The URL of the WebSocket. Usually `ws://localhost:port`.
	* @param onOpen sets the `onOpen` function directly to the class.
	* @param immediateOpen If true, the WebSocket will open immediately. Hence why `onOpen` is a function in the parameters.
	**/
	public function new(url:String, ?onOpen:WebSocketUtil->Void, ?immediateOpen:Bool = false) {
		this.onOpen = (onOpen == null) ? this.onOpen : onOpen;
		this.onError = this.onError;

		this.url = url;
		this.webSocket = new WebSocket(this.url, false);

		this.webSocket.onopen = function() {
			try {
				this.onOpen(this);
			} catch(error) {
				this.onError(error);
			}
		};

		this.webSocket.onmessage = function(message) {
			var data:Dynamic = null;
			try {
				switch(message) {
					case StrMessage(str):
						data = str;
						var _data = this.attemptDeserialize(data);
						if (WebSocketPacket.isServerPacket(_data)) data = _data;
					case BytesMessage(bytes):
						data = bytes;
				}
				this.onMessage(data);
			} catch(e) {
				this.onError(e);
			}
			__packets.push(data);
		};

		this.webSocket.onclose = function() {
			try {
				this.onClose();
			} catch(e) {
				this.onError(e);
			}
		};

		this.webSocket.onerror = this.onError;

		if (immediateOpen) this.open();
	}

	public function getRecentPacket():Dynamic {
		return __packets.shift();
	}

	/**
	* @param rawData The raw data from the server
	* @return The packet data if it was found, otherwise null and WebSocketUtil will handle it.
	*/
	private function attemptDeserialize(rawData:String):Null<ServerPacketData> {
		if (!rawData.startsWith("!")) return null;

		for (key=>value in WebSocketPacket.packetTypes) {
			var hasPacketData = rawData.startsWith(value.params); // PREFIXname=>DATA
			var hasPacketNone = rawData.startsWith(value.none); // PREFIX=>DATA

			if (hasPacketNone) {
				var data = rawData.substr(rawData.indexOf("=>") + 2);
				var packetData:Dynamic = Unserializer.run(data);
				if (packetData == null) packetData = {};
				var packet:ServerPacketData = { name: null, data: packetData };
				return packet;
			}

			if (!hasPacketData) continue;

			try {
				var data = rawData.substr(rawData.indexOf("=>") + 2);
				var name = rawData.substring(value.params.length, rawData.indexOf("=>"));
				var packetData:Dynamic = Unserializer.run(data);
				if (packetData == null) packetData = {};
				var packet:ServerPacketData = { name: name, data: packetData };
				return packet;
			} catch (e:Dynamic) {
				trace('Error parsing packet: ${e}');
				return null;
			}
			break;
		}

		return null;
	}

	/**
	* Opens the WebSocket.
	**/
	public function open() {
		Logs.traceColored([
			Logs.logText("[WebSocket Connection] ", BLUE),
			Logs.logText('Connecting to ${this.url}'),
		], INFO);
		
		var _func = () -> {
			try {
				this.webSocket.open();
			} catch(e) {
				this.onError(e);
				return;
			}
			Logs.traceColored([
				Logs.logText("[WebSocket Connection] ", YELLOW),
				Logs.logText('Connected to ${this.url}'),
			], INFO);
		};
		if (this._threadedConnection) Main.execAsync(_func);
		else _func();
	}

	/**
	* Closes the WebSocket.
	**/
	public function close() {
		Logs.traceColored([
			Logs.logText("[WebSocket Connection] ", BLUE),
			Logs.logText('Closing connection to ${this.url}'),
		], INFO);

		try {
			this.webSocket.close();
			this._isClosed = true;
		} catch(e) {
			this.onError(e);
		}
	}

	/**
	* Sends data to the server
	**/
	public function send(data) {	
		var _data = null;
		if (data is WebSocketPacket) _data = data.toString();
		else _data = data;
		try {
			this.webSocket.send(_data);
		} catch(e) {
			this.onError(e);
		}
	}

	private var _isClosed:Bool = false;

	/**
	* Closes the WebSocket and destroys the class instance.
	**/
	public function destroy() {
		if (this._isClosed) return;

		this.close();
	}
}