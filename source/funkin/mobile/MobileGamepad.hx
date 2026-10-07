package funkin.mobile;

import flixel.input.FlxInput.FlxInputState;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import funkin.game.PlayState;
import lime.ui.Joystick;
import lime.ui.JoystickHatPosition;

class MobileGamepad {
	public static var active:Bool = false;
	public static var keys:Array<FlxKey> = [];

	static inline var DEADZONE:Float = 0.45;

	static var listening:Bool = false;
	static var pads:Map<Int, RawPad> = [];

	public static function init() {
		#if android
		try {
			lime.system.System.setHint("SDL_JOYSTICK_HIDAPI", "1");
			lime.system.System.setHint("SDL_JOYSTICK_HIDAPI_PS4", "1");
			lime.system.System.setHint("SDL_JOYSTICK_HIDAPI_PS5", "1");
			lime.system.System.setHint("SDL_JOYSTICK_HIDAPI_SWITCH", "1");
			lime.system.System.setHint("SDL_JOYSTICK_HIDAPI_XBOX", "1");
			lime.system.System.setHint("SDL_JOYSTICK_THREAD", "1");
		} catch (e:Dynamic) Logs.warn('Could not set joystick hints: $e');
		#end

		if (listening) return;
		listening = true;
		for (joystick in Joystick.devices)
			attach(joystick);
		Joystick.onConnect.add(attach);
	}

	public static function poll() {
		keys.resize(0);
		var usingPad = mappedInput() || rawInput();
		if (usingPad) active = true;
		else if (!hasMappedPad() && !hasRawPad()) active = false;
		if (touchStarted()) active = false;
	}

	static function mappedInput():Bool {
		#if FLX_GAMEPAD
		for (id in 0...16) {
			var pad = FlxG.gamepads.getByID(id);
			if (pad == null || !pad.connected || ignored(pad.name)) continue;
			if (pad.anyButton(FlxInputState.PRESSED) || analogMoved(pad)) return true;
		}
		#end
		return false;
	}

	static function hasMappedPad():Bool {
		#if FLX_GAMEPAD
		for (id in 0...16) {
			var pad = FlxG.gamepads.getByID(id);
			if (pad != null && pad.connected && !ignored(pad.name)) return true;
		}
		#end
		return false;
	}

	static function analogMoved(pad:FlxGamepad):Bool {
		return Math.abs(pad.getXAxis(FlxGamepadInputID.LEFT_ANALOG_STICK)) > DEADZONE
			|| Math.abs(pad.getYAxis(FlxGamepadInputID.LEFT_ANALOG_STICK)) > DEADZONE
			|| Math.abs(pad.getXAxis(FlxGamepadInputID.RIGHT_ANALOG_STICK)) > DEADZONE
			|| Math.abs(pad.getYAxis(FlxGamepadInputID.RIGHT_ANALOG_STICK)) > DEADZONE;
	}

	static function rawInput():Bool {
		if (hasMappedPad()) return false;
		var usingPad = false;
		for (pad in pads) {
			if (pad == null || ignored(pad.name)) continue;
			if (fillKeys(pad)) usingPad = true;
		}
		return usingPad;
	}

	static function fillKeys(pad:RawPad):Bool { // notes in songs, accept/back in menus. same as Controls
		var song = inSong();
		var used = false;

		if (axisDir(pad, 0) < 0 || pad.hat.left || pad.button(13) || pad.button(2)) {
			pushKey(noteKey("left"));
			if (!song) pushKey(menuKey("left"));
			used = true;
		}
		if (axisDir(pad, 0) > 0 || pad.hat.right || pad.button(14) || (pad.button(1) && song)) {
			pushKey(noteKey("right"));
			if (!song) pushKey(menuKey("right"));
			used = true;
		}
		if (axisDir(pad, 1) < 0 || pad.hat.up || pad.button(11) || pad.button(3)) {
			pushKey(noteKey("up"));
			if (!song) pushKey(menuKey("up"));
			used = true;
		}
		if (axisDir(pad, 1) > 0 || pad.hat.down || pad.button(12) || (pad.button(0) && song)) {
			pushKey(noteKey("down"));
			if (!song) pushKey(menuKey("down"));
			used = true;
		}

		if (!song && pad.button(0)) { pushKey(firstKey(Options.P1_ACCEPT, FlxKey.ENTER)); used = true; }
		if (!song && pad.button(1)) { pushKey(firstKey(Options.P1_BACK, FlxKey.BACKSPACE)); used = true; }
		if (pad.button(6) || pad.button(7) || pad.button(8)) { pushKey(firstKey(Options.P1_PAUSE, FlxKey.ENTER)); used = true; }
		if (pad.button(4) || pad.button(9)) { pushKey(firstKey(Options.P1_SWITCHMOD, FlxKey.TAB)); used = true; }
		return used;
	}

