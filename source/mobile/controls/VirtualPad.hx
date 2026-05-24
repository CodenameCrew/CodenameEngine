package mobile.controls;

#if mobile
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
	
	private var buttonStates:Map<FlxButton, Bool> = new Map();
	private var buttonJustPressed:Map<FlxButton, Bool> = new Map();
	private var buttonJustReleased:Map<FlxButton, Bool> = new Map();

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

		
		if (Std.isOfType(FlxG.state, Charter)) {
            atlasFrames = FlxAtlasFrames.fromSpriteSheetPacker(
            'assets/images/editors/mobile/charter/virtual-input.png',
            'assets/images/editors/mobile/charter/virtual-input.txt');
        } else {
           atlasFrames = FlxAtlasFrames.fromSpriteSheetPacker(
			'assets/images/menus/virtual-input.png',
            'assets/images/menus/virtual-input.txt');
        }
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
		this.alpha = Options.virtualPadOpacity; 
	    
		var overlappingPad:Bool = false;
		var padButtons = [buttonLeft, buttonRight, buttonUp, buttonDown, buttonA, buttonB, buttonC, buttonX, buttonY];

		for (btn in padButtons) {
			if (btn == null || !btn.exists || !btn.active || !btn.visible) continue;

			var isPressed = false;

			for (touch in FlxG.touches.list) {
				if (touch.pressed) { 
					var point = touch.getWorldPosition(virtualpadCamera);
					if (btn.overlapsPoint(point, true, virtualpadCamera)) {
						isPressed = true;
						overlappingPad = true;
						break;
					}
				}
			}

			var wasPressed = buttonStates.exists(btn) ? buttonStates.get(btn) : false;
			var justPressed = isPressed && !wasPressed;
			var justReleased = !isPressed && wasPressed;

			buttonStates.set(btn, isPressed);
			buttonJustPressed.set(btn, justPressed);
			buttonJustReleased.set(btn, justReleased);

			var key = getBindForButton(btn);

            if (key != FlxKey.NONE)
            {
            	@:privateAccess
            	{
	        	if (justPressed)
		        {
        			FlxG.keys._keyListMap[key].current = JUST_PRESSED;
        		}
	            	else if (justReleased)
	               	{
		            	FlxG.keys._keyListMap[key].current = JUST_RELEASED;
	                    }
	            	else if (isPressed)
          	        {
	         		if (FlxG.keys._keyListMap[key].current == JUST_PRESSED)
			        	FlxG.keys._keyListMap[key].current = PRESSED;
					    }
		            else
            		{
	              		if (FlxG.keys._keyListMap[key].current == JUST_RELEASED)
			        	FlxG.keys._keyListMap[key].current = RELEASED;
	            	}
                }
            }
		}
		
		if (overlappingPad)
        {
            @:privateAccess
            FlxG.mouse._leftButton.current = FlxInputState.RELEASED;
		}

		VirtualPad.touchingPad = overlappingPad;

		super.update(elapsed);
	}
	
	private inline function getBind(keyName:String):FlxKey 
	{
		return keyBinds.exists(keyName) ? keyBinds.get(keyName) : FlxKey.NONE;
	}

	private function getBindForButton(btn:FlxButton):FlxKey 
	{
		if (btn == buttonUp) return getBind("up");
		if (btn == buttonDown) return getBind("down");
		if (btn == buttonLeft) return getBind("left");
		if (btn == buttonRight) return getBind("right");
		if (btn == buttonA) return getBind("a");
		if (btn == buttonB) return getBind("b");
		if (btn == buttonC) return getBind("c");
		if (btn == buttonX) return getBind("x");
		if (btn == buttonY) return getBind("y");
		return FlxKey.NONE;
	}

	override public function draw():Void {
		if (virtualpadCamera != null && !FlxG.cameras.list.contains(virtualpadCamera)) return; 
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

		for (btn => actions in boundActions) {
			if (actions != null && actions.contains(action)) {
				if (buttonStates.exists(btn) && buttonStates.get(btn)) return true;
			}
		}
		return false;
	}
	
	public function anyPressed():Bool
	{
		for (btn in buttonStates.keys()) {
			if (buttonStates.get(btn)) return true;
		}
		return false;
	}

	public function isTouchOnPad(point:FlxPoint):Bool
	{
		var padButtons = [buttonLeft, buttonRight, buttonUp, buttonDown, buttonA, buttonB, buttonC, buttonX, buttonY];
		for (btn in padButtons) {
			if (btn != null && btn.overlapsPoint(point)) return true;
		}
		return false;
	}
	
	public function justPressed(action:String):Bool
	{
		if (boundActions == null) return false; 

		for (btn => actions in boundActions) {
			if (actions != null && actions.contains(action)) {
				if (buttonJustPressed.exists(btn) && buttonJustPressed.get(btn)) return true;
			}
		}
		return false;
	}

	public function justReleased(action:String):Bool
	{
		if (boundActions == null) return false; 

		for (btn => actions in boundActions) {
			if (actions != null && actions.contains(action)) {
				if (buttonJustReleased.exists(btn) && buttonJustReleased.get(btn)) return true;
			}
		}
		return false;
	}

	public function justPressedRepeated(action:String, elapsed:Float):Bool
	{
		if (boundActions == null) return false;

		var isDown:Bool = false;
		for (btn => actions in boundActions) {
			if (actions != null && actions.contains(action)) {
				if (buttonStates.exists(btn) && buttonStates.get(btn)) {
					isDown = true;
					break;
				}
			}
		}
  
		if (!isDown) {
			holdTimers.remove(action);
			holdActive.remove(action);
			return false;
		}

		if (!holdTimers.exists(action)) {
			holdTimers.set(action, 0);
			holdActive.set(action, false);
			return true; 
		}

		var timer = holdTimers.get(action);
		var active = holdActive.exists(action) ? holdActive.get(action) : false;
		timer += elapsed;

		if (!active) {
			if (timer >= HOLD_DELAY) {
				holdActive.set(action, true);
				holdTimers.set(action, 0);
				return true;
			}
		 } else {
			if (timer >= HOLD_REPEAT) {
				holdTimers.set(action, 0);
				return true;
			}
		}

		holdTimers.set(action, timer);
		return false;
	}
	
	override public function destroy():Void
	{
		if (boundActions != null) {
			boundActions.clear();
			boundActions = null;
		}

		if (virtualpadCamera != null) {
			FlxG.cameras.remove(virtualpadCamera, false);
			virtualpadCamera = null;
		}

		if (buttonStates != null) {
			buttonStates.clear();
			buttonJustPressed.clear();
			buttonJustReleased.clear();
			buttonStates = null;
			buttonJustPressed = null;
			buttonJustReleased = null;
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

enum FlxDPadMode {
	NONE; UP_DOWN; LEFT_RIGHT; UP_LEFT_RIGHT; DOWN_LEFT_RIGHT; RIGHT_FULL; FULL;
}

enum FlxActionMode {
	NONE; A; B; X; Y; C; A_B; A_C; A_X; A_Y; A_B_C; A_X_Y; A_B_X_Y; A_C_X_Y; A_B_C_X_Y; B_C; B_X; B_Y; B_C_X_Y; B_X_Y;
}
#end
