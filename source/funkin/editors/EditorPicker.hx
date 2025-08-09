package funkin.editors;

import flixel.effects.FlxFlicker;
import flixel.math.FlxPoint;

class EditorPicker extends MusicBeatSubstate {
	public var bg:FlxSprite;

	// Name is for backwards compatibility, don't use it, use id instead
	public var options:Array<Editor> = [
		{
			name: "Chart Editor",
			id: "chart",
			state: funkin.editors.charter.CharterSelection
		},
		{
			name: "Character Editor",
			id: "character",
			state: funkin.editors.character.CharacterSelection
		},
		{
			name: "Stage Editor",
			id: "stage",
			state: funkin.editors.stage.StageSelection
		},
		{
			name: "Alphabet Editor",
			id: "alphabet",
			state: funkin.editors.alphabet.AlphabetSelection
		},
		#if (debug || debug_ui)
		{
			name: "UI Debug State",
			id: "uiDebug",
			state: UIDebugState
		},
		#end
		{
			name: "Wiki",
			id: "wiki",
			state: null,
			onClick: function() {
				CoolUtil.openURL(Flags.URL_WIKI);
			}
		}
	];

	public var sprites:Array<EditorPickerOption> = [];

	public var curSelected:Int = 0;

	public var subCam:FlxCamera;
	public var oldMousePos:FlxPoint = FlxPoint.get();
	public var curMousePos:FlxPoint = FlxPoint.get();

	public var optionHeight:Float = 0;

	public var selected:Bool = false;

	public var camVelocity:Float = 0;

	public override function create() {
		super.create();

		camera = subCam = new FlxCamera();
		subCam.bgColor = 0;
		FlxG.cameras.add(subCam, false);

		bg = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		bg.scrollFactor.set();
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		add(bg);

		optionHeight = FlxG.height / options.length;
		for(k=>o in options) {
			var visualName = (o.id != null) ? TU.translate("editor." + o.id + ".name") : o.name;
			var spr = new EditorPickerOption(visualName, o.id, optionHeight);
			spr.y = k * optionHeight;
			add(spr);
			sprites.push(spr);
		}
		sprites[0].selected = true;

		FlxG.mouse.getScreenPosition(subCam, oldMousePos);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		bg.alpha = CoolUtil.fpsLerp(bg.alpha, selected ? 1 : 0.5, 0.25);

		if (selected) {
			camVelocity += FlxG.width * elapsed * 2;
			subCam.scroll.x += camVelocity * elapsed;
			return;
		}
		changeSelection(-FlxG.mouse.wheel + (controls.UP_P ? -1 : 0) + (controls.DOWN_P ? 1 : 0));

		FlxG.mouse.getScreenPosition(subCam, curMousePos);
		if (curMousePos.x != oldMousePos.x || curMousePos.y != oldMousePos.y) {
			oldMousePos.set(curMousePos.x, curMousePos.y);
			curSelected = -1;
			changeSelection(Std.int(curMousePos.y / optionHeight)+1);
		}

		if (controls.ACCEPT || FlxG.mouse.justReleased) {
			if(options[curSelected].onClick != null)
				options[curSelected].onClick();
			else if (options[curSelected].state != null) {
				selected = true;
				CoolUtil.playMenuSFX(CONFIRM);

				MusicBeatState.skipTransIn = true;
				MusicBeatState.skipTransOut = true;

				if (FlxG.sound.music != null)
					FlxG.sound.music.fadeOut(0.7, 0, function(n) {
						FlxG.sound.music.stop();
					});

				sprites[curSelected].flicker(function() {
					subCam.fade(0xFF000000, 0.25, false, function() {
						FlxG.switchState(Type.createInstance(options[curSelected].state, []));
					});
				});
			} else {
				CoolUtil.openURL(Flags.URL_EDITOR_FALLBACK);
			}

		}
		if (controls.BACK)
			close();
	}

	override function destroy() {
		super.destroy();

		oldMousePos.put();
		curMousePos.put();

		if (FlxG.cameras.list.contains(subCam))
			FlxG.cameras.remove(subCam);
	}

	public function changeSelection(change:Int) {
		if (change == 0) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, sprites.length-1);

		for(o in sprites)
			o.selected = false;
		sprites[curSelected].selected = true;
	}
}

typedef Editor = {
	var name:String;
	var id:String;
	var state:Class<MusicBeatState>;
	var ?onClick:Void->Void;
}

class EditorPickerOption extends FlxTypedSpriteGroup<FlxSprite> {
	public var iconSpr:FlxSprite;
	public var label:Alphabet;

	public var selectionBG:FlxSprite;

	public var selected:Bool = false;

	public var selectionLerp:Float = 0;

	public var iconRotationCycle:Float = 0;
	public function new(name:String, iconID:String, height:Float) {
		super();

		FlxG.mouse.visible = true;
		iconSpr = new FlxSprite();
		if(iconID != null)
			iconSpr.loadGraphic(Paths.image('editors/icons/$iconID'));
		else
			iconSpr.exists = false;
		iconSpr.antialiasing = true;
		iconSpr.setUnstretchedGraphicSize(110, 110, false);
		iconSpr.x = 25 + ((height - iconSpr.width) / 2);
		iconSpr.y = (height - iconSpr.height) / 2;

		label = new Alphabet(25 + iconSpr.width + 25, 0, name, "bold");
		label.y = (height - label.height) / 2;

		selectionBG = new FlxSprite().makeGraphic(1, 1, -1);
		selectionBG.scale.set(FlxG.width, height);
		selectionBG.updateHitbox();
		selectionBG.alpha = 0;

		add(selectionBG);
		add(iconSpr);
		add(label);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		iconRotationCycle += elapsed;

		selectionLerp = CoolUtil.fpsLerp(selectionLerp, selected ? 1 : 0, 0.25);

		selectionBG.alpha = (iconSpr.alpha = FlxEase.cubeOut(selectionLerp)) * 0.5;
		selectionBG.x = FlxMath.lerp(-FlxG.width, 0, selectionLerp);

		label.x = FlxMath.lerp(10, 25 + iconSpr.width + 25, selectionLerp);
		iconSpr.x = label.x - 25 - iconSpr.width;
		iconSpr.angle = Math.sin(iconRotationCycle * 0.5) * 5;

		scrollFactor.set(FlxMath.lerp(1, 0.1, selectionLerp), 0);
		selectionBG.scrollFactor.set(0, 0);
	}

	public override function destroy() {
		super.destroy();
	}

	public function flicker(callback:Void->Void) {
		FlxFlicker.flicker(label, 0.5, Options.flashingMenu ? 0.06 : 0.15, false, false, function(t) {
			callback();
		});
	}
}
