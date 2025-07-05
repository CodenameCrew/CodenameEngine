package funkin.editors.ui;

import flixel.math.FlxRect;
import openfl.ui.MouseCursor;

@:allow(funkin.editors.ui.UIState)
@:allow(funkin.editors.ui.UIUtil)
class UISprite extends FlxSprite {
	public var members:Array<FlxBasic> = [];

	private var __lastDrawCameras:Array<FlxCamera> = [];
	private var __rect:FlxRect = new FlxRect();

	private var __oldDefCams:Array<FlxCamera>;

	public var hovered:Bool = false;
	public var hoveredByChild:Bool = false;
	public var pressed:Bool = false;

	public var canBeHovered:Bool = true;

	public var hoverCallback:Void->Void = null;

	public var cursor:MouseCursor = ARROW;

	public var focused(get, set):Bool;
	public var selectable:Bool = true;
	public var autoAlpha:Bool = true;

	private inline function get_focused():Bool
		return UIState.state.currentFocus == cast this;

	private inline function set_focused(b:Bool):Bool {
		if (get_focused()) {
			if (!b)
				UIState.state.currentFocus = null;
		} else {
			if (b)
				UIState.state.currentFocus = cast this;
		}
		return b;
	}

	public override function update(elapsed:Float) {
		hovered = false;
		pressed = false;
		hoveredByChild = false;

		super.update(elapsed);
		if (selectable)
			updateButton();

		@:privateAccess {
			__oldDefCams = FlxCamera._defaultCameras;
			FlxCamera._defaultCameras = cameras;

			for(m in members)
				m.update(elapsed);

			FlxCamera._defaultCameras = __oldDefCams;
		}

	}

	public override function draw() {
		drawSuper();
		drawMembers();
	}

	public function drawSuper() {
		super.draw();
		__lastDrawCameras = cameras.copy();
	}

	public function drawMembers() {
		@:privateAccess {
			__oldDefCams = FlxCamera._defaultCameras;
			FlxCamera._defaultCameras = cameras;

			for(m in members)
				if(m.exists && m.visible)
					m.draw();

			FlxCamera._defaultCameras = __oldDefCams;
		}
	}

	public override function destroy() {
		super.destroy();
		members = FlxDestroyUtil.destroyArray(members);
	}

	public function updateButton() {
		if(canBeHovered)
			updateButtonHandler();
		else {
			if(FlxG.mouse.pressed) {
				updateButtonHandler();
			}
		}
	}

	public function updateButtonHandler() {
		UIState.state.updateButtonHandler(this, onHovered);
	}

	/**
	 * Called whenever the sprite is being hovered by the mouse.
	 */
	public function onHovered() {
		hovered = true;
		if (FlxG.mouse.pressed)
			pressed = true;
		if (hoverCallback != null)
			hoverCallback();
	}
}