	static function axisDir(pad:RawPad, axis:Int):Int {
		var value = pad.axis(axis);
		if (value < -DEADZONE) return -1;
		if (value > DEADZONE) return 1;
		return 0;
	}

	static function pushKey(key:FlxKey) {
		if (key != FlxKey.NONE && !keys.contains(key)) keys.push(key);
	}

	static function noteKey(dir:String):FlxKey {
		return switch (dir) {
			case "left": firstKey(Options.P1_NOTE_LEFT, FlxKey.A);
			case "down": firstKey(Options.P1_NOTE_DOWN, FlxKey.S);
			case "up": firstKey(Options.P1_NOTE_UP, FlxKey.W);
			case "right": firstKey(Options.P1_NOTE_RIGHT, FlxKey.D);
			default: FlxKey.NONE;
		}
	}

	static function menuKey(dir:String):FlxKey {
		return switch (dir) {
			case "left": firstKey(Options.P1_LEFT, FlxKey.A);
			case "down": firstKey(Options.P1_DOWN, FlxKey.S);
			case "up": firstKey(Options.P1_UP, FlxKey.W);
			case "right": firstKey(Options.P1_RIGHT, FlxKey.D);
			default: FlxKey.NONE;
		}
	}

	public static function firstKey(list:Array<FlxKey>, fallback:FlxKey):FlxKey {
		if (list != null) {
			for (key in list) if (key != FlxKey.NONE) return key;
		}
		return fallback;
	}

	public static function inSong():Bool {
		var state = FlxG.state;
		return state != null && state.subState == null && Std.isOfType(state, PlayState);
	}

	static function hasRawPad():Bool {
		for (pad in pads) {
			if (pad != null && !ignored(pad.name)) return true;
		}
		return false;
	}

	static function ignored(name:String):Bool { // sensors show up as joysticks
		if (name == null || name.length == 0) return false;
		var n = name.toLowerCase();
		return n.indexOf("accelerometer") >= 0 || n.indexOf("gyroscope") >= 0 || n.indexOf("sensor") >= 0;
	}

	static function touchStarted():Bool {
		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
			if (touch != null && touch.justPressed)
				return true;
		#end
		return false;
	}

	static function attach(joystick:Joystick) {
		if (joystick == null || pads.exists(joystick.id)) return;
		var pad = new RawPad(joystick);
		pads.set(joystick.id, pad);
		joystick.onDisconnect.add(() -> {
			pads.remove(joystick.id);
		});
		joystick.onAxisMove.add((axis, value) -> pad.axes.set(axis, value));
		joystick.onButtonDown.add((button) -> pad.held.set(button, true));
		joystick.onButtonUp.add((button) -> pad.held.set(button, false));
		joystick.onHatMove.add((_, position) -> pad.hat = position);
	}
}

private class RawPad {
	public var name:String;
	public var held:Map<Int, Bool> = [];
	public var axes:Map<Int, Float> = [];
	public var hat:JoystickHatPosition = JoystickHatPosition.CENTER;

	public function new(joystick:Joystick) {
		name = joystick.name;
	}

	public inline function button(id:Int):Bool
		return held.exists(id) && held.get(id);

	public inline function axis(id:Int):Float
		return axes.exists(id) ? axes.get(id) : 0;
}
