package funkin.menus;

#if MOD_SUPPORT
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.assets.ModsFolder;
import funkin.backend.FunkinText;
import haxe.io.Path;
import sys.FileSystem;

class ModSwitchMenu extends MusicBeatSubstate {
	var disableConf:Map<String, Map<String, String>>;

	var title:FunkinText;
	var desc:FunkinText;
	var keyInfo:FunkinText;

	var mods:Array<String> = [];
	var addons:Array<String> = [];
	var modConf:Array<Map<String, Map<String, String>>> = [];
	// var addonConf:Array<Map<String, Map<String, String>>> = []; maybe, i'd just need to add a `folder` in ModsFolder.getModConfig()
	var alphabets:FlxTypedGroup<Alphabet>; // kept the name incase a script was here
	var addonObjs:FlxTypedGroup<Alphabet>;
	var addonChecks:FlxTypedGroup<FlxSprite>; // NOTE: maybe make a CheckboxObject, it kinda makes some things a mess here
	var queuedAddonsOff:Array<Bool> = [];

	var timer:Float = 0;
	var curSelected:Int = 0;
	var curAddon:Int = 0;
	var inAddons:Bool = false;

	var subCam:FlxCamera;

	var checkOffsets:Map<String, FlxPoint> = [
		"unchecked" => FlxPoint.get(0, -70),
		"checked" => FlxPoint.get(23, -32),
		"unchecking" => FlxPoint.get(25, -12),
		"checking" => FlxPoint.get(35, 29)
	];

	public override function create() {
		super.create();

		disableConf = [
			"Common" => [
				"NAME" => TU.translate("mods.disableMods")
			]
		];

		camera = subCam = new FlxCamera();
		subCam.bgColor = 0;
		FlxG.cameras.add(subCam, false);

		var bg = new FlxSprite(0, 0).makeSolid(FlxG.width, FlxG.height, 0xFF000000);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);

		bg.alpha = 0;
		FlxTween.tween(bg, {alpha: 0.5}, 0.25, {ease: FlxEase.cubeOut});

		mods = ModsFolder.getModsList({
		    descending: false,
			mode: CLEAN,
		});
		mods.push(null);

		alphabets = new FlxTypedGroup<Alphabet>();
		for(mod in mods) {
			var conf = mod != null ? ModsFolder.getModConfig(mod) : disableConf;
			modConf.push(conf);

			var name = (conf.exists("Common") && conf["Common"].exists("NAME")) ? conf["Common"].get("NAME") : mod;
			if (name == "YOUR MOD NAME HERE")
				name = mod;

			var a = new Alphabet(0, 0, name, "bold");
			if(mod == ModsFolder.currentModFolder) {
				a.effects = [new funkin.menus.ui.effects.ColorWaveEffect(0xFFFFFFFF, 0xFF00FF00, 10)];
				a.effects[0].speed = 10;
			}
			a.isMenuItem = true;
			a.scrollFactor.set();
			alphabets.add(a);
		}
		add(alphabets);

		addons = FileSystem.exists(ModsFolder.addonsPath) && FileSystem.isDirectory(ModsFolder.addonsPath) ? FileSystem.readDirectory(ModsFolder.addonsPath) : [];

