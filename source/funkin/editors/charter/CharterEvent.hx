package funkin.editors.charter;

import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import funkin.backend.chart.ChartData.ChartEvent;
import funkin.backend.scripting.DummyScript;
import funkin.backend.scripting.Script;
import funkin.backend.system.Conductor;
import funkin.editors.charter.Charter.ICharterSelectable;
import funkin.editors.charter.CharterBackdropGroup.EventBackdrop;
import funkin.game.Character;
import funkin.game.HealthIcon;

using flixel.util.FlxColorTransformUtil;

class CharterEvent extends UISliceSprite implements ICharterSelectable {
	public var events:Array<ChartEvent>;
	public var step:Float;
	public var icons:Array<FlxSprite> = [];

	public var selected:Bool = false;
	public var draggable:Bool = true;

	public var eventsBackdrop:EventBackdrop;
	public var snappedToGrid:Bool = true;

	public var displayGlobal:Bool = false;
	public var global(default, set):Bool = false;
	private function set_global(val:Bool) {
		for (event in events) event.global = val;
		return global = val;
	}

	public function new(step:Float, ?events:Array<ChartEvent>, ?global:Bool) {
		super(-100, (step * 40) - 17, 100, 34, 'editors/charter/event-spr');
		this.step = step;
		this.events = events.getDefault([]);

		this.global = displayGlobal = (global == null ? events[0] != null && events[0].global == true : global);
		this.color = displayGlobal ? 0xffc8bd23 : 0xFFFFFFFF;

		cursor = CLICK;
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (snappedToGrid && eventsBackdrop != null) {
			bWidth = 37 + (icons.length * 22);
			x = eventsBackdrop.x + (global ? 0 : eventsBackdrop.width - bWidth);
		}

		for(k=>i in icons) {
			i.follow(this, (k * 22) + 30 - (i.width / 2), (bHeight - i.height) / 2);
		}

		@:bypassAccessor color = CoolUtil.lerpColor(this.color, displayGlobal ? 0xffc8bd23 : 0xFFFFFFFF, 1/3);
		colorTransform.setMultipliers(color.redFloat, color.greenFloat, color.blueFloat, alpha);
		colorTransform.setOffsets(0, 0, 0, 0);
		selectedColorTransform(colorTransform);
		useColorTransform = true;

		for (sprite in icons) @:privateAccess {
			sprite.colorTransform.__identity();
			selectedColorTransform(sprite.colorTransform);
		}

		flipX = displayGlobal;
	}

	@:noCompletion private inline function selectedColorTransform(transform:ColorTransform) {
		transform.redMultiplier *= selected ? 0.75 : 1;
		transform.greenMultiplier *= selected ? 0.75 : 1;
		transform.blueMultiplier *= selected ? 0.75 : 1;

		transform.redOffset += selected ? 96 : 0;
		transform.greenOffset += selected ? 96 : 0;
		transform.blueOffset += selected ? 168 : 0;
	}

	/**
	 * Pack data is a list of 5 strings separated by `________PACKSEP________`
	 * [0] Event Name
	 * [1] Event Script
	 * [2] Event JSON Info
	 * [3] Event Icon
	 * [4] Event UI Script / Icon Script
	**/
	@:dox(hide) public static function getPackData(name:String):Array<String> {
		var packFile = Paths.pack('events/${name}');
		if (Assets.exists(packFile)) {
			return Assets.getText(packFile).split('________PACKSEP________');
		}
		return null;
	}

	@:dox(hide) public static function getUIScript(event:ChartEvent, caller:String):Script {
		var uiScript = Paths.script('data/events/${event.name}.ui');
		var script:Script = null;
		if(Assets.exists(uiScript)) {
			script = Script.create(uiScript);
		} else {
			var packData = getPackData(event.name);
			if(packData != null) {
				var scriptFile = packData[4];
				if(scriptFile != null) {
					script = Script.fromString(scriptFile, uiScript);
				}
			}
		}

		if(script != null && !(script is DummyScript)) {
			// classes and functions
			script.set("EventIconGroup", EventIconGroup); // automatically imported
			script.set("EventNumber", EventNumber); // automatically imported
			script.set("getIconFromStrumline", getIconFromStrumline);
			script.set("getIconFromCharName", getIconFromCharName);
			script.set("generateDefaultIcon", generateDefaultIcon);
			script.set("generateEventIconDurationArrow", generateEventIconDurationArrow);
			script.set("generateEventIconNumbers", generateEventIconNumbers);
			script.set("generateEventIconWarning", generateEventIconWarning);
			script.set("getPackData", getPackData);
			script.set("getEventComponent", getEventComponent);
			// data
			script.set("event", event);
			script.set("caller", caller);

			script.load();
		}

		return script;
	}

