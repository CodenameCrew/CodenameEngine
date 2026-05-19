package mobile.controls;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;
import flixel.FlxCamera;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.input.keyboard.FlxKey;

class VirtualPad extends FlxSpriteGroup
{
	public var buttonA:FlxButton;
	public var buttonB:FlxButton;
	public var buttonC:FlxButton;
	public var buttonY:FlxButton;
	public var buttonX:FlxButton;
	public var buttonLeft:FlxButton;
	public var buttonUp:FlxButton;
	public var buttonRight:FlxButton;
	public var buttonDown:FlxButton;

	public var virtualpadCamera:FlxCamera;

	public static var touchingPad:Bool = false;

	private inline static var B_W:Int = 132;
	private inline static var B_H:Int = 135;

	public var boundActions:Map<FlxButton, Array<String>> = new Map();

	private var atlasFrames:FlxAtlasFrames;
	
	public static inline var HOLD_DELAY:Float = 0.15;

	public static inline var HOLD_REPEAT:Float = 0.05;

	private var holdTimers:Map<String, Float> = new Map();
	private var holdActive:Map<String, Bool> = new Map();

	public var keyBinds:Map<String, FlxKey> = [
		"up" => FlxKey.UP,
		"down" => FlxKey.DOWN,
		"left" => FlxKey.LEFT,
		"right" => FlxKey.RIGHT,
		"a" => FlxKey.ENTER,
		"b" => FlxKey.BACKSPACE,
		"c" => FlxKey.SHIFT,
		"x" => FlxKey.SEVEN,
		"y" => FlxKey.TAB
	];
	
