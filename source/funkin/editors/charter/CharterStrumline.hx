package funkin.editors.charter;

import flixel.group.FlxSpriteGroup;
import funkin.game.Character;
import funkin.editors.ui.UITopMenu.UITopMenuButton;
import funkin.game.HealthIcon;
import funkin.backend.chart.ChartData.ChartStrumLine;
import funkin.backend.shaders.CustomShader;
import flixel.sound.FlxSound;

class CharterStrumline extends UISprite {
	public var strumLine:ChartStrumLine;
	public var hitsounds:Bool = true;

	public var draggingSprite:UISprite;
	public var healthIcons:FlxSpriteGroup;
	public var button:CharterStrumlineOptions;

	public var draggable:Bool = false;
	public var dragging:Bool = false;

	public var curMenu:UIContextMenu = null;

	public var vocals:FlxSound;

	public var selectedWaveform(default, set):Int = -1;
	public function set_selectedWaveform(value:Int):Int {
		if (value == -1) waveformShader = null;
		else {
			var shaderName:String = Charter.waveformHandler.waveformList[value];
			waveformShader = Charter.waveformHandler.waveShaders.get(shaderName);
		}
		return selectedWaveform = value;
	}
	public var waveformShader:CustomShader; 

	public function new(strumLine:ChartStrumLine) {
		super();
		this.strumLine = strumLine;

		scrollFactor.set(1, 0);
		alpha = 0;

		if(strumLine.visible == null) strumLine.visible = true;

		healthIcons = new FlxSpriteGroup(x, y);
		members.push(healthIcons);

		draggingSprite = new UISprite();
		draggingSprite.loadGraphic(Paths.image("editors/charter/strumline-drag"));
		draggingSprite.alpha = 0.4;
		draggingSprite.y = 9;
		draggingSprite.antialiasing = true;
		draggingSprite.cursor = BUTTON;
		members.push(draggingSprite);

		button = new CharterStrumlineOptions(this);
		members.push(button);

		updateInfo();

		selectedWaveform = -1;
	}

	private var __healthYOffset:Float = 0;
	private var __draggingYOffset:Float = 0;

	public override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.K) draggable = !draggable;

		healthIcons.follow(this, ((40 * 4) - healthIcons.width) / 2, 7 + (__healthYOffset = FlxMath.lerp(__healthYOffset, draggable ? 8 : 0, 1/20)));

		draggingSprite.selectable = draggable;
		UIState.state.updateSpriteRect(draggingSprite);

		var dragScale:Float = FlxMath.lerp(draggingSprite.scale.x, draggable ? 1 : 0.8, 1/16);
		draggingSprite.scale.set(dragScale, dragScale);
		draggingSprite.updateHitbox();

		draggingSprite.follow(this, (160/2) - (draggingSprite.width/2), 6 + (__draggingYOffset = FlxMath.lerp(__draggingYOffset, draggable ? 3 : 0, 1/12)));
		var fullAlpha:Float = UIState.state.isOverlapping(draggingSprite, @:privateAccess draggingSprite.__rect) || dragging ? 0.9 : 0.35;
		draggingSprite.alpha = FlxMath.lerp(draggingSprite.alpha, draggable ? fullAlpha : 0, 1/12);
		button.follow(this, 0, 95);

		super.update(elapsed);
	}

	public function updateInfo() {
		var icons = strumLine.characters != null ? strumLine.characters : [];

		healthIcons.clear();

		for (i=>icon in icons) {
			var healthIcon = new HealthIcon(Character.getIconFromCharName(icon));
			var newScale = 0.6 - (icons.length / 20);
			var size = Std.int(150 * newScale);
			healthIcon.setUnstretchedGraphicSize(size, size, true);
			healthIcon.updateHitbox();
			healthIcon.x = FlxMath.lerp(0, icons.length * 20, (icons.length-1 != 0 ? i / (icons.length-1) : 0));
			healthIcon.y = draggable ? 14 : 7;
			healthIcon.alpha = strumLine.visible ? 1 : 0.4;
			healthIcons.add(healthIcon);
		}

		vocals = null;
		vocals = strumLine.vocalsSuffix.length > 0 ? FlxG.sound.load(Paths.voices(PlayState.SONG.meta.name, PlayState.difficulty, strumLine.vocalsSuffix)) : new FlxSound();
		vocals.group = FlxG.sound.defaultMusicGroup;
	}
}

class CharterStrumlineOptions extends UITopMenuButton {
	var strLine:CharterStrumline;
	public function new(parent:CharterStrumline) {
		super(0, 95, null, "Options ↓", []);
		strLine = parent;
		bWidth = 40 * 4;
		this.label.fieldWidth = bWidth;
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		alpha = FlxMath.lerp(1/20, 1, alpha); // so that instead of 0% it is 33% visible
	}

	public override function openContextMenu() {
		contextMenu = [
			{
				label: "Hitsounds",
				onSelect: function(_) {
					strLine.hitsounds = !strLine.hitsounds;
				},
				icon: strLine.hitsounds ? 1 : 0
			},
			{
				label: "Mute Vocals",
				onSelect: function(_) {
					strLine.vocals.volume = strLine.vocals.volume > 0 ? 0 : 1;
				},
				icon: strLine.vocals.volume > 0 ? 0 : 1
			},
			null,
			{
				label: "Edit",
				onSelect: function (_) {
					Charter.instance.editStrumline(strLine.strumLine);
				},
				color: 0xFF959829,
				icon: 4
			},
			{
				label: "Delete",
				onSelect: function (_) {
					Charter.instance.deleteStrumlineFromData(strLine.strumLine);
				},
				color: 0xFF982929,
				icon: 3
			}
		];

		contextMenu.insert(0, {
			label: "No Waveform",
			onSelect: function(_) {strLine.selectedWaveform = -1;},
			icon: strLine.selectedWaveform == -1 ? 1 : 0
		});

		for (i => name in Charter.waveformHandler.waveformList)
			contextMenu.insert(1+i, {
				label: name,
				onSelect: function(_) {strLine.selectedWaveform = i;},
				icon: strLine.selectedWaveform == i ? 6 : 5
			});

		contextMenu.insert(1+Charter.waveformHandler.waveformList.length, null);

		super.openContextMenu();
	}
}