package funkin.editors.ui;

import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxSort;

class UIButtonList<T:UIButton> extends UIWindow {
	public var buttons:FlxTypedGroup<T> = new FlxTypedGroup<T>();
	public var addButton:UIButton;
	public var addIcon:FlxSprite;

	public var buttonCameras:FlxCamera;
	public var cameraSpacing = 30;

	public var buttonSpacing:Float = 16;
	public var buttonSize:FlxPoint = null;
	public var buttonOffset:FlxPoint = FlxPoint.get();

	public var dragging:Bool = false;
	public var dragCallback:(T,Int,Int)->Void;

	var curMoving:T = null;
	var curMovingInterval:Float = 0;

	public function new(x:Float, y:Float, width:Int, height:Int, windowName:String, buttonSize:FlxPoint, ?buttonOffset:FlxPoint, ?buttonSpacing:Float) {
		if (buttonSpacing != null) this.buttonSpacing = buttonSpacing;
		this.buttonSize = buttonSize;
		if (buttonOffset != null) this.buttonOffset = buttonOffset;
		super(x, y, width, height, windowName);

		buttonCameras = new FlxCamera(Std.int(x), Std.int(y+cameraSpacing), width, height-cameraSpacing-1);
		FlxG.cameras.add(buttonCameras, false);
		buttonCameras.bgColor = 0;

		addButton = new UIButton(25, 16, null, null, Std.int(this.buttonSize.x));
		addButton.autoAlpha = false;
		addButton.color = 0xFF00FF00;
		addButton.cameras = [buttonCameras];

		addIcon = new FlxSprite(addButton.x + addButton.bHeight / 2, addButton.y + (32/2) - 8).loadGraphic(Paths.image('editors/charter/add-button'));
		addIcon.antialiasing = false;
		addButton.members.push(addIcon);
		content.add(addButton);

		content.add(buttons);
		nextscrollY = buttonCameras.scroll.y = -this.buttonSpacing;
	}

	public inline function add(button:T) {
		button.ID = buttons.members.length;
		buttons.add(button);
		curMovingInterval = 0;
		nextscrollY += button.bHeight;
	}

	public inline function insert(button:T, position:Int) {
		button.ID = position;
		buttons.insert(position, button);
		nextscrollY += button.bHeight;
	}

	public inline function remove(button:T) {
		nextscrollY -= button.bHeight;
		buttons.remove(button, true);
		button.destroy();
	}

	public inline function updateButtonsPos(elapsed:Float) {
		var endButtonY:Float = 0;
		for (i => button in buttons.members) {
			if (button == null) continue;
			
			if (curMoving != button) {
				button.setPosition(
					(bWidth/2) - (buttonSize.x/2) + buttonOffset.x,
					CoolUtil.fpsLerp(button.y, endButtonY + buttonOffset.y, 0.25));
			}
			endButtonY += button.bHeight+buttonSpacing;
			if (button.hovered && FlxG.mouse.justPressed) curMoving = button;
		}

		if (addButton != null)
			addButton.setPosition(
				(bWidth/2) - (buttonSize.x/2) + buttonOffset.x,
				CoolUtil.fpsLerp(addButton.y, endButtonY + buttonOffset.y, 0.25));

		if (curMoving != null) {
			curMovingInterval += FlxG.mouse.deltaY;
			if (Math.abs(curMovingInterval) > addButton.bHeight / 2) {
				curMovingInterval = 999;
				var mousePos = FlxG.mouse.getWorldPosition(buttonCameras);
				curMoving.y = CoolUtil.fpsLerp(curMoving.y, mousePos.y - (curMoving.bHeight / 2), 0.3);
				buttons.sort(function(o, a:T, b:T) return FlxSort.byValues(o, a.y + (a.bHeight / 2), b.y + (a.bHeight / 2)), -1);
				mousePos.put();
			}
			if (FlxG.mouse.justReleased) {
				curMoving = null;
				curMovingInterval = 0;
			}
		}
		addIcon.x = addButton.x + addButton.bWidth / 2 - addIcon.width / 2;
		addIcon.y = addButton.y + addButton.bHeight / 2 - addIcon.height / 2;
	}
	var nextscrollY:Float = 0;
	public override function update(elapsed:Float) {
		updateButtonsPos(elapsed);
		dragging = Math.abs(curMovingInterval) > addButton.bHeight / 2;

		super.update(elapsed);

		nextscrollY = CoolUtil.bound(nextscrollY - (hovered ? FlxG.mouse.wheel : 0) * 12, -buttonSpacing, Math.max((addButton.y + 32 + (buttonSpacing*1.5)) - buttonCameras.height, -buttonSpacing));

		if (curMoving != null && dragging) {
			var mousePos = FlxG.mouse.getWorldPosition(buttonCameras);
			nextscrollY -= Math.min((bHeight - 100) - mousePos.y, 0) / 8;
			nextscrollY += Math.min(mousePos.y - 100, 0) / 8;
			mousePos.put();
		}

		buttonCameras.scroll.y = FlxMath.lerp(buttonCameras.scroll.y, nextscrollY, 1/3);

		for (i => button in buttons.members) {
			if (button == null) continue;
			button.selectable = button.shouldPress = (hovered && !dragging);
			button.cameras = [buttonCameras];
			if (button.ID != i) {
				if (dragCallback != null) dragCallback(cast button, button.ID, i);
				button.ID = i; // Ok back to normal :D
			}
		}
		addButton.selectable = (hovered && !dragging);

		if (__lastDrawCameras[0] != null) {
			// -1 on each vertical sides for the little gap at the bottom of the window
			buttonCameras.height = bHeight - cameraSpacing - 2;
			buttonCameras.x = __lastDrawCameras[0].x + x - __lastDrawCameras[0].scroll.x;
			buttonCameras.y = __lastDrawCameras[0].y + y + cameraSpacing - __lastDrawCameras[0].scroll.y+1;
			buttonCameras.zoom = __lastDrawCameras[0].zoom;
		}
	}

	override function destroy() {
		super.destroy();

		if(buttonCameras != null) {
			if (FlxG.cameras.list.contains(buttonCameras))
				FlxG.cameras.remove(buttonCameras);
			buttonCameras = null;
		}
	}
}