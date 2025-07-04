package funkin.backend.system;

import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionInputDigital;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

enum abstract Action(String) to String from String {
	var UP = "up";
	var LEFT = "left";
	var RIGHT = "right";
	var DOWN = "down";
	var UP_P = "up-press";
	var LEFT_P = "left-press";
	var RIGHT_P = "right-press";
	var DOWN_P = "down-press";
	var UP_R = "up-release";
	var LEFT_R = "left-release";
	var RIGHT_R = "right-release";
	var DOWN_R = "down-release";


	var NOTE_UP = "note-up";
	var NOTE_LEFT = "note-left";
	var NOTE_RIGHT = "note-right";
	var NOTE_DOWN = "note-down";
	var NOTE_UP_P = "note-up-press";
	var NOTE_LEFT_P = "note-left-press";
	var NOTE_RIGHT_P = "note-right-press";
	var NOTE_DOWN_P = "note-down-press";
	var NOTE_UP_R = "note-up-release";
	var NOTE_LEFT_R = "note-left-release";
	var NOTE_RIGHT_R = "note-right-release";
	var NOTE_DOWN_R = "note-down-release";

	var ACCEPT = "accept";
	var BACK = "back";
	var PAUSE = "pause";
	var RESET = "reset";
	var CHEAT = "cheat";
	var SWITCHMOD = "switchmod";

	// Debugs
	var DEBUG_RELOAD = "debug-reload";
}

enum Device
{
	Keys;
	Gamepad(id:Int);
}

/**
 * Since, in many cases multiple actions should use similar keys, we don't want the
 * rebinding UI to list every action. ActionBinders are what the user perceives as
 * an input so, for instance, they can't set jump-press and jump-release to different keys.
 */
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
	CHEAT;
	SWITCHMOD;
	
	// Debugs
	DEBUG_RELOAD;
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
@:noCustomClass
class Controls extends FlxActionSet
{
	var _up = new FlxActionDigital(Action.UP);
	var _left = new FlxActionDigital(Action.LEFT);
	var _right = new FlxActionDigital(Action.RIGHT);
	var _down = new FlxActionDigital(Action.DOWN);
	var _upP = new FlxActionDigital(Action.UP_P);
	var _leftP = new FlxActionDigital(Action.LEFT_P);
	var _rightP = new FlxActionDigital(Action.RIGHT_P);
	var _downP = new FlxActionDigital(Action.DOWN_P);
	var _upR = new FlxActionDigital(Action.UP_R);
	var _leftR = new FlxActionDigital(Action.LEFT_R);
	var _rightR = new FlxActionDigital(Action.RIGHT_R);
	var _downR = new FlxActionDigital(Action.DOWN_R);

	var _noteUp = new FlxActionDigital(Action.NOTE_UP);
	var _noteLeft = new FlxActionDigital(Action.NOTE_LEFT);
	var _noteRight = new FlxActionDigital(Action.NOTE_RIGHT);
	var _noteDown = new FlxActionDigital(Action.NOTE_DOWN);
	var _noteUpP = new FlxActionDigital(Action.NOTE_UP_P);
	var _noteLeftP = new FlxActionDigital(Action.NOTE_LEFT_P);
	var _noteRightP = new FlxActionDigital(Action.NOTE_RIGHT_P);
	var _noteDownP = new FlxActionDigital(Action.NOTE_DOWN_P);
	var _noteUpR = new FlxActionDigital(Action.NOTE_UP_R);
	var _noteLeftR = new FlxActionDigital(Action.NOTE_LEFT_R);
	var _noteRightR = new FlxActionDigital(Action.NOTE_RIGHT_R);
	var _noteDownR = new FlxActionDigital(Action.NOTE_DOWN_R);

	var _accept = new FlxActionDigital(Action.ACCEPT);
	var _back = new FlxActionDigital(Action.BACK);
	var _pause = new FlxActionDigital(Action.PAUSE);
	var _reset = new FlxActionDigital(Action.RESET);
	var _cheat = new FlxActionDigital(Action.CHEAT);
	var _switchMod = new FlxActionDigital(Action.SWITCHMOD);
	
	var debug_reload = new FlxActionDigital(Action.DEBUG_RELOAD);

	#if (haxe >= "4.0.0")
	var byName:Map<String, FlxActionDigital> = [];
	#else
	var byName:Map<String, FlxActionDigital> = new Map<String, FlxActionDigital>();
	#end

	public var gamepadsAdded:Array<Int> = [];
	public var keyboardScheme = KeyboardScheme.None;