	/**
	 * Generates the default event icon for the wanted event
	 * @param name The name of the event
	 * @return The icon
	**/
	private static function generateDefaultIcon(name:String) {
		var isBase64:Bool = false;
		var path:String = Paths.image('editors/charter/event-icons/$name');
		var defaultPath = Paths.image('editors/charter/event-icons/Unknown');
		if(!Assets.exists(path)) {
			path = defaultPath;

			var packData = getPackData(name);
			if(packData != null) {
				var packImg = packData[3];
				if(packImg != null && packImg.length > 0) {
					isBase64 = !packImg.startsWith("assets/");
					path = packImg;
				}
			}
		}
		path = path.trim();

		var graphic:FlxGraphicAsset = try {
			isBase64 ? BitmapData.fromBase64(path, 'UTF8') : path;
		} catch(e:Dynamic) {
			Logs.trace('Failed to load event icon: ${e.toString()}', ERROR);
			isBase64 = false;
			defaultPath;
		}

		if(!isBase64) {
			if (!Assets.exists(graphic))
				graphic = defaultPath;
		}

		return new FlxSprite(graphic);
	}

	/**
	 * Gets a component sprite from the editors/charter/event-icons/components folder
	 * If you wanna use a number, please use the EventNumber class instead
	 * @param type The type of component to get
	 * @param x The x position of the sprite (optional)
	 * @param y The y position of the sprite (optional)
	 * @return The component sprite
	**/
	public static function getEventComponent(type:String, x:Float = 0.0, y:Float = 0.0) {
		var componentPath = Paths.image("editors/charter/event-icons/components/" + type);
		if (Assets.exists(componentPath)) return new FlxSprite(x, y, componentPath);

		Logs.trace('Could not find component $type', WARNING);
		return null;
	}

	/**
	 * Expected to be called from inside of a ui script,
	 * calling this elsewhere might cause unexpected results or crashes
	**/
	public static function getIconFromStrumline(index:Null<Int>) {
		var state = cast(FlxG.state, Charter);
		if (index != null && index >= 0 && index < state.strumLines.length) {
			return getIconFromCharName(state.strumLines.members[index].strumLine.characters[0]);
		}
		return null;
	}

	public static function getIconFromCharName(name:String) {
		var icon = Character.getIconFromCharName(name);
		var healthIcon = new HealthIcon(icon);
		CoolUtil.setUnstretchedGraphicSize(healthIcon, 32, 32, false);
		healthIcon.scrollFactor.set(1, 1);
		healthIcon.active = false;
		return healthIcon;
	}

