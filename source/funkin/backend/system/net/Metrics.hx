package funkin.backend.system.net;

import flixel.util.FlxSignal.FlxTypedSignal;

class Metrics {
	public var bytesSent:Int = 0;
	public var bytesReceived:Int = 0;

	public var packetsSent:Int = 0;
	public var packetsReceived:Int = 0;

	public var IS_LOGGING:Bool = true;

	public var onBytesSent:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	public var onBytesReceived:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

	public function new() { }

	public function updateBytesSent(amount:Int) {
		if (!IS_LOGGING) return;

		bytesSent += amount;
		packetsSent++;

		onBytesSent.dispatch(amount);
	}

	public function updateBytesReceived(amount:Int) {
		if (!IS_LOGGING) return;

		bytesReceived += amount;
		packetsReceived++;

		onBytesReceived.dispatch(amount);
	}

	public function toString():String {
		return '(Metrics) $bytesSent bytes sent | $bytesReceived bytes received | $packetsSent packets sent | $packetsReceived packets received';
	}
}