	public var UP(get, set):Bool;

	inline function get_UP()
		return _up.check();

	inline function set_UP(val)
		return @:privateAccess _up._checked = val;

	public var LEFT(get, set):Bool;

	inline function get_LEFT()
		return _left.check();

	inline function set_LEFT(val)
		return @:privateAccess _left._checked = val;

	public var RIGHT(get, set):Bool;

	inline function get_RIGHT()
		return _right.check();

	inline function set_RIGHT(val)
		return @:privateAccess _right._checked = val;

	public var DOWN(get, set):Bool;

	inline function get_DOWN()
		return _down.check();

	inline function set_DOWN(val)
		return @:privateAccess _down._checked = val;

	public var UP_P(get, set):Bool;

	inline function get_UP_P()
		return _upP.check();

	inline function set_UP_P(val)
		return @:privateAccess _upP._checked = val;

	public var LEFT_P(get, set):Bool;

	inline function get_LEFT_P()
		return _leftP.check();

	inline function set_LEFT_P(val)
		return @:privateAccess _leftP._checked = val;

	public var RIGHT_P(get, set):Bool;

	inline function get_RIGHT_P()
		return _rightP.check();

	inline function set_RIGHT_P(val)
		return @:privateAccess _rightP._checked = val;

	public var DOWN_P(get, set):Bool;

	inline function get_DOWN_P()
		return _downP.check();

	inline function set_DOWN_P(val)
		return @:privateAccess _downP._checked = val;

	public var UP_R(get, set):Bool;

	inline function get_UP_R()
		return _upR.check();

	inline function set_UP_R(val)
		return @:privateAccess _upR._checked = val;

	public var LEFT_R(get, set):Bool;

	inline function get_LEFT_R()
		return _leftR.check();

	inline function set_LEFT_R(val)
		return @:privateAccess _leftR._checked = val;

	public var RIGHT_R(get, set):Bool;

	inline function get_RIGHT_R()
		return _rightR.check();

	inline function set_RIGHT_R(val)
		return @:privateAccess _rightR._checked = val;

	public var DOWN_R(get, set):Bool;

	inline function get_DOWN_R()
		return _downR.check();

	inline function set_DOWN_R(val)
		return @:privateAccess _downR._checked = val;

	public var NOTE_UP(get, set):Bool;

	inline function get_NOTE_UP()
		return _noteUp.check();

	inline function set_NOTE_UP(val)
		return @:privateAccess _noteUp._checked = val;

	public var NOTE_LEFT(get, set):Bool;

	inline function get_NOTE_LEFT()
		return _noteLeft.check();

	inline function set_NOTE_LEFT(val)
		return @:privateAccess _noteLeft._checked = val;

	public var NOTE_RIGHT(get, set):Bool;

	inline function get_NOTE_RIGHT()
		return _noteRight.check();

	inline function set_NOTE_RIGHT(val)
		return @:privateAccess _noteRight._checked = val;

	public var NOTE_DOWN(get, set):Bool;

	inline function get_NOTE_DOWN()
		return _noteDown.check();

	inline function set_NOTE_DOWN(val)
		return @:privateAccess _noteDown._checked = val;

	public var NOTE_UP_P(get, set):Bool;

	inline function get_NOTE_UP_P()
		return _noteUpP.check();

	inline function set_NOTE_UP_P(val)
		return @:privateAccess _noteUpP._checked = val;

	public var NOTE_LEFT_P(get, set):Bool;

	inline function get_NOTE_LEFT_P()
		return _noteLeftP.check();

	inline function set_NOTE_LEFT_P(val)
		return @:privateAccess _noteLeftP._checked = val;

	public var NOTE_RIGHT_P(get, set):Bool;

	inline function get_NOTE_RIGHT_P()
		return _noteRightP.check();

	inline function set_NOTE_RIGHT_P(val)
		return @:privateAccess _noteRightP._checked = val;

	public var NOTE_DOWN_P(get, set):Bool;

	inline function get_NOTE_DOWN_P()
		return _noteDownP.check();

	inline function set_NOTE_DOWN_P(val)
		return @:privateAccess _noteDownP._checked = val;

	public var NOTE_UP_R(get, set):Bool;

	inline function get_NOTE_UP_R()
		return _noteUpR.check();

	inline function set_NOTE_UP_R(val)
		return @:privateAccess _noteUpR._checked = val;

	public var NOTE_LEFT_R(get, set):Bool;

	inline function get_NOTE_LEFT_R()
		return _noteLeftR.check();

