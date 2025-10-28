package funkin.options.keybinds;

import flixel.util.FlxColor;
import haxe.xml.Access;
using StringTools;


class KeybindsOptions extends MusicBeatSubstate {
	public static var instance:KeybindsOptions;

	public function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate(id, args);

	public var settingCam:FlxCamera;

	public var p2Selected:Bool = false;
	public var curSelected:Int = 0;
	public var canSelect:Bool = true;
	public var alphabets:FlxTypedGroup<KeybindSetting>;
	public var bg:FlxSprite;
	public var coloredBG:FlxSprite;
	public var noteColors:Array<FlxColor> = [
		0xFFC24B99,
		0xFF00FFFF,
		0xFF12FA05,
		0xFFF9393F
	];
	public var camFollow:FlxObject = new FlxObject(0, 0, 2, 2);

	public var categories:Array<ControlsCategory> = [];
	public static var defaultCategories:Array<ControlsCategory> = [
		{
			name: "category.notes",
			settings: [
				{
					sparrowIcon: "game/notes/default",
					sparrowAnim: "purple0",
					name: "left",
					control: 'NOTE_LEFT'
				},
				{
					sparrowIcon: "game/notes/default",
					sparrowAnim: "blue0",
					name: "down",
					control: 'NOTE_DOWN'
				},
				{
					sparrowIcon: "game/notes/default",
					sparrowAnim: "green0",
					name: "up",
					control: 'NOTE_UP'
				},
				{
					sparrowIcon: "game/notes/default",
					sparrowAnim: "red0",
					name: "right",
					control: 'NOTE_RIGHT'
				},
			]
		},
		{
			name: "category.ui",
			settings: [
				{
					name: "left",
					control: 'LEFT'
				},
				{
					name: "down",
					control: 'DOWN'
				},
				{
					name: "up",
					control: 'UP'
				},
				{
					name: "right",
					control: 'RIGHT'
				},
				{
					name: "ui.accept",
					control: 'ACCEPT'
				},
				{
					name: "ui.back",
					control: 'BACK'
				},
				{
					name: "ui.reset",
					control: 'RESET'
				},
				{
					name: "ui.pause",
					control: 'PAUSE'
				},
				{
					name: "ui.changeMode",
					control: 'CHANGE_MODE'
				},
			]
		},
		{
			name: "category.volume",
			settings: [
				{
					name: "volume.up",
					control: 'VOLUME_UP'
				},
				{
					name: "volume.down",
					control: 'VOLUME_DOWN'
				},
				{
					name: "volume.mute",
					control: 'VOLUME_MUTE'
				},
			]
		},
		{
			name: "category.engine",
			settings: [
				{
					name: "engine.switchMod",
					control: 'SWITCHMOD'
				},
				{
					name: "engine.fpsCounter",
					control: 'FPS_COUNTER'
				},
			]
		},
		{
			name: "category.developer",
			devModeOnly: true,
			settings: [
				{
					name: "developer.devMenus",
					control: 'DEV_ACCESS'
				},
				{
					name: "developer.openConsole",
					control: 'DEV_CONSOLE'
				},
				{
					name: "developer.reloadState",
					control: 'DEV_RELOAD'
				},
			]
		}
	];

	public var isSubState:Bool = false;

	public override function create() {
		super.create();
		instance = this;

		isSubState = FlxG.state != this;
		alphabets = new FlxTypedGroup<KeybindSetting>();
		bg = new FlxSprite(-80).loadAnimatedGraphic(Paths.image(isSubState ? 'menus/menuTransparent' : 'menus/menuBGBlue'));
		coloredBG = new FlxSprite(-80).loadAnimatedGraphic(Paths.image('menus/menuDesat'));
		for(bg in [bg, coloredBG]) {
			bg.scrollFactor.set();
			bg.scale.set(1.15, 1.15);
			bg.updateHitbox();
			bg.screenCenter();
			bg.antialiasing = true;
			add(bg);
		}
		coloredBG.alpha = 0;

		if (isSubState) {
			// is substate, opened from pause menu
			if (settingCam == null) {
				settingCam = new FlxCamera();
				settingCam.bgColor = 0xAA000000;
				FlxG.cameras.add(settingCam, false);
			}
			cameras = [settingCam];
			bg.alpha = 0;
			settingCam.follow(camFollow, LOCKON, 0.125);
		} else {
			FlxG.camera.follow(camFollow, LOCKON, 0.125);
		}

		for (category in defaultCategories) categories.push(category);

		var customCategories = loadCustomCategories();
		for (i in customCategories) categories.push(i);

		var k:Int = 0;
		for (category in categories) {
			if (category.devModeOnly && !Options.devMode) continue;

			k++;
			var translationPrefix:String = (category.custom != null) ? '' : 'KeybindsOptions.';

			var categoryToTranslate:String = translationPrefix + category.name;
			var translatedCategory:String = TU.exists(categoryToTranslate) ? translate(categoryToTranslate) : category.name;
			var title = new Alphabet(0, k * 75, translatedCategory, "bold");
			title.screenCenter(X);
			add(title);

			k++;
			for (e in category.settings) {
				var sparrowIcon:String = null;
				var sparrowAnim:String = null;
				if (e.sparrowIcon != null) sparrowIcon = e.sparrowIcon;
				if (e.sparrowAnim != null) sparrowAnim = e.sparrowAnim;

				var nameToTranslate:String = translationPrefix + e.name;
				var translatedName:String = TU.exists(nameToTranslate) ? translate(nameToTranslate) : e.name;
				var text = new KeybindSetting(100, k * 75, translatedName, e.control, sparrowIcon, sparrowAnim, e.custom == null ? false : e.custom);
				if (!isSubState)
					text.bind1.color = text.bind2.color = FlxColor.BLACK;
				alphabets.add(text);
				k++;
			}
		}
		add(alphabets);
		add(camFollow);

		FlxG.sound.volumeUpKeys = [];
		FlxG.sound.volumeDownKeys = [];
		FlxG.sound.muteKeys = [];
	}

