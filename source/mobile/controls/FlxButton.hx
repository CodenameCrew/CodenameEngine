package mobile.controls;

interface IMobileButton
{
	public function updateButton():Bool;
}

class FlxButtonManager
{
	public static var activeButtons:Array<IMobileButton> = [];
	public static var isGlobalHookInitialized:Bool = false;
	
	private static var _wasMouseHidden:Bool = false;

	public static function globalPreUpdate():Void
	{
		var isInputOccupied = false;

		for (btn in activeButtons)
		{
			var basic = cast(btn, flixel.FlxBasic);
			if (basic != null && basic.exists && basic.active && basic.visible)
			{
				#if FLX_POINTER_INPUT
				if (btn.updateButton())
					isInputOccupied = true;
				#end
			}
		}

		#if FLX_MOUSE
		@:privateAccess
		var mouseBtn = FlxG.mouse._leftButton;

		if (isInputOccupied)
		{
			if (mouseBtn.current == 2)
			{
				mouseBtn.current = 0;
			}
			else if (mouseBtn.current == 1)
			{
				if (!_wasMouseHidden) 
				{
					mouseBtn.current = -1;
				}
				else 
				{
					mouseBtn.current = 0;
				}
			}
			else if (mouseBtn.current == -1)
			{
				mouseBtn.current = 0;
			}
			
			_wasMouseHidden = true;
		}
		else
		{
			_wasMouseHidden = false;
		}
		#end
	}
}

class FlxButton extends FlxTypedButton<FlxText>
{
	public static inline var NORMAL:Int = 0;
	public static inline var HIGHLIGHT:Int = 1;
	public static inline var PRESSED:Int = 2;

	public var text(get, set):String;

	public function new(X:Float = 0, Y:Float = 0, ?Text:String, ?OnClick:Void->Void)
	{
		super(X, Y, OnClick);

		for (point in labelOffsets)
			point.set(point.x, point.y + 3);

		initLabel(Text);
	}

	override function resetHelpers():Void
	{
		super.resetHelpers();

		if (label != null)
		{
			label.fieldWidth = label.frameWidth = Std.int(width);
			label.size = label.size;
		}
	}

	inline function initLabel(Text:String):Void
	{
		if (Text != null)
		{
			label = new FlxText(x + labelOffsets[NORMAL].x, y + labelOffsets[NORMAL].y, 80, Text);
			label.setFormat(null, 8, 0x333333, "center");
			label.alpha = labelAlphas[status];
			label.drawFrame(true);
		}
	}

	inline function get_text():String
	{
		return (label != null) ? label.text : null;
	}

	inline function set_text(Text:String):String
	{
		if (label == null)
			initLabel(Text);
		else
			label.text = Text;

		return Text;
	}
}

#if !display
@:generic
#end
class FlxTypedButton<T:FlxSprite> extends FlxSprite implements IFlxInput implements IMobileButton
{
	public var label(default, set):T;

	public var labelOffsets:Array<FlxPoint> = [FlxPoint.get(), FlxPoint.get(), FlxPoint.get(0, 1)];
	public var labelAlphas:Array<Float> = [0.8, 1.0, 0.5];
	public var statusAnimations:Array<String> = ["normal", "highlight", "pressed"];
	public var allowSwiping:Bool = true;
	public var maxInputMovement:Float = Math.POSITIVE_INFINITY;
	public var status(default, set):Int;
	public var onUp(default, null):FlxButtonEvent;
	public var onDown(default, null):FlxButtonEvent;
	public var onOver(default, null):FlxButtonEvent;
	public var onOut(default, null):FlxButtonEvent;
	public var justReleased(get, never):Bool;
	public var released(get, never):Bool;
	public var pressed(get, never):Bool;
	public var justPressed(get, never):Bool;

	var _spriteLabel:FlxSprite;
	var input:FlxInput<Int>;
	var currentInput:IFlxInput;
	var lastStatus = -1;