	inline function set_NOTE_LEFT_R(val)
		return @:privateAccess _noteLeftR._checked = val;

	public var NOTE_RIGHT_R(get, set):Bool;

	inline function get_NOTE_RIGHT_R()
		return _noteRightR.check();

	inline function set_NOTE_RIGHT_R(val)
		return @:privateAccess _noteRightR._checked = val;

	public var NOTE_DOWN_R(get, set):Bool;

	inline function get_NOTE_DOWN_R()
		return _noteDownR.check();

	inline function set_NOTE_DOWN_R(val)
		return @:privateAccess _noteDownR._checked = val;

	public var ACCEPT(get, set):Bool;

	inline function get_ACCEPT()
		return _accept.check();

	inline function set_ACCEPT(val)
		return @:privateAccess _accept._checked = val;

	public var BACK(get, set):Bool;

	inline function get_BACK()
		return _back.check();

	inline function set_BACK(val)
		return @:privateAccess _back._checked = val;

	public var PAUSE(get, set):Bool;

	inline function get_PAUSE()
		return _pause.check();

	inline function set_PAUSE(val)
		return @:privateAccess _pause._checked = val;

	public var RESET(get, set):Bool;

	inline function get_RESET()
		return _reset.check();

	inline function set_RESET(val)
		return @:privateAccess _reset._checked = val;

	public var CHEAT(get, set):Bool;

	inline function get_CHEAT()
		return _cheat.check();

	inline function set_CHEAT(val)
		return @:privateAccess _cheat._checked = val;

	public var SWITCHMOD(get, set):Bool;

	inline function get_SWITCHMOD()
		return _switchMod.check();

	inline function set_SWITCHMOD(val)
		return @:privateAccess _switchMod._checked = val;

	public var DEBUG_RELOAD(get, set):Bool;

	inline function get_DEBUG_RELOAD()
		return debug_reload.check();

	inline function set_DEBUG_RELOAD(val)
		return @:privateAccess debug_reload._checked = val;

	public function new(name, scheme = None)
	{
		super(name);

		add(_up);
		add(_left);
		add(_right);
		add(_down);
		add(_upP);
		add(_leftP);
		add(_rightP);
		add(_downP);
		add(_upR);
		add(_leftR);
		add(_rightR);
		add(_downR);

		add(_noteUp);
		add(_noteLeft);
		add(_noteRight);
		add(_noteDown);
		add(_noteUpP);
		add(_noteLeftP);
		add(_noteRightP);
		add(_noteDownP);
		add(_noteUpR);
		add(_noteLeftR);
		add(_noteRightR);
		add(_noteDownR);

		add(_accept);
		add(_back);
		add(_pause);
		add(_reset);
		add(_cheat);
		add(_switchMod);
		add(debug_reload);

		for (action in digitalActions)
			byName[action.name] = action;

		setKeyboardScheme(scheme, false);
	}

	override function update()
	{
		super.update();
	}

	// inline
	public function checkByName(name:Action):Bool
	{
		#if debug
		if (!byName.exists(name))
			throw 'Invalid name: $name';
		#end
		return byName[name].check();
	}

	public function getKeyName(control:Control):String
	{
		return getDialogueName(getActionFromControl(control));
	}

	public function getDialogueName(action:FlxActionDigital):String
	{
		var input = action.inputs[0];
		return switch input.device
		{
			case KEYBOARD: return '${(input.inputID : FlxKey)}';
			case GAMEPAD: return '${(input.inputID : FlxGamepadInputID)}';
			case device: throw 'unhandled device: $device';
		}
	}

	public function getDialogueNameFromToken(token:String):String
	{
		return getDialogueName(getActionFromControl(Control.createByName(token.toUpperCase())));
	}

	function getActionFromControl(control:Control):FlxActionDigital
	{
		return switch (control)
		{
			case UP: _up;
			case DOWN: _down;
			case LEFT: _left;
			case RIGHT: _right;
			case NOTE_UP: _noteUp;
			case NOTE_DOWN: _noteDown;
			case NOTE_LEFT: _noteLeft;
			case NOTE_RIGHT: _noteRight;
			case ACCEPT: _accept;
			case BACK: _back;
			case PAUSE: _pause;
			case RESET: _reset;
			case CHEAT: _cheat;
			case SWITCHMOD: _switchMod;
			case DEBUG_RELOAD: debug_reload;
		}
	}

	static function init():Void
	{
		var actions = new FlxActionManager();
		FlxG.inputs.add(actions);
	}

