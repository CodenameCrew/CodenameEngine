package funkin.backend.system;

import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

enum Control
{
	UP;
	LEFT;
	RIGHT;
	DOWN;
	NOTE_UP;
	NOTE_LEFT;
	NOTE_RIGHT;
	NOTE_DOWN;
	RESET;
	ACCEPT;
	BACK;
	PAUSE;
	CHANGE_MODE;
	//CHEAT;
	SWITCHMOD;

	// Debugs
	DEV_ACCESS;
	DEV_CONSOLE;
	DEV_RELOAD;
}

enum KeyboardScheme
{
	Solo;
	Duo(first:Bool);
	None;
	Custom;
}

/**
 * A list of actions that a player would invoke via some input device.
 * Uses FlxActions to funnel various inputs to a single action.
 */
// Macro generated
// A and B are swapped for switch
@:noCustomClass
@:nullSafety
@:build(funkin.backend.system.macros.ControlsMacro.build())
class Controls extends FlxActionSet
{
	// Menus
	#if !switch
	@:rawGamepad([DPAD_UP, LEFT_STICK_DIGITAL_UP])
	#else
	@:rawGamepad([DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP])
	#end
	@:pressed("up") public var UP(get, set): Bool;
	@:justPressed("up") public var UP_P(get, set): Bool;
	@:justReleased("up") public var UP_R(get, set): Bool;

	#if !switch
	@:rawGamepad([DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT])
	#else
	@:rawGamepad([DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT])
	#end
	@:pressed("left") public var LEFT(get, set): Bool;
	@:justPressed("left") public var LEFT_P(get, set): Bool;
	@:justReleased("left") public var LEFT_R(get, set): Bool;

	#if !switch
	@:rawGamepad([DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT])
	#else
	@:rawGamepad([DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT])
	#end
	@:pressed("right") public var RIGHT(get, set): Bool;
	@:justPressed("right") public var RIGHT_P(get, set): Bool;
	@:justReleased("right") public var RIGHT_R(get, set): Bool;

	#if !switch
	@:rawGamepad([DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN])
	#else
	@:rawGamepad([DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN])
	#end
	@:pressed("down") public var DOWN(get, set): Bool;
	@:justPressed("down") public var DOWN_P(get, set): Bool;
	@:justReleased("down") public var DOWN_R(get, set): Bool;

	// Note Controls

	#if !switch
	@:rawGamepad([DPAD_UP, LEFT_STICK_DIGITAL_UP])
	#else
	@:rawGamepad([DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP])
	#end
	@:pressed("note-up") public var NOTE_UP(get, set): Bool;
	@:justPressed("note-up") public var NOTE_UP_P(get, set): Bool;
	@:justReleased("note-up") public var NOTE_UP_R(get, set): Bool;

	#if !switch
	@:rawGamepad([DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT])
	#else
	@:rawGamepad([DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT])
	#end
	@:pressed("note-left") public var NOTE_LEFT(get, set): Bool;
	@:justPressed("note-left") public var NOTE_LEFT_P(get, set): Bool;
	@:justReleased("note-left") public var NOTE_LEFT_R(get, set): Bool;

	#if !switch
	@:rawGamepad([DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT])
	#else
	@:rawGamepad([DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT])
	#end
	@:pressed("note-right") public var NOTE_RIGHT(get, set): Bool;
	@:justPressed("note-right") public var NOTE_RIGHT_P(get, set): Bool;
	@:justReleased("note-right") public var NOTE_RIGHT_R(get, set): Bool;

	#if !switch
	@:rawGamepad([DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN])
	#else
	@:rawGamepad([DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN])
	#end
	@:pressed("note-down") public var NOTE_DOWN(get, set): Bool;
	@:justPressed("note-down") public var NOTE_DOWN_P(get, set): Bool;
	@:justReleased("note-down") public var NOTE_DOWN_R(get, set): Bool;

