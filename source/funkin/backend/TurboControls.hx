package funkin.backend;

import flixel.input.actions.FlxAction;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput.FlxInputState;
import flixel.FlxBasic;

import funkin.backend.system.Controls;
import funkin.options.PlayerSettings;

class TurboBasic extends FlxBasic {
	public static var DEFAULT_DELAY:Float = 0.4;
	public static var DEFAULT_INTERVAL:Float = 1 / 18;

	public var delay:Float;
	public var interval:Float;
	public var activated(default, null):Bool;
	public var pressed(get, never):Bool; function get_pressed() return false;
	public var allPress:Bool;

	var time:Float = 0;

	public function new(?delay:Float, ?interval:Float, allPress = false) {
		super();
		this.delay = delay != null ? delay : DEFAULT_DELAY;
		this.interval = interval != null ? interval : DEFAULT_INTERVAL;
		this.allPress = allPress;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (pressed) {
			if (time == 0) activated = true;
			else if (activated = (time >= delay + interval)) time -= interval;
			time += elapsed;
		}
		else {
			activated = false;
			time = 0;
		}
	}
}

class TurboControls extends TurboBasic {
	public var controlsInstance:Controls;
	public var controls:Array<Control>;
	public function new(controls:Array<Control>, ?controlsInstance:Controls, ?delay:Float, ?interval:Float, ?allPress:Bool) {
		super(delay, interval, allPress);
		this.controls = controls;
		this.controlsInstance = controlsInstance != null ? controlsInstance : PlayerSettings.solo.controls;
	}

	override function get_pressed() {
		if (allPress) {
			for (control in controls) if (!controlsInstance.getActionFromControl(control).check()) return false;
		}
		else {
			for (control in controls) if (controlsInstance.getActionFromControl(control).check()) return true;
		}
		return allPress;
	}
}

class TurboActions extends TurboBasic {
	public var actions:Array<FlxAction>;
	public function new(actions:Array<FlxAction>, ?delay:Float, ?interval:Float, ?allPress:Bool) {
		super(delay, interval, allPress);
		this.actions = actions;
	}

	override function get_pressed() {
		if (allPress) {
			for (action in actions) if (!action.check()) return false;
		}
		else {
			for (action in actions) if (action.check()) return true;
		}
		return allPress;
	}
}

class TurboKeys extends TurboBasic {
	public var keys:Array<FlxKey>;
	public function new(keys:Array<FlxKey>, ?delay:Float, ?interval:Float, ?allPress:Bool) {
		super(delay, interval, allPress);
		this.keys = keys;
	}

	override function get_pressed() {
		if (allPress) {
			for (key in keys) if (!FlxG.keys.checkStatus(key, PRESSED)) return false;
		}
		else {
			for (key in keys) if (FlxG.keys.checkStatus(key, PRESSED)) return true;
		}
		return allPress;
	}
}

class TurboButtons extends TurboBasic {
	public var inputs:Array<FlxGamepadInputID>;
	public var gamepad:FlxGamepad;
	public function new(inputs:Array<FlxGamepadInputID>, ?gamepad:FlxGamepad, ?delay:Float, ?interval:Float, ?allPress:Bool) {
		super(delay, interval, allPress);
		this.inputs = inputs;
		this.gamepad = gamepad != null ? gamepad : FlxG.gamepads.firstActive;
	}

	override function get_pressed() {
		if (allPress) {
			for (input in inputs) if (!gamepad.checkStatus(input, PRESSED)) return false;
		}
		else {
			for (input in inputs) if (gamepad.checkStatus(input, PRESSED)) return true;
		}
		return allPress;
	}
}