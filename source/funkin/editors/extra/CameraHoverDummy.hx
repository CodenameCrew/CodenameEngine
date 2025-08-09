package funkin.editors.extra;

class CameraHoverDummy extends UISprite {
	var parent:FlxBasic;
	public function new(?parent:FlxBasic, scroll:FlxPoint) {
		super();
		this.parent = parent;
		cameras = parent == null ? [FlxG.camera] : parent.cameras;
		scrollFactor.copyFrom(scroll);
	}

	public override function updateButton() {
		camera.getViewRect(__rect);
		UIState.state.updateRectButtonHandler(this, __rect, onHovered);
	}

	public override function draw() {
		@:privateAccess
		__lastDrawCameras = cameras.copy();
	}
}