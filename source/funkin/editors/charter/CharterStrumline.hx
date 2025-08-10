package funkin.editors.charter;

import flixel.group.FlxSpriteGroup;
import flixel.sound.FlxSound;
import funkin.backend.chart.ChartData.ChartStrumLine;
import funkin.backend.shaders.CustomShader;
import funkin.editors.ui.UITopMenu.UITopMenuButton;
import funkin.game.Character;
import funkin.game.HealthIcon;

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

	public var keyCount:Int = 4;
	public var startingID(get, null):Int;
	private var __startingID:Int = -1;
	public function get_startingID():Int {
		if (__startingID != -1) return __startingID;

		var index = Charter.instance.strumLines.members.indexOf(this);
		if (index < 1) return __startingID = 0; //-1 or 0

		var v:Int = 0;
		for (i in 0...index) v += Charter.instance.strumLines.members[i].keyCount;
		return __startingID = v;
	}

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

		var icons = strumLine.characters != null ? strumLine.characters : [];

		keyCount = strumLine.keyCount != null ? strumLine.keyCount : 4;

		healthIcons = new FlxSpriteGroup(x, y);

		var maxCol = icons.length < 4 ? icons.length : 4;
		var maxRow = Math.floor((icons.length-1) / 4) + 1;
		for (i=>icon in icons) {
			var healthIcon = new HealthIcon(Character.getIconFromCharName(icon));
			healthIcon.scale.x = healthIcon.scale.y = Math.max((0.6 - (icons.length / 20)), 0.35);
			healthIcon.updateHitbox();
			healthIcon.x = FlxMath.lerp(0, Math.min(icons.length * 20, 120), (maxCol-1 != 0 ? (i % 4) / (maxCol-1) : 0));
			healthIcon.y = (draggable ? 29 : 7) + FlxMath.lerp(0, Math.min(maxRow * 15, 60), (maxRow-1 != 0 ? Math.floor(i / 4) / (maxRow-1) : 0));
			healthIcon.alpha = strumLine.visible ? 1 : 0.4;
			healthIcons.add(healthIcon);
		}

		members.push(healthIcons);

		draggingSprite = new UISprite();
		draggingSprite.loadGraphic(Paths.image("editors/charter/strumline-drag"));
		draggingSprite.alpha = 0.4;
		draggingSprite.y = 9;
		draggingSprite.antialiasing = true;
		draggingSprite.cursor = CLICK;
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

		healthIcons.follow(this, ((40 * keyCount) - healthIcons.width) / 2, 7 + (__healthYOffset = FlxMath.lerp(__healthYOffset, draggable ? 8 : 0, 1/20)));

		draggingSprite.selectable = draggable;
		draggingSprite.updateSpriteRect();

		var dragScale:Float = FlxMath.lerp(draggingSprite.scale.x, draggable ? 1 : 0.8, 1/16);
		draggingSprite.scale.set(dragScale, dragScale);
		draggingSprite.updateHitbox();

		draggingSprite.follow(this, ((keyCount*40)/2) - (draggingSprite.width/2), 6 + (__draggingYOffset = FlxMath.lerp(__draggingYOffset, draggable ? 3 : 0, 1/12)));
		var fullAlpha:Float = UIState.state.isOverlapping(draggingSprite, @:privateAccess draggingSprite.__rect) || dragging ? 0.9 : 0.35;
		draggingSprite.alpha = FlxMath.lerp(draggingSprite.alpha, draggable ? fullAlpha : 0, 1/12);
		button.follow(this, 0, 95);

		super.update(elapsed);
	}

	public function updateInfo() {
		var icons = strumLine.characters != null ? strumLine.characters : [];

		keyCount = strumLine.keyCount != null ? strumLine.keyCount : 4;

		healthIcons.clear();

		var maxCol = icons.length < 4 ? icons.length : 4;
		var maxRow = Math.floor((icons.length-1) / 4) + 1;
		for (i=>icon in icons) {
			var healthIcon = new HealthIcon(Character.getIconFromCharName(icon));
			healthIcon.scale.x = healthIcon.scale.y = Math.max((0.6 - (icons.length / 20)), 0.35) * (150 / Math.max(healthIcon.frameWidth, healthIcon.frameHeight));
			healthIcon.updateHitbox();
			healthIcon.x = FlxMath.lerp(0, Math.min(icons.length * 20, 120), (maxCol-1 != 0 ? (i % 4) / (maxCol-1) : 0));
			healthIcon.y = (draggable ? 14 : 7) + FlxMath.lerp(0, Math.min(maxRow * 15, 60), (maxRow-1 != 0 ? Math.floor(i / 4) / (maxRow-1) : 0));
			healthIcon.alpha = strumLine.visible ? 1 : 0.4;
			healthIcons.add(healthIcon);
		}

		var asset = strumLine.vocalsSuffix.length > 0 ? Assets.getSound(Paths.voices(PlayState.SONG.meta.name, PlayState.difficulty, strumLine.vocalsSuffix)) : null;

		if (vocals == null) FlxG.sound.list.add(vocals = new FlxSound());
		if (asset != null) {
			vocals.reset();
			vocals.loadEmbedded(asset);
		}
		else {
			vocals.destroy();
		}
		vocals.group = FlxG.sound.defaultMusicGroup;
	}
}

class CharterStrumlineOptions extends UITopMenuButton {
	var strLine:CharterStrumline;
	public function new(parent:CharterStrumline) {
		// TODO: better id for this
		super(0, 95, null, TU.translate("charter.strumLine.button-name"), []);
		strLine = parent;
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		alpha = FlxMath.lerp(1/20, 1, alpha); // so that instead of 0% it is 33% visible
		bWidth = 40 * strLine.keyCount;
		this.label.fieldWidth = bWidth;
	}

	public override function openContextMenu() {
		contextMenu = [
			{
				label: TU.translate("charter.strumLine.hitsounds"),
				onSelect: function(_) {
					strLine.hitsounds = !strLine.hitsounds;
				},
				icon: strLine.hitsounds ? 1 : 0
			},
			{
				label: TU.translate("charter.strumLine.muteVocals"),
				onSelect: function(_) {
					strLine.vocals.volume = strLine.vocals.volume > 0 ? 0 : 1;
				},
				icon: strLine.vocals.volume > 0 ? 0 : 1
			},
			null,
			{
				label: TU.translate("charter.strumLine.edit"),
				onSelect: function (_) {
					Charter.instance.editStrumline(strLine.strumLine);
				},
				color: 0xFF959829,
				icon: 4
			},
			{
				label: TU.translate("charter.strumLine.delete"),
				onSelect: function (_) {
					Charter.instance.deleteStrumlineFromData(strLine.strumLine);
				},
				color: 0xFF982929,
				icon: 3
			}
		];

		contextMenu.insert(0, {
			label: TU.translate("charter.strumLine.noWaveform"),
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

		var cam = Charter.instance.charterCamera;
		var point = CoolUtil.worldToScreenPosition(this, cam);
		curMenu = UIState.state.openContextMenu(contextMenu, null, point.x, point.y + (bHeight*cam.zoom), Std.int(bWidth * cam.zoom));
		point.put();
	}
}