	public static function generateEventIcon(event:ChartEvent, inMenu:Bool = true):FlxSprite {
		var script = getUIScript(event, "event-icon");
		if(script != null && !(script is DummyScript)) {
			script.set("inMenu", inMenu);
			if(script.get("generateIcon") != null) {
				var res:FlxSprite = script.call("generateIcon");
				if(res != null)
					return res;
			}
		}

		switch(event.name) {
			case "Time Signature Change":
				if(event.params != null && (event.params[0] >= 0 || event.params[1] >= 0)) {
					var group = new EventIconGroup();
					group.add(generateDefaultIcon(event.name));
					group.add({ // top
						var num = new EventNumber(9, -1, event.params[0], EventNumber.ALIGN_CENTER);
						num.active = false;
						num;
					});
					group.add({ // bottom
						var num = new EventNumber(9, 10, event.params[1], EventNumber.ALIGN_CENTER);
						num.active = false;
						num;
					});
					if (Conductor.invalidEvents.contains(event)) generateEventIconWarning(group);
					return group;
				}
			case "Continuous BPM Change":
				if(event.params != null && event.params[1] != null) {
					var group = new EventIconGroup();
					group.add(generateDefaultIcon("BPM Change Start"));
					if (!inMenu) {
						generateEventIconDurationArrow(group, event.params[1]);
						group.members[0].y -= 2;
						generateEventIconNumbers(group, event.params[0], 3);
					}
					if (Conductor.invalidEvents.contains(event)) generateEventIconWarning(group);
					return group;
				} else {
					return generateDefaultIcon("BPM Change Start");
				}
			case "BPM Change":
				if(event.params != null && event.params[0] != null) {
					var group = new EventIconGroup();
					group.add(generateDefaultIcon(event.name));
					if (!inMenu) {
						group.members[0].y -= 2;
						generateEventIconNumbers(group, event.params[0], 3);
					}
					if (Conductor.invalidEvents.contains(event)) generateEventIconWarning(group);
					return group;
				}

			case "Scroll Speed Change":
				if(event.params != null && !inMenu) {
					var group = new EventIconGroup();
					group.add(generateDefaultIcon(event.name));
					if (event.params[0]) generateEventIconDurationArrow(group, event.params[2]);
					group.members[0].y -= 2;
					generateEventIconNumbers(group, event.params[1]);
					return group;
				}

			case "Camera Movement":
				var shouldDoArrow:Bool = false;
				var icon:Null<FlxSprite> = null;
				if (event.params != null) {
					shouldDoArrow = event.params[1] && event.params[3] != "CLASSIC"; // is Tweened and isnt Lerped
					icon = getIconFromStrumline(event.params[0]); // camera movement, use health icon
				}
				
				if (icon == null) icon = generateDefaultIcon(event.name);
				
				if(event.params != null && shouldDoArrow && !inMenu) {
					var group = new EventIconGroup();
					group.add(icon);
					group.members[0].x -= 8;
					group.members[0].y -= 8;
					generateEventIconDurationArrow(group, event.params[2]);
					return group;
				} else
					return icon;

			case "Camera Position":
				var shouldDoArrow:Bool = false;
				if (event.params != null)
					shouldDoArrow = event.params[2] && event.params[4] != "CLASSIC"; // is Tweened and isnt Lerped

				if(event.params != null && shouldDoArrow && !inMenu) {
					var group = new EventIconGroup();
					group.add(generateDefaultIcon(event.name));
					generateEventIconDurationArrow(group, event.params[3]);
					return group;
				}

			case "Camera Zoom":
				var shouldDoArrow:Bool = false;
				if (event.params != null)
					shouldDoArrow = event.params[0];

				if(event.params != null && shouldDoArrow && !inMenu) {
					var group = new EventIconGroup();
					group.add(generateDefaultIcon(event.name));
					generateEventIconDurationArrow(group, event.params[3]);
					return group;
				}
		}
		return generateDefaultIcon(event.name);
	}

	private static function generateEventIconNumbers(group:EventIconGroup, number:Float, x:Float = 4, y:Float = 15, spacing:Float = 5, precision:Int = 3) {
		group.add({
			var num = new EventNumber(x, y, number, EventNumber.ALIGN_CENTER, spacing, precision);
			if (num.numWidth > 20) {
				num.scale.x = num.scale.y = 20 / num.numWidth;
			}
			num.active = false;
			num;
		});
	}

	private static function generateEventIconDurationArrow(group:EventIconGroup, stepDuration:Float) {
		//var group = new EventIconGroup();
		//group.add(generateDefaultIcon(startIcon));

		var xOffset = 4;
		var yGap = 24;
		var endGap = 2;

		if (stepDuration >= 0.55) { //min time for showing arrow
			var tail = new FlxSprite(xOffset, yGap);
			var arrow = new FlxSprite(xOffset, (stepDuration * 40) + endGap);
			var arrowSegment = new FlxSprite(xOffset, yGap);
			tail.frames = arrow.frames = arrowSegment.frames = Paths.getSparrowAtlas("editors/charter/event-icons/components/arrow-down");

			group.add({
				tail.animation.addByPrefix("tail", "tail");
				tail.animation.play("tail");
				tail;
			});

			group.add({
				arrowSegment.animation.addByPrefix("segment", "segment");
				arrowSegment.animation.play("segment");
				arrowSegment.scale.y = endGap + (stepDuration * 40) - (tail.height + yGap);
				arrowSegment.updateHitbox();
				arrowSegment.y += tail.height;
				arrowSegment;
			});

			group.add({
				arrow.animation.addByPrefix("arrow", "arrow");
				arrow.animation.play("arrow");
				arrow;
			});
		}
	}

	private static function generateEventIconWarning(group:EventIconGroup) {
		for (spr in group) {
			spr.colorTransform.redMultiplier = spr.colorTransform.greenMultiplier = spr.colorTransform.blueMultiplier = 0.5;
			spr.colorTransform.redOffset = 100;
		}
		group.add(getEventComponent("warning", 16, -8));
		group.copyColorTransformToChildren = false;
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
		var newStep:Float = step = CoolUtil.bound(step + change.x, 0, Charter.instance.__endStep-1);
		y = ((newStep) * 40) - 17;
	}