	@:gamepad([A])
	@:justPressed("accept") public var ACCEPT(get, set): Bool;
	@:pressed("accept") public var ACCEPT_HOLD(get, set): Bool;
	@:justReleased("accept") public var ACCEPT_R(get, set): Bool;

	@:gamepad([B])
	@:justPressed("back") public var BACK(get, set): Bool;
	@:pressed("back") public var BACK_HOLD(get, set): Bool;
	@:justReleased("back") public var BACK_R(get, set): Bool;

	@:gamepad([START])
	@:justPressed("pause") public var PAUSE(get, set): Bool;
	@:pressed("pause") public var PAUSE_HOLD(get, set): Bool;
	@:justReleased("pause") public var PAUSE_R(get, set): Bool;

	@:gamepad([Y])
	@:justPressed("reset") public var RESET(get, set): Bool;
	@:pressed("reset") public var RESET_HOLD(get, set): Bool;
	@:justReleased("reset") public var RESET_R(get, set): Bool;

	@:gamepad([FlxGamepadInputID.BACK]) // select button
	@:justPressed("change-mode") public var CHANGE_MODE(get, set): Bool;
	@:pressed("change-mode") public var CHANGE_MODE_HOLD(get, set): Bool;
	@:justReleased("change-mode") public var CHANGE_MODE_R(get, set): Bool;

	//@:gamepad([])
	//@:justPressed("cheat") public var CHEAT(get, set): Bool;
	//@:pressed("cheat") public var CHEAT_HOLD(get, set): Bool;
	//@:justReleased("cheat") public var CHEAT_R(get, set): Bool;

	@:gamepad([FlxGamepadInputID.BACK]) // select button
	@:justPressed("switchmod") public var SWITCHMOD(get, set): Bool;
	@:pressed("switchmod") public var SWITCHMOD_HOLD(get, set): Bool;
	@:justReleased("switchmod") public var SWITCHMOD_R(get, set): Bool;

	@:devModeOnly
	@:gamepad([])
	@:justPressed("dev-access") public var DEV_ACCESS(get, set): Bool;
	@:pressed("dev-access") public var DEV_ACCESS_HOLD(get, set): Bool;
	@:justReleased("dev-access") public var DEV_ACCESS_R(get, set): Bool;

	@:devModeOnly
	@:gamepad([])
	@:justPressed("dev-console") public var DEV_CONSOLE(get, set): Bool;
	@:pressed("dev-console") public var DEV_CONSOLE_HOLD(get, set): Bool;
	@:justReleased("dev-console") public var DEV_CONSOLE_R(get, set): Bool;

	@:devModeOnly
	@:gamepad([])
	@:justPressed("dev-reload") public var DEV_RELOAD(get, set): Bool;
	@:pressed("dev-reload") public var DEV_RELOAD_HOLD(get, set): Bool;
	@:justReleased("dev-reload") public var DEV_RELOAD_R(get, set): Bool;

	@:allow(funkin.backend.utils.ControlsUtil)
	var byName:Map<String, FlxActionDigital> = [];

	public var gamepadsAdded:Array<Int> = [];
	public var keyboardScheme:KeyboardScheme = None;

	public function new(name, scheme = None)
	{
		super(name);

		macro_addKeysToActions();

		for (action in digitalActions)
			byName[action.name] = action;

		setKeyboardScheme(scheme, false);
	}

	public function getActionFromControl(control:Control):FlxAction return macro_getActionFromControl(control);

	public function getKeyName(control:Control, idx:Int = 0):String
	{
		var action = macro_getActionFromControl(control);
		var input = action.inputs[idx];
		return switch input.device
		{
			case KEYBOARD: return '${(input.inputID : FlxKey)}';
			case GAMEPAD: return '${(input.inputID : FlxGamepadInputID)}';
			case device: throw 'unhandled device: $device';
		}
	}

