package funkin.backend.system.interfaces;

interface IBeatCancellableReceiver extends IBeatReceiver {
	public var cancelConductorUpdate:Bool;
}