		addonObjs = new FlxTypedGroup<Alphabet>();
		addonChecks = new FlxTypedGroup<FlxSprite>();
		for(i in 0...addons.length) {
			var idx = addons.length - 1 - i; // reverse it for removal safety
			var mod = addons[idx];
			if (!FileSystem.isDirectory(ModsFolder.addonsPath + mod) && !Flags.ALLOWED_ZIP_EXTENSIONS.contains(Path.extension(mod))) {
				addons.splice(idx, 1);
				continue;
			}

			var isOff = Options.disabledAddons.contains(mod);
			queuedAddonsOff.insert(0, isOff);

			var name = Path.withoutExtension(mod);
			addons[idx] = name;
			if (name.startsWith("[LOW]") || name.startsWith("[HIGH]"))
				name = name.substring(name.lastIndexOf("]") + 1);

			var a = new Alphabet(0, 0, name, "bold");
			a.isMenuItem = true;
			a.scrollFactor.set();
			a.itemSlide = -20;
			addonObjs.insert(0, a);

			var checkbox = new FlxSprite();
			checkbox.frames = Paths.getFrames('menus/options/checkboxThingie');
			checkbox.animation.addByPrefix("unchecked", "Check Box unselected0", 24);
			checkbox.animation.addByPrefix("checked", "Check Box Selected Static0", 24);
			checkbox.animation.addByPrefix("unchecking", "Check Box deselect animation0", 24, false);
			checkbox.animation.addByPrefix("checking", "Check Box selecting animation0", 24, false);
			checkbox.animation.play(isOff ? "unchecked" : "checked");
			checkbox.antialiasing = true;
			checkbox.scale.set(0.75, 0.75);
			checkbox.updateHitbox();
			addonChecks.insert(0, checkbox);

			applyAddonOffset(a, checkbox, 0);
		}
		add(addonObjs);
		add(addonChecks);

		title = new FunkinText(4, 4, FlxG.width - 8, TU.translate("mods.modsTitle"), 32);
		title.borderSize = 1.25;
		add(title);
		desc = new FunkinText(4, title.y + title.height, FlxG.width - 8, getDescription(modConf[curSelected]), 16);
		add(desc);

		keyInfo = new FunkinText(FlxG.width - 4, title.y + title.height * 0.5, 0, '[${CoolUtil.keyToString(Options.SOLO_CHANGE_MODE[0])}] >>>', 24);
		keyInfo.x -= keyInfo.width;
		keyInfo.y -= keyInfo.height * 0.5;
		keyInfo.visible = addons.length > 0;
		add(keyInfo);

		changeSelection(0, true);
		if (addons.length > 0)
			changeAddon(0, true);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		timer += elapsed;

		var keyOffset = Math.abs(Math.sin(timer * 1.5 * Math.PI)) * 15;
		keyInfo.x = inAddons ? 4 + keyOffset : FlxG.width - 4 - keyInfo.width - keyOffset;

		var targetFramerateY:Float = keyInfo.y + keyInfo.height;
		if (!inAddons)
			targetFramerateY = ((desc.text != "") ? desc.y + desc.height : title.y + title.height);
		Framerate.offset.y = CoolUtil.fpsLerp(Framerate.offset.y, targetFramerateY, 0.35);

		var scrollChange = (controls.DOWN_P ? 1 : 0) + (controls.UP_P ? -1 : 0) - FlxG.mouse.wheel;
		(inAddons ? addonControls : regularControls)(scrollChange);