	public function refreshEventIcons() {
		while(icons.length > 0) {
			var i = icons.shift();
			members.remove(i);
			i.destroy();
		}

		for(event in events) {
			var spr = generateEventIcon(event, false);
			icons.push(spr);
			members.push(spr);
		}

		draggable = true;

		bWidth = 37 + (icons.length * 22);
		x = (snappedToGrid && eventsBackdrop != null && global ? eventsBackdrop.x - bWidth : (global ? 0 : -bWidth));
	}
}

class EventIconGroup extends FlxSpriteGroup {
	public var forceWidth:Float = 16;
	public var forceHeight:Float = 16;
	public var dontTransformChildren:Bool = false;
	public var copyColorTransformToChildren:Bool = true;

	public function new() {
		super();
		colorTransform = new ColorTransform();
		scrollFactor.set(1, 1);
	}

	override function preAdd(sprite:FlxSprite):Void
	{
		super.preAdd(sprite);
		sprite.scrollFactor.set(1, 1);
	}

	public override function transformChildren<V>(Function:FlxSprite->V->Void, Value:V):Void
	{
		if (dontTransformChildren)
			return;

		super.transformChildren(Function, Value);
	}

	override function set_x(Value:Float):Float
	{
		if (exists && x != Value)
			transformChildren(xTransform, Value - x); // offset
		return x = Value;
	}

	override function set_y(Value:Float):Float
	{
		if (exists && y != Value)
			transformChildren(yTransform, Value - y); // offset
		return y = Value;
	}

	override function get_width() {
		return forceWidth;
	}
	override function get_height() {
		return forceHeight;
	}

	override public function draw() {
		@:privateAccess
		if (copyColorTransformToChildren && colorTransform != null) for (child in members) child.colorTransform.__copyFrom(colorTransform);
		super.draw();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}
}

class EventNumber extends FlxSprite {
	public static inline final ALIGN_NORMAL:Int = 0;
	public static inline final ALIGN_CENTER:Int = 1;

	public var digits:Array<Int> = [];
	public static inline final FRAME_POINT:Int = 10;
	public static inline final FRAME_NEGATIVE:Int = 11;

	public var align:Int = ALIGN_NORMAL;
	public var spacing:Float = 6;

	public function new(x:Float, y:Float, number:Float, ?align:Int, spacing:Float = 6, precision:Int = 3) {
		super(x, y);
		this.digits = [];
		this.align = align == null ? ALIGN_NORMAL : align;
		this.spacing = spacing;

		if (number == 0) {
			this.digits.insert(0, 0);
		}
		else {
			var decimals:Float = FlxMath.roundDecimal(Math.abs(number % 1), precision);
			if (decimals > 0) this.digits.insert(0, FRAME_POINT);
			while(decimals > 0) {
				this.digits.push(Math.floor(decimals * 10));
				decimals = FlxMath.roundDecimal((decimals * 10) % 1, precision);
			}

			var ints = Std.int(Math.abs(number));
			if (ints == 0) this.digits.insert(0, 0);
			while (ints > 0) {
				this.digits.insert(0, ints % 10);
				ints = Std.int(ints / 10);
			}

			if (number < 0) {
				this.digits.insert(0, FRAME_NEGATIVE);
			}
		}

		loadGraphic(Paths.image('editors/charter/event-icons/components/eventNums'), true, 6, 7);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}

	override function draw() {
		var baseX = x;
		var offsetX = 0.0;
		if(align == ALIGN_CENTER) offsetX = -(digits.length - 1) * spacing * Math.abs(scale.x) / 2;

		x = baseX + offsetX;
		for (i in 0...digits.length) {
			frame = frames.frames[digits[i]];
			super.draw();
			x += spacing * Math.abs(scale.x);
		}
		x = baseX;
	}

	public var numWidth(get, never):Float;
	private function get_numWidth():Float {
		return Math.abs(scale.x) * spacing * digits.length;
	}
	public var numHeight(get, never):Float;
	private function get_numHeight():Float {
		return Math.abs(scale.y) * frameHeight;
	}

	public override function updateHitbox():Void {
		var numWidth = this.numWidth;
		var numHeight = this.numHeight;
		width = numWidth;
		height = numHeight;
		offset.set(-0.5 * (numWidth - spacing * digits.length), -0.5 * (numHeight - frameHeight));
		centerOrigin();
	}
}