	public override function destroy() {
		super.destroy();
		if (settingCam != null) FlxG.cameras.remove(settingCam);
		instance = null;
	}

	var skipThisFrame:Bool = true;

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (isSubState) bg.alpha = lerp(bg.alpha, 0.1, 0.125);
		else {
			if (curSelected < 4) {
				if (coloredBG.alpha == 0)
					coloredBG.color = noteColors[curSelected];
				else
					coloredBG.color = CoolUtil.lerpColor(coloredBG.color, noteColors[curSelected], 0.0625);

				coloredBG.alpha = lerp(coloredBG.alpha, 1, 0.0625);
			} else
				coloredBG.alpha = lerp(coloredBG.alpha, 0, 0.0625);
		}

		if (canSelect) {
			changeSelection((controls.UP_P ? -1 : 0) + (controls.DOWN_P ? 1 : 0));

			if (controls.BACK) {
				if (isSubState) close();
				else {
					MusicBeatState.skipTransIn = true;
					FlxG.switchState(new OptionsMenu());
				}
				ControlsUtil.resetCustomControls();
				Options.applyKeybinds();
				ControlsUtil.loadCustomControls();
				Options.save();
				return;
			}

			if (controls.ACCEPT && !skipThisFrame) {
				if (alphabets.members[curSelected] != null) {
					canSelect = false;
					CoolUtil.playMenuSFX(CONFIRM);
					alphabets.members[curSelected].changeKeybind(function() {
						canSelect = true;
					}, function() {
						canSelect = true;
					}, p2Selected);
				}
				return;
			}

			if (controls.LEFT_P || controls.RIGHT_P) {
				if (alphabets.members[curSelected] != null) {
					CoolUtil.playMenuSFX(SCROLL, 0.7);
					alphabets.members[curSelected].p2Selected = (p2Selected = !p2Selected);
				}
			}
		}
		super.update(elapsed);
		skipThisFrame = false;

	}

	public function changeSelection(change:Int) {
		if (change != 0) CoolUtil.playMenuSFX(SCROLL, 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, alphabets.length-1);
		alphabets.forEach(function(e) {
			e.alpha = 0.45;
		});
		if (alphabets.members[curSelected] != null) {
			var alphabet = alphabets.members[curSelected];
			alphabet.p2Selected = p2Selected;
			alphabet.alpha = 1;
			var minH = FlxG.height / 2;
			var maxH = alphabets.members[alphabets.length-1].y + alphabets.members[alphabets.length-1].height - (FlxG.height / 2);
			if (minH < maxH)
				camFollow.setPosition(FlxG.width / 2, CoolUtil.bound(alphabet.y + (alphabet.height / 2) - 35, minH, maxH));
			else
				camFollow.setPosition(FlxG.width / 2, FlxG.height / 2);
		}
	}

	public function loadCustomCategories() {
		var customCategories:Array<ControlsCategory> = [];

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
					for (category in access.elements) {
						if (!category.has.name) continue;

						var cat:ControlsCategory = {
							name: category.getAtt("name"),
							custom: true,
							settings: []
						};

						for (control in category.elements) {
							if (control.has.menuName && control.has.saveName) {
								cat.settings.push({
									name: control.getAtt("menuName"),
									control: control.getAtt("saveName"),
									custom: true,
									sparrowIcon: control.getAtt("menuIcon").getDefault(null),
									sparrowAnim: control.getAtt("menuAnim").getDefault(null)
								});
							}
						}

						customCategories.push(cat);
					}
				}
			}
		}
		return customCategories;
	}
}

typedef KeybindSettingData = {
	var name:String;
	var control:String;
	var ?custom:Bool;
	var ?sparrowIcon:String;
	var ?sparrowAnim:String;
}

typedef ControlsCategory = {
	var name:String;
	var settings:Array<KeybindSettingData>;
	var ?devModeOnly:Bool;
	var ?custom:Bool;
}