	public function new(X:Float = 0, Y:Float = 0, ?OnClick:Void->Void)
	{
		super(X, Y);

		loadDefaultGraphic();

		onUp = new FlxButtonEvent(OnClick);
		onDown = new FlxButtonEvent();
		onOver = new FlxButtonEvent();
		onOut = new FlxButtonEvent();

		status = FlxButton.NORMAL;
		scrollFactor.set();

		statusAnimations[FlxButton.HIGHLIGHT] = "normal";
		labelAlphas[FlxButton.HIGHLIGHT] = 1;

		input = new FlxInput(0);

		FlxButtonManager.activeButtons.push(this);
		if (!FlxButtonManager.isGlobalHookInitialized)
		{
			FlxG.signals.preUpdate.add(FlxButtonManager.globalPreUpdate);
			FlxButtonManager.isGlobalHookInitialized = true;
		}
	}

	override public function graphicLoaded():Void
	{
		super.graphicLoaded();

		setupAnimation("normal", FlxButton.NORMAL);
		setupAnimation("highlight", FlxButton.HIGHLIGHT);
		setupAnimation("pressed", FlxButton.PRESSED);
	}

	function loadDefaultGraphic():Void
	{
		loadGraphic("flixel/images/ui/button.png", true, 80, 20);
	}

	function setupAnimation(animationName:String, frameIndex:Int):Void
	{
		frameIndex = Std.int(Math.min(frameIndex, animation.frames - 1));
		animation.add(animationName, [frameIndex]);
	}

	override public function destroy():Void
	{
		label = FlxDestroyUtil.destroy(label);
		_spriteLabel = null;

		onUp = FlxDestroyUtil.destroy(onUp);
		onDown = FlxDestroyUtil.destroy(onDown);
		onOver = FlxDestroyUtil.destroy(onOver);
		onOut = FlxDestroyUtil.destroy(onOut);

		labelOffsets = FlxDestroyUtil.putArray(labelOffsets);
	
		labelAlphas = null;
		currentInput = null;
		input = null;

		FlxButtonManager.activeButtons.remove(this);

		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (visible)
		{
			if (lastStatus != status)
			{
				updateStatusAnimation();
				lastStatus = status;
			}
		}

		input.update();
	}

	function updateStatusAnimation():Void
	{
		animation.play(statusAnimations[status]);
	}

	override public function draw():Void
	{
		super.draw();

		if (_spriteLabel != null && _spriteLabel.visible)
		{
			_spriteLabel.cameras = cameras;
			_spriteLabel.draw();
		}
	}

	#if FLX_DEBUG
	override public function drawDebug():Void
	{
		super.drawDebug();

		if (_spriteLabel != null)
			_spriteLabel.drawDebug();
	}
	#end

	public function stampOnAtlas(atlas:FlxAtlas):Bool
	{
		var buttonNode:FlxNode = atlas.addNode(graphic.bitmap, graphic.key);
		var result:Bool = (buttonNode != null);

		if (buttonNode != null)
		{
			var buttonFrames:FlxTileFrames = cast frames;
			var tileSize:FlxPoint = FlxPoint.get(buttonFrames.tileSize.x, buttonFrames.tileSize.y);
			var tileFrames:FlxTileFrames = buttonNode.getTileFrames(tileSize);
			this.frames = tileFrames;
		}

		if (result && label != null)
		{
			var labelNode:FlxNode = atlas.addNode(label.graphic.bitmap, label.graphic.key);
			result = result && (labelNode != null);

			if (labelNode != null)
				label.frames = labelNode.getImageFrame();
		}

		return result;
	}

	public function updateButton():Bool
    {
        var wasOwner = (currentInput != null); 
        var overlapFound = checkTouchOverlap();

        var inputJustReleased = (currentInput != null && currentInput.justReleased);
    
        if (inputJustReleased && overlapFound)
            onUpHandler();

        if (status != FlxButton.NORMAL && (!overlapFound || inputJustReleased))
            onOutHandler();

        return (currentInput != null) || overlapFound;
    }

	function checkTouchOverlap():Bool
	{
		var overlapFound = false;

		#if FLX_TOUCH
		var i = FlxG.touches.list.length - 1;
		while (i >= 0)
		{
			var touch = FlxG.touches.list[i];
			var consumed = false;
			
			for (camera in cameras)
			{
				if (checkInput(touch, touch, touch.justPressedPosition, camera))
				{
					overlapFound = true;
					consumed = true;
					break;
				}
			}
			
			if (consumed)
            {
	            FlxG.touches.list.remove(touch);
            }
			i--;
		}
		#end

		#if FLX_MOUSE
		for (camera in cameras)
		{
			@:privateAccess
			if (checkInput(FlxG.mouse, FlxG.mouse._leftButton, FlxG.mouse._leftButton.justPressedPosition, camera))
			{
				overlapFound = true;
				break;
			}
		}
		#end

		return overlapFound;
	}

