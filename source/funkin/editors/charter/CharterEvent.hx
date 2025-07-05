package funkin.editors.charter;

import flixel.system.FlxAssets.FlxGraphicAsset;
import funkin.editors.charter.Charter.ICharterSelectable;
import flixel.math.FlxPoint;
import funkin.game.Character;
import funkin.game.HealthIcon;
import funkin.editors.charter.CharterBackdropGroup.EventBackdrop;
import funkin.backend.chart.ChartData.ChartEvent;

class CharterEvent extends UISliceSprite implements ICharterSelectable {
	public var events:Array<ChartEvent>;
	public var step:Float;
	public var icons:Array<FlxSprite> = [];

	public var selected:Bool = false;
	public var draggable:Bool = true;

	public var eventsBackdrop:EventBackdrop;
	public var snappedToGrid:Bool = true;

	public function new(step:Float, ?events:Array<ChartEvent>) {
		super(-100, (step * 40) - 17, 100, 34, 'editors/charter/event-spr');
		this.step = step;
		this.events = events.getDefault([]);

		cursor = BUTTON;
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (snappedToGrid && eventsBackdrop != null)
			x = eventsBackdrop.x + eventsBackdrop.width - (bWidth = 37 + (icons.length * 22));

		for(k=>i in icons) {
			i.follow(this, (k * 22) + 30 - (i.width / 2), (bHeight - i.height) / 2);
		}

		colorTransform.redMultiplier = colorTransform.greenMultiplier = colorTransform.blueMultiplier = selected ? 0.75 : 1;
		colorTransform.redOffset = colorTransform.greenOffset = selected ? 96 : 0;
		colorTransform.blueOffset = selected ? 168 : 0;

		for (sprite in icons)
			sprite.colorTransform = colorTransform;
	}

	private static function generateDefaultIcon(name:String) {
		var isBase64:Bool = false;
		var path:String = Paths.image('editors/charter/event-icons/$name');
		var defaultPath = Paths.image('editors/charter/event-icons/Unknown');
		if (!Assets.exists(path)) path = defaultPath;

		var packPath = Paths.pack('events/$name');
		if (Assets.exists(packPath)) {
			var packText = Assets.getText(packPath).split('________PACKSEP________');
			var packImg = packText[3];
			if(packImg != null && packImg.length > 0) {
				isBase64 = !packImg.startsWith("assets/");
				path = packImg;
			}
		}
		path = path.trim();

		var graphic:FlxGraphicAsset = try {
			isBase64 ? openfl.display.BitmapData.fromBase64(path, 'UTF8') : path;
		} catch(e:Dynamic) {
			Logs.trace('Failed to load event icon: ${e.toString()}', ERROR);
			isBase64 = false;
			defaultPath;
		}

		if(!isBase64) {
			if (!Assets.exists(graphic))
				graphic = defaultPath;
		}

		return new FlxSprite().loadGraphic(graphic);
	}

	public static function generateEventIcon(event:ChartEvent) {
		return switch(event.name) {
			default:
				generateDefaultIcon(event.name);
			case "Camera Movement":
				// custom icon for camera movement
				var state = cast(FlxG.state, Charter);
				if (event.params != null && event.params[0] != null && event.params[0] >= 0 && event.params[0] < state.strumLines.length) {
					// camera movement, use health icon
					var icon = Character.getIconFromCharName(state.strumLines.members[event.params[0]].strumLine.characters[0]);
					var healthIcon = new HealthIcon(icon);
					healthIcon.setUnstretchedGraphicSize(32, 32, false);
					healthIcon.scrollFactor.set(1, 1);
					healthIcon.active = false;
					healthIcon;
				} else
					generateDefaultIcon(event.name);
		}
	}

	public override function onHovered() {
		super.onHovered();
		/*
		if (FlxG.mouse.justReleased)
			FlxG.state.openSubState(new CharterEventScreen(this));
		*/
	}

	public function handleSelection(selectionBox:UISliceSprite):Bool {
		return (selectionBox.x + selectionBox.bWidth > x) && (selectionBox.x < x + bWidth) && (selectionBox.y + selectionBox.bHeight > y) && (selectionBox.y < y + bHeight);
	}

	public function handleDrag(change:FlxPoint) {
		var newStep:Float = step = FlxMath.bound(step + change.x, 0, Charter.instance.__endStep-1);
		y = ((newStep) * 40) - 17;
	}

	public function refreshEventIcons() {
		while(icons.length > 0) {
			var i = icons.shift();
			members.remove(i);
			i.destroy();
		}

		for(event in events) {
			var spr = generateEventIcon(event);
			icons.push(spr);
			members.push(spr);
		}

		draggable = true;
		for (event in events)
			if (event.name == "BPM Change") {
				draggable = false;
				break;
			}

		x = (snappedToGrid && eventsBackdrop != null ? eventsBackdrop.x : 0) - (bWidth = 37 + (icons.length * 22));
	}
}