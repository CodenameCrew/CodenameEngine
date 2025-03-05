package funkin.backend.system.net;

#if sys
import sys.net.Host;
import sys.net.Socket as SysSocket;

@:keep
class Socket implements IFlxDestroyable {
	public var socket:SysSocket;

	public function new(?socket:SysSocket) {
		this.socket = socket;
		if (this.socket == null)
			this.socket = new SysSocket();
		this.socket.setFastSend(true);
		this.socket.setBlocking(false);
	}

	public function read():String {
		try {
			return this.socket.input.readUntil('\n'.code).replace("\\n", "\n");
		} catch(e) {

		}
		return null;
	}

	public function write(str:String):Bool {
		try {
			this.socket.output.writeString(str.replace("\n", "\\n"));
			return true;
		} catch(e) {

		}
		return false;
	}

	public function host(host:Host, port:Int, nbConnections:Int = 1) {
		socket.bind(host, port);
		socket.listen(nbConnections);
		socket.setFastSend(true);
	}

	public function hostAndWait(h:Host, port:Int) {
		host(h, port);
		return acceptConnection();
	}

	public function acceptConnection():Socket {
		socket.setBlocking(true);
		var accept = new Socket(socket.accept());
		socket.setBlocking(false);
		return accept;
	}

	public function connect(host:Host, port:Int) {
		socket.connect(host, port);
	}

	public function destroy() {
		if (socket != null)
			socket.close();
	}
}
#end