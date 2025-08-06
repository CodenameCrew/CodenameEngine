package funkin.backend.utils;

import funkin.options.PlayerSettings;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import funkin.backend.system.Controls;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import haxe.xml.Access;

class ControlsUtil {

	private static var storedCustomControls:Array<String> = [];

	public static function initCustomControl(controls:Controls, name:String) {
		if (controls.byName.exists(name)) return;

		controls.byName.set(name, new FlxActionDigital(name));
		controls.byName.set(name+"_P", new FlxActionDigital(name+"_P"));
		controls.byName.set(name+"_R", new FlxActionDigital(name+"_R"));
		storedCustomControls.push(name);
	}

	public static function addKeysToCustomControl(controls:Controls, name:String, keys:Array<FlxKey>) {
		if (!controls.byName.exists(name)) return;

		var pressed:FlxActionDigital = controls.byName.get(name);
		if (pressed != null) Controls.addKeys(pressed, keys, PRESSED);

		var justPressed:FlxActionDigital = controls.byName.get(name+"_P");
		if (justPressed != null) Controls.addKeys(justPressed, keys, JUST_PRESSED);

		var justReleased:FlxActionDigital = controls.byName.get(name+"_R");
		if (justReleased != null) Controls.addKeys(justReleased, keys, JUST_RELEASED);
	}

	public static function removeKeysFromCustomControl(controls:Controls, name:String, keys:Array<FlxKey>) {
		if (!controls.byName.exists(name)) return;

		var pressed:FlxActionDigital = controls.byName.get(name); 
		if (pressed != null) Controls.removeKeys(pressed, keys);

		var justPressed:FlxActionDigital = controls.byName.get(name+"_P"); 
		if (justPressed != null) Controls.removeKeys(justPressed, keys);

		var justReleased:FlxActionDigital = controls.byName.get(name+"_R"); 
		if (justReleased != null) Controls.removeKeys(justReleased, keys);
	}

	public static function resetCustomControls() {
		removeCustomControls(PlayerSettings.solo.controls);
		removeCustomControls(PlayerSettings.player1.controls);
		removeCustomControls(PlayerSettings.player2.controls);
		storedCustomControls = [];
	}

	private static inline function removeCustomControls(controls:Controls) {
		for (name in storedCustomControls) {
			var pressed:FlxActionDigital = controls.byName.get(name);
			if (pressed != null) pressed.destroy();

			var justPressed:FlxActionDigital = controls.byName.get(name+"_P");
			if (justPressed != null) justPressed.destroy();

			var justReleased:FlxActionDigital = controls.byName.get(name+"_R");
			if (justReleased != null) justReleased.destroy();

			controls.byName.remove(name);
			controls.byName.remove(name+"_P");
			controls.byName.remove(name+"_R");
		}
	}


	private static inline function checkControl(controls:Controls, name:String) {
		var control = getControl(controls, name);
		if (control != null) return control.check();
		return false;
	}

	public static inline function getControl(controls:Controls, name:String) : FlxActionDigital {
		return controls.byName.get(name);
	}

	public static inline function getJustPressed(controls:Controls, name:String) {
		return checkControl(controls, name + "_P");
	}
	public static inline function getJustReleased(controls:Controls, name:String) {
		return checkControl(controls, name + "_R");
	}
	public static inline function getPressed(controls:Controls, name:String) {
		return checkControl(controls, name);
	}

	public static function loadCustomControls() {
		var xmlPath = Paths.xml("config/controls");
		for(source in [funkin.backend.assets.AssetSource.SOURCE, funkin.backend.assets.AssetSource.MODS]) {
			if (Paths.assetsTree.existsSpecific(xmlPath, "TEXT", source)) {
				var access:Access = null;
				try {
					access = new Access(Xml.parse(Paths.assetsTree.getSpecificAsset(xmlPath, "TEXT", source)).firstElement());
				} catch(e) {
					Logs.trace('Error while parsing controls.xml: ${Std.string(e)}', ERROR);
				}

				if (access != null) {
					parseControlsXml(access);
				}
			}
		}
	}

	private static inline function parseControlsXml(xml:Access) {
		for (category in xml.elements) {
			for (control in category.elements) {
				if (!control.has.name) {
					continue;
				} 

				var name = control.getAtt("name");
				var saveName = control.getAtt("saveName").getDefault("");
				var defaultKeyP1 = control.getAtt("keyP1").getDefault("");
				var defaultKeyP2 = control.getAtt("keyP2").getDefault("");
				
				var keyP1:Null<FlxKey> = 0;
				var keyP2:Null<FlxKey> = 0;

				ControlsUtil.initCustomControl(PlayerSettings.solo.controls, name);
				ControlsUtil.initCustomControl(PlayerSettings.player1.controls, name);
				ControlsUtil.initCustomControl(PlayerSettings.player2.controls, name);

				if (saveName != "") {
					var p1:Null<FlxKey> = Reflect.getProperty(FlxG.save.data, "P1_"+saveName);
					var p2:Null<FlxKey> = Reflect.getProperty(FlxG.save.data, "P2_"+saveName);

					//check for save data (and load default if it doesnt exist)
					if (p1 != null) {
						keyP1 = p1;
					} else {
						if (defaultKeyP1 != "") keyP1 = FlxKey.fromString(defaultKeyP1);
						Reflect.setProperty(FlxG.save.data, "P1_"+saveName, keyP1);
					}
						
					if (p2 != null) {
						keyP2 = p2;
					} else {
						if (defaultKeyP2 != "") keyP2 = FlxKey.fromString(defaultKeyP2);
						Reflect.setProperty(FlxG.save.data, "P2_"+saveName, keyP2);
					}

				} else {
					//if no save data just load the default
					if (defaultKeyP1 != "") keyP1 = FlxKey.fromString(defaultKeyP1);
					if (defaultKeyP2 != "") keyP2 = FlxKey.fromString(defaultKeyP2);
				}

				ControlsUtil.addKeysToCustomControl(PlayerSettings.solo.controls, name, [keyP1, keyP2]);
				ControlsUtil.addKeysToCustomControl(PlayerSettings.player1.controls, name, [keyP1, 0]);
				ControlsUtil.addKeysToCustomControl(PlayerSettings.player2.controls, name, [0, keyP2]);
			}
		}
	}
}