		for (i => check in addonChecks.members) {
			var obj = addonObjs.members[i];

			check.alpha = obj.alpha;
			check.setPosition(
				obj.x + obj.width + 26, // so who decided on 26
				obj.y - 50
			);

			if (check.animation.curAnim.finished) switch(check.animation.curAnim.name) {
				case "unchecking": check.animation.play("unchecked", true);
				case "checking": check.animation.play("checked", true);
			}

			var offset:FlxPoint = checkOffsets[check.animation.name];
			if (offset != null)
				check.frameOffset.copyFrom(offset);
		}
	}

	function regularControls(scrollChange:Int) {
		changeSelection(scrollChange);

		if (controls.ACCEPT) {
			var newAddonsOff:Array<String> = [];
			for (i => isOff in queuedAddonsOff) {
				if (isOff)
					newAddonsOff.push(addons[i]);
			}
			Options.disabledAddons = newAddonsOff;

			ModsFolder.switchMod(mods[curSelected]);
			close();
		}

		if (controls.BACK) {
			close();
			Framerate.offset.y = 0;
		} else if (controls.CHANGE_MODE && addons.length > 0)
			toggleTab(false);
	}
	function addonControls(scrollChange:Int) {
		changeAddon(scrollChange);

		if (controls.ACCEPT) {
			queuedAddonsOff[curAddon] = !queuedAddonsOff[curAddon];
			addonChecks.members[curAddon].animation.play(queuedAddonsOff[curAddon] ? "unchecking" : "checking", true);

			desc.text = addonsChanged() ? TU.translate("mods.addonsChanged") : "";
			CoolUtil.playMenuSFX(queuedAddonsOff[curAddon] ? UNCHECKED : CHECKED);
		}

		if (controls.CHANGE_MODE || controls.BACK)
			toggleTab(controls.BACK);
	}

	public function changeSelection(change:Int, force:Bool = false) {
		if (change == 0 && !force) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, alphabets.length - 1);

		CoolUtil.playMenuSFX(SCROLL, 0.7);

		for(k => alphabet in alphabets.members) {
			alphabet.alpha = 0.6;
			alphabet.targetY = k - curSelected;
		}
		alphabets.members[curSelected].alpha = 1;

		desc.text = getDescription(modConf[curSelected]);
	}
	public function changeAddon(change:Int, force:Bool = false) {
		if (change == 0 && !force) return;

		curAddon = FlxMath.wrap(curAddon + change, 0, addonObjs.length - 1);

		if (change != 0)
			CoolUtil.playMenuSFX(SCROLL, 0.7);

		for(k => alphabet in addonObjs.members) {
			alphabet.alpha = 0.6;
			alphabet.targetY = k - curAddon;
		}
		addonObjs.members[curAddon].alpha = 1;
	}

	public function toggleTab(playCancel:Bool) {
		inAddons = !inAddons;
		var offset = inAddons ? FlxG.width * -2 : 0;

		for (item in alphabets.members)
			item.menuOffset.x = offset;
		for (i in 0...addonObjs.length)
			applyAddonOffset(addonObjs.members[i], addonChecks.members[i], offset);

		if (inAddons) {
			title.alignment = desc.alignment = RIGHT;
			
			title.text = TU.translate("mods.addonsTitle");
			desc.text = addonsChanged() ? TU.translate("mods.addonsChanged") : "";
		} else {
			title.alignment = desc.alignment = LEFT;

			title.text = TU.translate("mods.modsTitle");
			desc.text = getDescription(modConf[curSelected]);
		}

		keyInfo.text = '[${CoolUtil.keyToString(Options.SOLO_CHANGE_MODE[0])}]';
		keyInfo.text = inAddons ? "<<< " + keyInfo.text : keyInfo.text + " >>>";
		CoolUtil.playMenuSFX(playCancel ? CANCEL : SCROLL, 0.7);
	}

	inline function getDescription(conf:Map<String, Map<String, String>>) {
		if (!conf.exists("Common")) return "";
		var common = conf.get("Common");
		var desc = common.exists("DESCRIPTION") ? common.get("DESCRIPTION").trim() : "";

		return (desc != "YOUR MOD DESCRIPTION HERE") ? desc : "";
	}
	function addonsChanged() {
		for (i => isOff in queuedAddonsOff) {
			if (isOff != Options.disabledAddons.contains(addons[i]))
				return true;
		}

		return false;
	}

	inline function applyAddonOffset(item:Alphabet, checkbox:FlxSprite, additionalOffset:Float)
		item.menuOffset.x = FlxG.width * 3 - item.width - checkbox.width - 210 + additionalOffset; // (* 2 from the offset, * 1 for right aligning, - 180 for flipping the + 90 combined with a 30 offset)

	override function destroy() {
		super.destroy();

		if (FlxG.cameras.list.contains(subCam))
			FlxG.cameras.remove(subCam);

		for (point in checkOffsets)
			point.put();
	}
}
#end