	public function new(?DPad:FlxDPadMode, ?Action:FlxActionMode)
	{
		super();

		virtualpadCamera = new FlxCamera();
		virtualpadCamera.bgColor = 0x00000000;
		FlxG.cameras.add(virtualpadCamera, false);
		this.cameras = [virtualpadCamera];

		atlasFrames = FlxAtlasFrames.fromSpriteSheetPacker(
	     'assets/images/menus/virtual-input.png',
	     'assets/images/menus/virtual-input.txt'
		);
		
		switch (DPad)
		{
			case NONE:
			case UP_DOWN:
				add(buttonUp = createButton(0, FlxG.height - 255, B_W, B_H, "up"));
				add(buttonDown = createButton(0, FlxG.height - 135, B_W, B_H, "down"));
			case LEFT_RIGHT:
				add(buttonLeft = createButton(0, FlxG.height - 135, B_W, B_H, "left"));
				add(buttonRight = createButton(126, FlxG.height - 135, B_W, B_H, "right"));
			case FULL:
				add(buttonUp = createButton(105, FlxG.height - 348, B_W, B_H, "up"));
				add(buttonLeft = createButton(0, FlxG.height - 243, B_W, B_H, "left"));
				add(buttonRight = createButton(207, FlxG.height - 243, B_W, B_H, "right"));
				add(buttonDown = createButton(105, FlxG.height - 135, B_W, B_H, "down"));
			default:
				add(buttonUp = createButton(105, FlxG.height - 348, B_W, B_H, "up"));
				add(buttonLeft = createButton(0, FlxG.height - 243, B_W, B_H, "left"));
				add(buttonRight = createButton(207, FlxG.height - 243, B_W, B_H, "right"));
				add(buttonDown = createButton(105, FlxG.height - 135, B_W, B_H, "down"));
		}

		switch (Action)
		{
			case A: add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
			case B: add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "b"));
			case X: add(buttonX = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "x"));
			case Y: add(buttonY = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "y"));
			case C: add(buttonC = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "c"));
			case A_B:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "b"));
			case A_C:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
				add(buttonC = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "c"));
			case A_X:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
				add(buttonX = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "x"));
			case A_Y:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "y"));
			case A_B_C:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonC = createButton(FlxG.width - 381, FlxG.height - 135, B_W, B_H, "c"));
			case A_X_Y:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 381, FlxG.height - 135, B_W, B_H, "x"));
			case A_B_X_Y:
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 132, FlxG.height - 255, B_W, B_H, "x"));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
			case A_B_C_X_Y:
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 132, FlxG.height - 255, B_W, B_H, "x"));
				add(buttonC = createButton(FlxG.width - 381, FlxG.height - 135, B_W, B_H, "c"));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
			case B_C:
				add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonC = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "c"));
			case B_X:
				add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonX = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "x"));
			case B_Y:
				add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "y"));
			case B_X_Y:
				add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 381, FlxG.height - 135, B_W, B_H, "x"));
			case B_C_X_Y:
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 132, FlxG.height - 255, B_W, B_H, "x"));
				add(buttonC = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "c"));
				add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "b"));
			case A_C_X_Y:
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 132, FlxG.height - 255, B_W, B_H, "x"));
				add(buttonC = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "c"));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
			case NONE:
			default:
		}

		scrollFactor.set();
	}

	public function rebind(button:String, key:String):Void
	{
		var btnLower = button.toLowerCase();
		var keyFormatted = FlxKey.fromString(key.toUpperCase());

		if (keyBinds.exists(btnLower) && keyFormatted != FlxKey.NONE)
		{
			keyBinds.set(btnLower, keyFormatted);
		}
	}

	override function update(elapsed:Float) 
	{
		var padButtons = [buttonLeft, buttonRight, buttonUp, buttonDown, buttonA, buttonB, buttonC, buttonX, buttonY];
		var overlappingPad:Bool = false;

		for (btn in padButtons) {
			if (btn != null && btn.visible && FlxG.mouse.overlaps(btn)) {
				overlappingPad = true;
				break;
			}
		}
		
		if (overlappingPad) {
			@:privateAccess {
				FlxG.mouse._leftButton.current = 0; 
				FlxG.mouse._leftButton.last = 0;
		   }
		}

		#if mobile
		this.alpha = Options.virtualPadOpacity;
		#end

		updateButtonKey(buttonUp, getBind("up"), "up", elapsed);
        updateButtonKey(buttonDown, getBind("down"), "down", elapsed);
        updateButtonKey(buttonLeft, getBind("left"), "left", elapsed);
        updateButtonKey(buttonRight, getBind("right"), "right", elapsed);
    
        updateButtonKey(buttonA, getBind("a"), "a", elapsed);
        updateButtonKey(buttonB, getBind("b"), "b", elapsed);
        updateButtonKey(buttonC, getBind("c"), "c", elapsed);
        updateButtonKey(buttonX, getBind("x"), "x", elapsed);
        updateButtonKey(buttonY, getBind("y"), "y", elapsed);

		super.update(elapsed);
	}

	private inline function getBind(keyName:String):FlxKey 
    {
        return keyBinds.exists(keyName) ? keyBinds.get(keyName) : FlxKey.NONE;
    }
    
	private function updateButtonKey(btn:FlxButton, key:FlxKey, actionName:String, elapsed:Float):Void
	{
		if (btn == null || !btn.exists || !btn.active || key == FlxKey.NONE) return;

        if (btn.justPressed)
	    {
			FlxG.keys.handleAction(key, true);
			holdTimers.set(actionName, 0);
			holdActive.set(actionName, false);
		}
		
		if (btn.pressed && !btn.justPressed)
		{
			var timer = holdTimers.exists(actionName) ? holdTimers.get(actionName) : 0;
			var active = holdActive.exists(actionName) ? holdActive.get(actionName) : false;
			
			timer += elapsed;
			
			if (!active)
			{
				if (timer >= HOLD_DELAY)
				{
					holdActive.set(actionName, true);
					holdTimers.set(actionName, 0);
					FlxG.keys.handleAction(key, true);
				}
				else
				{
					holdTimers.set(actionName, timer);
				}
			}
			else
			{
				if (timer >= HOLD_REPEAT)
				{
					holdTimers.set(actionName, 0);
					FlxG.keys.handleAction(key, true);
				}
				else
				{
					holdTimers.set(actionName, timer);
				}
			}
		}
		
		if (btn.justReleased)
		{
			FlxG.keys.handleAction(key, false);
			holdTimers.remove(actionName);
			holdActive.remove(actionName);
		}
	}

	override public function draw():Void {
		if (virtualpadCamera != null && !FlxG.cameras.list.contains(virtualpadCamera))
		{
			return; 
		}

		super.draw();
	}

	private function addAction(btn:FlxButton, action:String):Void
	{
		if (btn == null || action == null || action == "") return;
		if (!boundActions.exists(btn)) boundActions.set(btn, []);
		
		var list = boundActions.get(btn);
		if (!list.contains(action)) list.push(action);
	}

	public function bindDPad(up:String, down:String, left:String, right:String):Void
	{
		addAction(buttonUp, up);
		addAction(buttonDown, down);
		addAction(buttonLeft, left);
		addAction(buttonRight, right);
	}

	public function bindActionGroup(a:String = "", b:String = "", x:String = "", y:String = "", c:String = ""):Void
	{
		addAction(buttonA, a);
		addAction(buttonB, b);
		addAction(buttonX, x);
		addAction(buttonY, y);
		addAction(buttonC, c);
	}

	public function pressed(action:String, elapsed:Float):Bool
	{
		if (boundActions == null) return false;

		var isDown:Bool = false;

		for (btn => actions in boundActions)
		{
			if (actions != null && actions.contains(action))
			{
				if (btn != null && btn.exists && btn.active && btn.pressed)
				{
					isDown = true;
					break;
				}
			}
		}
		if (!isDown)
		{
			if (holdTimers.exists(action))
			{
				holdTimers.remove(action);
				holdActive.remove(action);
			}
			return false;
		}
		if (!holdTimers.exists(action))
		{
			holdTimers.set(action, 0);
			holdActive.set(action, false);
			return true;
		}

		var timer = holdTimers.get(action);
		var active = holdActive.exists(action) ? holdActive.get(action) : false;

		timer += elapsed;

		if (!active)
		{
			if (timer >= HOLD_DELAY)
			{
				holdActive.set(action, true);
				holdTimers.set(action, 0);
				return true;
			}
		}
		else
		{
			if (timer >= HOLD_REPEAT)
			{
				holdTimers.set(action, 0);
				return true;
			}
		}

		holdTimers.set(action, timer);
		return false;
	}
	
	public function anyPressed():Bool
	{
		if (buttonUp != null && buttonUp.pressed) return true;
		if (buttonDown != null && buttonDown.pressed) return true;
		if (buttonLeft != null && buttonLeft.pressed) return true;
		if (buttonRight != null && buttonRight.pressed) return true;

		if (buttonA != null && buttonA.pressed) return true;
		if (buttonB != null && buttonB.pressed) return true;
		if (buttonX != null && buttonX.pressed) return true;
		if (buttonY != null && buttonY.pressed) return true;
		if (buttonC != null && buttonC.pressed) return true;

		return false;
	}

	public function isTouchOnPad(point:FlxPoint):Bool
	{
		if (buttonUp != null && buttonUp.overlapsPoint(point)) return true;
		if (buttonDown != null && buttonDown.overlapsPoint(point)) return true;
		if (buttonLeft != null && buttonLeft.overlapsPoint(point)) return true;
		if (buttonRight != null && buttonRight.overlapsPoint(point)) return true;

		if (buttonA != null && buttonA.overlapsPoint(point)) return true;
		if (buttonB != null && buttonB.overlapsPoint(point)) return true;
		if (buttonX != null && buttonX.overlapsPoint(point)) return true;
		if (buttonY != null && buttonY.overlapsPoint(point)) return true;
		if (buttonC != null && buttonC.overlapsPoint(point)) return true;

		return false;
	}
	
	public function justPressed(action:String):Bool
	{
		if (boundActions == null) return false; 

		for (btn => actions in boundActions)
		{
			if (actions != null && actions.contains(action))
			{
				if (btn != null && btn.exists && btn.active && btn.justPressed)
					return true;
			}
		}
		return false;
	}

	public function justReleased(action:String):Bool
	{
		if (boundActions == null) return false; 

		for (btn => actions in boundActions) {
			if (actions != null && actions.contains(action)) {
				if (btn != null && btn.justReleased)
					return true;
			}
		}
		return false;
	}
	
	override public function destroy():Void
	{
		if (boundActions != null)
		{
			boundActions.clear();
			boundActions = null;
		}

		if (virtualpadCamera != null)
		{
			FlxG.cameras.remove(virtualpadCamera, false);
			virtualpadCamera = null;
		}

		buttonA = FlxDestroyUtil.destroy(buttonA);
		buttonB = FlxDestroyUtil.destroy(buttonB);
		buttonC = FlxDestroyUtil.destroy(buttonC);
		buttonX = FlxDestroyUtil.destroy(buttonX);
		buttonY = FlxDestroyUtil.destroy(buttonY);
		
		buttonLeft = FlxDestroyUtil.destroy(buttonLeft);
		buttonDown = FlxDestroyUtil.destroy(buttonDown);
		buttonUp = FlxDestroyUtil.destroy(buttonUp);
		buttonRight = FlxDestroyUtil.destroy(buttonRight);

		this.cameras = null;
		atlasFrames = null;

		super.destroy();
	}
	
	private function createButton(x:Float, y:Float, width:Int, height:Int, graphic:String):FlxButton
	{
		var button:FlxButton = new FlxButton(x, y);
		button.frames = FlxTileFrames.fromFrame(atlasFrames.getByName(graphic), FlxPoint.get(width, height));
		button.resetSizeFromFrame();
		button.solid = false;
		button.immovable = true;
		button.scrollFactor.set();
		return button;
	}
}

enum FlxDPadMode
{
	NONE;
	UP_DOWN;
	LEFT_RIGHT;
	UP_LEFT_RIGHT;
	DOWN_LEFT_RIGHT;
	RIGHT_FULL;
	FULL;
}

enum FlxActionMode
{
	NONE;
	A;
	B;
	X;
	Y;
	C;
	A_B;
	A_C;
	A_X;
	A_Y;
	A_B_C;
	A_X_Y;
	A_B_X_Y;
	A_C_X_Y;
	A_B_C_X_Y;
	B_C;
	B_X;
	B_Y;
	B_C_X_Y;
	B_X_Y;
}