	/**
	 * Calls a function passing each action bound by the specified control
	 * @param control
	 * @param func
	 * @return ->Void)
	 */
	function forEachBound(control:Control, func:FlxActionDigital->FlxInputState->Void)
	{
		switch (control)
		{
			case NOTE_UP:
				func(_noteUp, PRESSED);
				func(_noteUpP, JUST_PRESSED);
				func(_noteUpR, JUST_RELEASED);
			case NOTE_LEFT:
				func(_noteLeft, PRESSED);
				func(_noteLeftP, JUST_PRESSED);
				func(_noteLeftR, JUST_RELEASED);
			case NOTE_RIGHT:
				func(_noteRight, PRESSED);
				func(_noteRightP, JUST_PRESSED);
				func(_noteRightR, JUST_RELEASED);
			case NOTE_DOWN:
				func(_noteDown, PRESSED);
				func(_noteDownP, JUST_PRESSED);
				func(_noteDownR, JUST_RELEASED);
			case UP:
				func(_up, PRESSED);
				func(_upP, JUST_PRESSED);
				func(_upR, JUST_RELEASED);
			case LEFT:
				func(_left, PRESSED);
				func(_leftP, JUST_PRESSED);
				func(_leftR, JUST_RELEASED);
			case RIGHT:
				func(_right, PRESSED);
				func(_rightP, JUST_PRESSED);
				func(_rightR, JUST_RELEASED);
			case DOWN:
				func(_down, PRESSED);
				func(_downP, JUST_PRESSED);
				func(_downR, JUST_RELEASED);
			case ACCEPT:
				func(_accept, JUST_PRESSED);
			case BACK:
				func(_back, JUST_PRESSED);
			case PAUSE:
				func(_pause, JUST_PRESSED);
			case RESET:
				func(_reset, JUST_PRESSED);
			case CHEAT:
				func(_cheat, JUST_PRESSED);
			case SWITCHMOD:
				func(_switchMod, JUST_PRESSED);
			case DEBUG_RELOAD:
				func(debug_reload, JUST_PRESSED);
		}
	}

	public function replaceBinding(control:Control, device:Device, ?toAdd:Int, ?toRemove:Int)
	{
		if (toAdd == toRemove)
			return;

		switch (device)
		{
			case Keys:
				if (toRemove != null)
					unbindKeys(control, [toRemove]);
				if (toAdd != null)
					bindKeys(control, [toAdd]);

			case Gamepad(id):
				if (toRemove != null)
					unbindButtons(control, id, [toRemove]);
				if (toAdd != null)
					bindButtons(control, id, [toAdd]);
		}
	}

	public function copyFrom(controls:Controls, ?device:Device)
	{
		#if (haxe >= "4.0.0")
		for (name => action in controls.byName)
		{
			for (input in action.inputs)
			{
				if (device == null || isDevice(input, device))
					byName[name].add(cast input);
			}
		}
		#else
		for (name in controls.byName.keys())
		{
			var action = controls.byName[name];
			for (input in action.inputs)
			{
				if (device == null || isDevice(input, device))
				byName[name].add(cast input);
			}
		}
		#end

		switch (device)
		{
			case null:
				// add all
				#if (haxe >= "4.0.0")
				for (gamepad in controls.gamepadsAdded)
					if (!gamepadsAdded.contains(gamepad))
						gamepadsAdded.push(gamepad);
				#else
				for (gamepad in controls.gamepadsAdded)
					if (gamepadsAdded.indexOf(gamepad) == -1)
					  gamepadsAdded.push(gamepad);
				#end

				mergeKeyboardScheme(controls.keyboardScheme);

			case Gamepad(id):
				gamepadsAdded.push(id);
			case Keys:
				mergeKeyboardScheme(controls.keyboardScheme);
		}
	}

	inline public function copyTo(controls:Controls, ?device:Device)
	{
		controls.copyFrom(this, device);
	}

