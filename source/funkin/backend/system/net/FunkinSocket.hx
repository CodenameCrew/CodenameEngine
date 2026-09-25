package funkin.backend.system.net;

#if sys
import sys.net.Host;
import sys.net.Socket as SysSocket;
import haxe.io.Bytes;

@:keep
class FunkinSocket implements IFlxDestroyable {
	public var socket:SysSocket = new SysSocket();

	public var metrics:Metrics = new Metrics();

	public var FAST_SEND(default, set):Bool = true;
	private function set_FAST_SEND(value:Bool):Bool {
		FAST_SEND = value;
		socket.setFastSend(value);
		return value;
	}
	public var BLOCKING(default, set):Bool = false;
	private function set_BLOCKING(value:Bool):Bool {
		BLOCKING = value;
		socket.setBlocking(value);
		return value;
	}

	public var host:Host;
	public var port:Int;

	public function new(?_host:String = "127.0.0.1", ?_port:Int = 5000) {
		FAST_SEND = true;
		BLOCKING = false;
		this.host = new Host(_host);
		this.port = _port;
	}

	// Reading Area
	public function readAll():Null<Bytes> {
		try {
			var bytes = this.socket.input.readAll();
			if (bytes == null) return null;
			metrics.updateBytesReceived(bytes.length);
			return bytes;
		} catch(e) { }
		return null;
	}
	public function readLine():Null<String> {
		try {
			var bytes = this.socket.input.readLine();
			if (bytes == null) return null;
			metrics.updateBytesReceived(bytes.length);
			return bytes;
		} catch(e) { }
		return null;
	}
	public function read(nBytes:Int):Null<Bytes> {
		try {
			var bytes = this.socket.input.read(nBytes);
			if (bytes == null) return null;
			metrics.updateBytesReceived(bytes.length);
			return bytes;
		} catch(e) { }
		return null;
	}
	public function readBytes(bytes:Bytes):Int {
		try {
			var length = this.socket.input.readBytes(bytes, 0, bytes.length);
			metrics.updateBytesReceived(length);
			return length;
		} catch(e) { }
		return 0;
	}

	// Writing Area
	public function prepare(nbytes:Int):Void { socket.output.prepare(nbytes); }
	public function write(bytes:Bytes):Bool {
		try {
			this.socket.output.write(bytes);
			metrics.updateBytesSent(bytes.length);
			return true;
		} catch (e) { }
		return false;
	}
	public function writeString(str:String):Bool {
		try {
			this.socket.output.writeString(str);
			metrics.updateBytesSent(Bytes.ofString(str).length);
			return true;
		} catch(e) { }
		return false;
	}

	public function bind(?expectingConnections:Int = 1):FunkinSocket {
		Logs.traceColored([
			Logs.logText('[FunkinSocket] ', BLUE),
			Logs.logText('Binding to ', NONE), Logs.logText(host.toString(), YELLOW), Logs.logText(':', NONE), Logs.logText(Std.string(port), CYAN),
		]);
		socket.bind(host, port);
		socket.listen(expectingConnections);
		return this;
	}

	public function connect():FunkinSocket {
		Logs.traceColored([
			Logs.logText('[FunkinSocket] ', BLUE),
			Logs.logText('Connecting to ', NONE), Logs.logText(host.toString(), YELLOW), Logs.logText(':', NONE), Logs.logText(Std.string(port), CYAN),
		]);
		socket.connect(host, port);
		return this;
	}

	public function close() {
		try {
			if (socket != null) socket.close();
			Logs.traceColored([
				Logs.logText('[FunkinSocket] ', BLUE),
				Logs.logText('Closing socket from ', NONE), Logs.logText(host.toString(), YELLOW), Logs.logText(':', NONE), Logs.logText(Std.string(port), CYAN),
			]);
		} catch(e) {
			Logs.traceColored([
				Logs.logText('[FunkinSocket] ', BLUE),
				Logs.logText('Failed to close socket: ${e}', NONE),
			]);
		}
	}

	public function destroy() { close(); }
}
#end