	public function replaceBindingKeyboard(control:Control, ?toAdd:Int, ?toRemove:Int)
	{
		if (toAdd == toRemove)
			return;

		if (toRemove != null)
			unbindKeys(control, [toRemove]);
		if (toAdd != null)
			bindKeys(control, [toAdd]);
	}

	public function replaceBindingGamepad(control:Control, deviceID:Int, ?toAdd:Int, ?toRemove:Int)
	{
		if (toAdd == toRemove)
			return;

		if (toRemove != null)
			unbindButtons(control, deviceID, [toRemove]);
		if (toAdd != null)
			bindButtons(control, deviceID, [toAdd]);
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public inline function bindKeys(control:Control, keys:Array<FlxKey>)
	{
		macro_forEachBound(control, (action, state) -> addKeys(action, keys, state));
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public inline function unbindKeys(control:Control, keys:Array<FlxKey>)
	{
		macro_forEachBound(control, (action, _) -> removeKeys(action, keys));
	}

	public inline static function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState)
	{
		for (key in keys)
			action.addKey(key, state);
	}

	public static function removeKeys(action:FlxActionDigital, keys:Array<FlxKey>)
	{
		var i = action.inputs.length;
		while (i-- > 0)
		{
			var input = action.inputs[i];
			if (input.device == KEYBOARD && keys.contains(cast input.inputID))
				action.remove(input);
		}
	}

	public function setKeyboardScheme(scheme:KeyboardScheme, reset = true)
	{
		if (reset)
			removeKeyboard();

		keyboardScheme = scheme;

		macro_bindControls(scheme);
	}

	function removeKeyboard()
	{
		for (action in this.digitalActions)
		{
			var i = action.inputs.length;
			while (i-- > 0)
			{
				var input = action.inputs[i];
				if (input.device == KEYBOARD)
					action.remove(input);
			}
		}
	}

	public function addGamepad(id:Int, buttonMap:Map<Control, Array<FlxGamepadInputID>>):Void
	{
		gamepadsAdded.push(id);

		for (control => buttons in buttonMap)
			bindButtons(control, id, buttons);
	}

	public function removeGamepad(deviceID:Int = FlxInputDeviceID.ALL):Void
	{
		for (action in this.digitalActions)
		{
			var i = action.inputs.length;
			while (i-- > 0)
			{
				var input = action.inputs[i];
				if (isGamepad(input, deviceID))
					action.remove(input);
			}
		}

		gamepadsAdded.remove(deviceID);
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public inline function bindButtons(control:Control, id, buttons)
	{
		macro_forEachBound(control, (action, state) -> addButtons(action, buttons, state, id));
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public inline function unbindButtons(control:Control, gamepadID:Int, buttons)
	{
		macro_forEachBound(control, (action, _) -> removeButtons(action, gamepadID, buttons));
	}

	public inline static function addButtons(action:FlxActionDigital, buttons:Array<FlxGamepadInputID>, state, id)
	{
		for (button in buttons)
			action.addGamepad(button, state, id);
	}

	public static function removeButtons(action:FlxActionDigital, gamepadID:Int, buttons:Array<FlxGamepadInputID>)
	{
		var i = action.inputs.length;
		while (i-- > 0)
		{
			var input = action.inputs[i];
			if (isGamepad(input, gamepadID) && buttons.contains(cast input.inputID))
				action.remove(input);
		}
	}

	public inline static function isGamepad(input:FlxActionInput, deviceID:Int)
	{
		return input.device == GAMEPAD && (deviceID == FlxInputDeviceID.ALL || input.deviceID == deviceID);
	}

	@:nullSafety(Off)
	public inline function getJustPressed(name:String) {
		return ControlsUtil.getJustPressed(this, name);
	}
	@:nullSafety(Off)
	public inline function getJustReleased(name:String) {
		return ControlsUtil.getJustReleased(this, name);
	}
	@:nullSafety(Off)
	public inline function getPressed(name:String) {
		return ControlsUtil.getPressed(this, name);
	}
}