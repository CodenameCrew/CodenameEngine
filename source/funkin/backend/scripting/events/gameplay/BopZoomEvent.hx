package funkin.backend.scripting.events.gameplay;

final class BopZoomEvent extends CancellableEvent {
	/**
		Whether to use the zoomMultiplier property in the camera.
	**/
	public var useZoomMultiplier:Bool;

	/**
		If higher than this, the zoom will be skipped.
	**/
	public var maxZoomMultiplier:Float;

	/**
		The zoom's strength multiplier.
	**/
	public var zoomStrength:Float;

	/**
		The zoom's strength multiplier on the game camera.
	**/
	public var camGameZoomMultiplier:Float;

	/**
		The zoom's strength multiplier on the HUD camera.
	**/
	public var camHUDZoomMultiplier:Float;
}