	function checkInput(pointer:FlxPointer, input:IFlxInput, justPressedPosition:FlxPoint, camera:FlxCamera):Bool
	{
		if (maxInputMovement != Math.POSITIVE_INFINITY
			&& justPressedPosition.distanceTo(pointer.getScreenPosition(FlxPoint.weak())) > maxInputMovement
			&& input == currentInput)
		{
			currentInput = null;
		}
		else if (overlapsPoint(pointer.getWorldPosition(camera, _point), true, camera))
		{
			updateStatus(input);
			return true;
		}

		return false;
	}

	function updateStatus(input:IFlxInput):Void
	{
		if (input.justPressed)
		{
			currentInput = input;
			onDownHandler();
		}
		else if (status == FlxButton.NORMAL)
		{
			if (allowSwiping && input.pressed)
			{
				currentInput = input;
				onDownHandler();
			}
			else
				onOverHandler();
		}
	}

	function updateLabelPosition()
	{
		if (_spriteLabel != null)
		{
			_spriteLabel.x = (pixelPerfectPosition ? Math.floor(x) : x) + labelOffsets[status].x;
			_spriteLabel.y = (pixelPerfectPosition ? Math.floor(y) : y) + labelOffsets[status].y;
		}
	}

	function updateLabelAlpha()
	{
		if (_spriteLabel != null && labelAlphas.length > status)
			_spriteLabel.alpha = alpha * labelAlphas[status];
	}

	function onUpHandler():Void
	{
		status = FlxButton.HIGHLIGHT;
		input.release();
		currentInput = null;
		onUp.fire();
	}

	function onDownHandler():Void
	{
		status = FlxButton.PRESSED;
		input.press();
		onDown.fire();
	}

	function onOverHandler():Void
	{
		status = FlxButton.HIGHLIGHT;
		onOver.fire();
	}

	function onOutHandler():Void
	{
		status = FlxButton.NORMAL;
		input.release();
		currentInput = null;
		onOut.fire();
	}

	function set_label(Value:T):T
	{
		if (Value != null)
		{
			Value.scrollFactor.put();
			Value.scrollFactor = scrollFactor;
		}

		label = Value;
		_spriteLabel = label;
		updateLabelPosition();
		return Value;
	}

	function set_status(Value:Int):Int
	{
		status = Value;
		updateLabelAlpha();
		return status;
	}

	override function set_alpha(Value:Float):Float
	{
		super.set_alpha(Value);
		updateLabelAlpha();
		return alpha;
	}

	override function set_x(Value:Float):Float
	{
		super.set_x(Value);
		updateLabelPosition();
		return x;
	}

	override function set_y(Value:Float):Float
	{
		super.set_y(Value);
		updateLabelPosition();
		return y;
	}

	inline function get_justReleased():Bool
	{
		return input != null && input.justReleased;
	}

	inline function get_released():Bool
	{
		return input != null && input.released;
	}

	inline function get_pressed():Bool
	{
		return input != null && input.pressed;
	}

	inline function get_justPressed():Bool
	{
		return input != null && input.justPressed;
	}
}

private class FlxButtonEvent implements IFlxDestroyable
{
	public var callback:Void->Void;

	#if FLX_SOUND_SYSTEM
	public var sound:FlxSound;
	#end

	public function new(?Callback:Void->Void, ?sound:FlxSound)
	{
		callback = Callback;

		#if FLX_SOUND_SYSTEM
		this.sound = sound;
		#end
	}

	public inline function destroy():Void
	{
		callback = null;

		#if FLX_SOUND_SYSTEM
		sound = FlxDestroyUtil.destroy(sound);
		#end
	}

	public inline function fire():Void
	{
		if (callback != null)
			callback();

		#if FLX_SOUND_SYSTEM
		if (sound != null)
			sound.play(true);
		#end
	}
}