	function mergeKeyboardScheme(scheme:KeyboardScheme):Void
	{
		if (scheme != None)
		{
			switch (keyboardScheme)
			{
				case None:
					keyboardScheme = scheme;
				default:
					keyboardScheme = Custom;
			}
		}
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public function bindKeys(control:Control, keys:Array<FlxKey>)
	{
		#if (haxe >= "4.0.0")
		inline forEachBound(control, (action, state) -> addKeys(action, keys, state));
		#else
		forEachBound(control, function(action, state) addKeys(action, keys, state));
		#end
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public function unbindKeys(control:Control, keys:Array<FlxKey>)
	{
		#if (haxe >= "4.0.0")
		inline forEachBound(control, (action, _) -> removeKeys(action, keys));
		#else
		forEachBound(control, function(action, _) removeKeys(action, keys));
		#end
	}

	inline static function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState)
	{
		for (key in keys)
			action.addKey(key, state);
	}

	static function removeKeys(action:FlxActionDigital, keys:Array<FlxKey>)
	{
		var i = action.inputs.length;
		while (i-- > 0)
		{
			var input = action.inputs[i];
			if (input.device == KEYBOARD && keys.indexOf(cast input.inputID) != -1)
				action.remove(input);
		}
	}

	public function setKeyboardScheme(scheme:KeyboardScheme, reset = true)
	{
		if (reset)
			removeKeyboard();

		keyboardScheme = scheme;

		switch (scheme)
		{
			case Solo:
				inline bindKeys(Control.UP, Options.SOLO_UP);
				inline bindKeys(Control.DOWN, Options.SOLO_DOWN);
				inline bindKeys(Control.LEFT, Options.SOLO_LEFT);
				inline bindKeys(Control.RIGHT, Options.SOLO_RIGHT);
				inline bindKeys(Control.NOTE_UP, Options.SOLO_NOTE_UP);
				inline bindKeys(Control.NOTE_DOWN, Options.SOLO_NOTE_DOWN);
				inline bindKeys(Control.NOTE_LEFT, Options.SOLO_NOTE_LEFT);
				inline bindKeys(Control.NOTE_RIGHT, Options.SOLO_NOTE_RIGHT);
				inline bindKeys(Control.ACCEPT, Options.SOLO_ACCEPT);
				inline bindKeys(Control.BACK, Options.SOLO_BACK);
				inline bindKeys(Control.PAUSE, Options.SOLO_PAUSE);
				inline bindKeys(Control.RESET, Options.SOLO_RESET);
				inline bindKeys(Control.SWITCHMOD, Options.SOLO_SWITCHMOD);
				inline bindKeys(Control.DEBUG_RELOAD, Options.SOLO_DEBUG_RELOAD);
			case Duo(true):
				inline bindKeys(Control.UP, Options.P1_UP);
				inline bindKeys(Control.DOWN, Options.P1_DOWN);
				inline bindKeys(Control.LEFT, Options.P1_LEFT);
				inline bindKeys(Control.RIGHT, Options.P1_RIGHT);
				inline bindKeys(Control.NOTE_UP, Options.P1_NOTE_UP);
				inline bindKeys(Control.NOTE_DOWN, Options.P1_NOTE_DOWN);
				inline bindKeys(Control.NOTE_LEFT, Options.P1_NOTE_LEFT);
				inline bindKeys(Control.NOTE_RIGHT, Options.P1_NOTE_RIGHT);
				inline bindKeys(Control.ACCEPT, Options.P1_ACCEPT);
				inline bindKeys(Control.BACK, Options.P1_BACK);
				inline bindKeys(Control.PAUSE, Options.P1_PAUSE);
				inline bindKeys(Control.RESET, Options.P1_RESET);
				inline bindKeys(Control.SWITCHMOD, Options.P1_SWITCHMOD);
				inline bindKeys(Control.DEBUG_RELOAD, Options.P1_DEBUG_RELOAD);
			case Duo(false):
				inline bindKeys(Control.UP, Options.P2_UP);
				inline bindKeys(Control.DOWN, Options.P2_DOWN);
				inline bindKeys(Control.LEFT, Options.P2_LEFT);
				inline bindKeys(Control.RIGHT, Options.P2_RIGHT);
				inline bindKeys(Control.NOTE_UP, Options.P2_NOTE_UP);
				inline bindKeys(Control.NOTE_DOWN, Options.P2_NOTE_DOWN);
				inline bindKeys(Control.NOTE_LEFT, Options.P2_NOTE_LEFT);
				inline bindKeys(Control.NOTE_RIGHT, Options.P2_NOTE_RIGHT);
				inline bindKeys(Control.ACCEPT, Options.P2_ACCEPT);
				inline bindKeys(Control.BACK, Options.P2_BACK);
				inline bindKeys(Control.PAUSE, Options.P2_PAUSE);
				inline bindKeys(Control.RESET, Options.P2_RESET);
				inline bindKeys(Control.SWITCHMOD, Options.P2_SWITCHMOD);
				inline bindKeys(Control.DEBUG_RELOAD, Options.P2_DEBUG_RELOAD);
			case None: // nothing
			case Custom: // nothing
		}
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

	public function addGamepad(id:Int, ?buttonMap:Map<Control, Array<FlxGamepadInputID>>):Void
	{
		gamepadsAdded.push(id);

		#if (haxe >= "4.0.0")
		for (control => buttons in buttonMap)
			inline bindButtons(control, id, buttons);
		#else
		for (control in buttonMap.keys())
			bindButtons(control, id, buttonMap[control]);
		#end
	}

	inline function addGamepadLiteral(id:Int, ?buttonMap:Map<Control, Array<FlxGamepadInputID>>):Void
	{
		gamepadsAdded.push(id);

		#if (haxe >= "4.0.0")
		for (control => buttons in buttonMap)
			inline bindButtons(control, id, buttons);
		#else
		for (control in buttonMap.keys())
			bindButtons(control, id, buttonMap[control]);
		#end
	}

	public function removeGamepad(deviceID:Int = FlxInputDeviceID.ALL):Void
	{
		for (action in this.digitalActions)
		{
			var i = action.inputs.length;
			while (i-- > 0)
			{
				var input = action.inputs[i];
				if (input.device == GAMEPAD && (deviceID == FlxInputDeviceID.ALL || input.deviceID == deviceID))
					action.remove(input);
			}
		}

		gamepadsAdded.remove(deviceID);
	}

	public function addDefaultGamepad(id):Void
	{
		#if !switch
		addGamepadLiteral(id, [
			Control.ACCEPT => [A],
			Control.BACK => [B],
			Control.UP => [DPAD_UP, LEFT_STICK_DIGITAL_UP],
			Control.DOWN => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
			Control.LEFT => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
			Control.RIGHT => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
			Control.PAUSE => [START],
			Control.RESET => [Y]
		]);
		#else
		addGamepadLiteral(id, [
			//Swap A and B for switch
			Control.ACCEPT => [B],
			Control.BACK => [A],
			Control.UP => [DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP],
			Control.DOWN => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN],
			Control.LEFT => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT],
			Control.RIGHT => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT],
			Control.PAUSE => [START],
			//Swap Y and X for switch
			Control.RESET => [Y],
			Control.CHEAT => [X]
		]);
		#end
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public function bindButtons(control:Control, id, buttons)
	{
		#if (haxe >= "4.0.0")
		inline forEachBound(control, (action, state) -> addButtons(action, buttons, state, id));
		#else
		forEachBound(control, function(action, state) addButtons(action, buttons, state, id));
		#end
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public function unbindButtons(control:Control, gamepadID:Int, buttons)
	{
		#if (haxe >= "4.0.0")
		inline forEachBound(control, (action, _) -> removeButtons(action, gamepadID, buttons));
		#else
		forEachBound(control, function(action, _) removeButtons(action, gamepadID, buttons));
		#end
	}

	inline static function addButtons(action:FlxActionDigital, buttons:Array<FlxGamepadInputID>, state, id)
	{
		for (button in buttons)
			action.addGamepad(button, state, id);
	}

	static function removeButtons(action:FlxActionDigital, gamepadID:Int, buttons:Array<FlxGamepadInputID>)
	{
		var i = action.inputs.length;
		while (i-- > 0)
		{
			var input = action.inputs[i];
			if (isGamepad(input, gamepadID) && buttons.indexOf(cast input.inputID) != -1)
				action.remove(input);
		}
	}

	public function getInputsFor(control:Control, device:Device, ?list:Array<Int>):Array<Int>
	{
		if (list == null)
			list = [];

		switch (device)
		{
			case Keys:
				for (input in getActionFromControl(control).inputs)
				{
					if (input.device == KEYBOARD)
						list.push(input.inputID);
				}
			case Gamepad(id):
				for (input in getActionFromControl(control).inputs)
				{
					if (input.deviceID == id)
						list.push(input.inputID);
				}
		}
		return list;
	}

	public function removeDevice(device:Device)
	{
		switch (device)
		{
			case Keys:
				setKeyboardScheme(None);
			case Gamepad(id):
				removeGamepad(id);
		}
	}

	static function isDevice(input:FlxActionInput, device:Device)
	{
		return switch device
		{
			case Keys: input.device == KEYBOARD;
			case Gamepad(id): isGamepad(input, id);
		}
	}

	inline static function isGamepad(input:FlxActionInput, deviceID:Int)
	{
		return input.device == GAMEPAD && (deviceID == FlxInputDeviceID.ALL || input.deviceID == deviceID);
	}
}
