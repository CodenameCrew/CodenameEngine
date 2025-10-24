package funkin.options;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSignal;
import funkin.backend.system.Controls;
import funkin.backend.TurboControls;
import funkin.options.TreeMenu.ITreeOption;
import funkin.options.TreeMenu.ITreeFloatOption;
import funkin.options.type.OptionType;
import funkin.options.type.Separator;

class TreeMenuScreen extends FlxSpriteGroup {
	public var persistentUpdate:Bool = false;
	public var persistentDraw:Bool = false;

	public var onClose:FlxSignal = new FlxSignal();

	public var parent:TreeMenu;
	public var transitioning:Bool = false;
	public var inputEnabled:Bool = false;
	public var curSelected:Int = 0;

	public var name:String;
	public var desc:String;
	/**
	 * The prefix to add to the translations ids.
	**/
	public var prefix:String = "";

	private var rawName(default, set):String;
	private var rawDesc(default, set):String;

	function set_rawName(v:String) {
		rawName = v;
		name = TU.exists(v) ? TU.translate(v) : v;
		return v;
	}

	function set_rawDesc(v:String) {
		rawDesc = v;
		desc = TU.exists(v) ? TU.translate(v) : v;
		return v;
	}

	public inline function getNameID(name):String return prefix + name + "-name";
	public inline function getDescID(name):String return prefix + name + "-desc";
	public inline function getID(name):String return prefix + name;
	public function translate(name:String, ?args:Array<Dynamic>):String return TU.translate(getID(name), args);

	public var controls(get, never):Controls;
	inline function get_controls():Controls return PlayerSettings.solo.controls;

	var leftTurboControl:TurboControls = new TurboControls([Control.LEFT], 0.2, 1 / 48);
	var rightTurboControl:TurboControls = new TurboControls([Control.RIGHT], 0.2, 1 / 48);
	var upTurboControl:TurboControls = new TurboControls([Control.UP]);
	var downTurboControl:TurboControls = new TurboControls([Control.DOWN]);
	var turboBasics:Array<TurboBasic>;

	var curOption:ITreeOption;
	var curFloatOption:ITreeFloatOption;
	var __firstFrame:Bool = true;

	public function new(name:String, desc:String, ?prefix:String, ?objects:Array<FlxSprite>) {
		super();
		this.prefix = prefix;
		rawName = name;
		rawDesc = desc;

		turboBasics = [leftTurboControl, rightTurboControl, upTurboControl, downTurboControl];

		if (objects != null) for (object in objects) add(object);
	}

	public function reloadStrings() {
		rawName = rawName;
		rawDesc = rawDesc;

		for (object in members) if (object != null && object is OptionType) cast(object, OptionType).reloadStrings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (__firstFrame) {
			__firstFrame = false;
			if (members[curSelected] is ITreeOption) {
				(curOption = cast members[curSelected]).selected = true;
				if (curOption is ITreeFloatOption) curFloatOption = cast curOption;
			}
			updateItems(true);
			return;
		}

		if (inputEnabled) {
			for (basic in turboBasics) basic.update(elapsed);

			var change = (upTurboControl.activated ? -1 : 0) + (downTurboControl.activated ? 1 : 0) - FlxG.mouse.wheel, mouseControl = false;
			if (FlxG.mouse.justPressed) {
				for (i in CoolUtil.maxInt(curSelected - 3, 0)...CoolUtil.minInt(curSelected + 4, length))
					if (i != curSelected && members[i] != null && mouseOverlaps(members[i])) {
						change = i - curSelected;
						mouseControl = true;
						break;
					}
			}
			changeSelection(change);

			if (length > 0 && curOption != null) {
				if (controls.ACCEPT || (!mouseControl && FlxG.mouse.justPressed && mouseOverlaps(members[curSelected]))) curOption.select();
				if (curFloatOption != null) {
					if (controls.LEFT) curFloatOption.changeValue(-elapsed);
					if (controls.RIGHT) curFloatOption.changeValue(elapsed);
				}
				else {
					if (leftTurboControl.activated) curOption.changeSelection(-1);
					if (rightTurboControl.activated) curOption.changeSelection(1);
				}
			}

			if (controls.BACK || (FlxG.mouse.justPressedRight && Main.timeSinceFocus > 0.3)) close();
		}

		updateItems();
	}

	dynamic function updateItem(object:FlxSprite, itemHeight:Float, centerY:Float, lerpRatio:Float) {
		object.y = CoolUtil.fpsLerp(object.y, centerY - itemHeight * 0.5, lerpRatio);
		object.x = x + 100 - Math.pow(Math.abs((object.y - (FlxG.height - itemHeight) * 0.5) / itemHeight / FlxG.height * FlxG.initialHeight), 1.6) * 15;
	}

	public function updateItems(force = false) {
		var r = force ? 1 : 0.25, initY = FlxG.height * 0.5;
		var i = curSelected, y = initY, object:FlxSprite = null, itemHeight:Float = 0;

		while (i < length) if ((object = members[i++]) != null) {
			itemHeight = object.height;
			updateItem(object, itemHeight, y, r);
			y += itemHeight;
		}

		y = initY;
		i = curSelected;
		while (i-- > 0) if ((object = members[i]) != null) {
			y -= (itemHeight = object.height);
			updateItem(object, itemHeight, y, r);
		}
	}

	public function close() {
		onClose.dispatch();

		if (curOption != null) curOption.selected = false;

		if (parent == null) return destroy();
		else parent.removeMenu(this);

		CoolUtil.playMenuSFX(CANCEL).persist = true;
	}

	public function changeSelection(change:Int, force:Bool = false) {
		if (length == 0 || (change == 0 && !force)) return;

		var prevSelect = curSelected = FlxMath.wrap(curSelected + change, 0, members.length - 1);
		while (members[curSelected] is Separator)
			if ((curSelected = FlxMath.wrap(curSelected + (change > 0 ? 1 : -1), 0, members.length - 1)) == prevSelect) break;

		if (curOption != null) curOption.selected = false;
		if (members[curSelected] is ITreeOption) {
			(curOption = cast members[curSelected]).selected = true;
			if (curOption is ITreeFloatOption) curFloatOption = cast curOption;
			else curFloatOption = null;
		}
		else {
			curOption = null;
			curFloatOption = null;
		}
		updateMenuDesc();

		CoolUtil.playMenuSFX(SCROLL);
	}

	public function updateMenuDesc(?customTxt:String) {
		if (parent != null) parent.updateDesc(customTxt);
	}

	function mouseOverlaps(sprite:FlxSprite):Bool
		return sprite.overlapsPoint(FlxG.mouse.getPosition(@:privateAccess flixel.input.FlxPointer._cachedPoint), true);

	override function destroy() {
		super.destroy();
		for (basic in turboBasics) basic.destroy();
	}
}