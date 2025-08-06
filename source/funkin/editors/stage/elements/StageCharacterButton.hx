package funkin.editors.stage.elements;

import funkin.editors.stage.StageEditor.StageXMLEditScreen;
import funkin.editors.ui.notifications.UIBaseNotification;
import funkin.editors.ui.UIState;
import funkin.game.Character;
import haxe.xml.Access;

using StringTools;

class StageCharacterButton extends StageElementButton {
	public var char:Character;
	public var charScale(get, null):Float;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("stageCharacters." + id, args);

	public function new(x:Float,y:Float, char:Character, xml:Access) {
		this.char = char;
		super(x,y, xml);

		color = 0xff7aa8ff;

		hasAdvancedEdit = true;

		updateInfo();
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
	}

	public override function updateInfo() {
		char.visible = !isHidden;
		char.scale.scale(1 / charScale);
		super.updateInfo();
		char.scale.scale(charScale);
	}

	public override function getSprite():FunkinSprite {
		return char;
	}

	public override function onSelect() {
		StageEditor.instance.selectSprite(char);
	}

	/*public override function onSelect() {
		UIState.state.displayNotification(new UIBaseNotification("Selecting a character isnt implemented yet!", 2, BOTTOM_LEFT));
		CoolUtil.playMenuSFX(WARNING, 0.45);
	}*/

	public override function onEdit() {
		if(!FlxG.keys.pressed.SHIFT) {
			FlxG.state.openSubState(new StageCharacterEditScreen(this));
		} else {
			FlxG.state.openSubState(new StageXMLEditScreen(this.xml, updateInfo, "Character"));
		}
	}
	//public override function onEdit() {
	//	UIState.state.displayNotification(new UIBaseNotification("Editing a character isnt implemented yet!", 2, BOTTOM_LEFT));
	//	CoolUtil.playMenuSFX(WARNING, 0.45);
	//}

	public override function onDelete() {
		if (char.name.startsWith("NO_DELETE_")) {
			var text = translate("requiredPosition");
			if (char.name == "NO_DELETE_girlfriend" && FlxG.random.bool(1))
				text = translate("noDeleteGirlfriend");
			UIState.state.displayNotification(new UIBaseNotification(text, 2, BOTTOM_LEFT));
			return;
		}

		char.destroy();
		xml.x.parent.removeChild(xml.x);
		StageEditor.instance.xmlMap.remove(char);
		StageEditor.instance.stageSpritesWindow.remove(this);
	}

	public override function onVisiblityToggle() {
		isHidden = !isHidden;
		updateInfo();
	}

	public override function getName():String {
		return char.name.replace("NO_DELETE_", "");
	}

	public override function getPos():FlxPoint {
		return FlxPoint.get(char.x, char.y);
	}

	public override function updatePos() {
		super.updatePos();
	}

	function get_charScale():Float {
		return (char.xml.has.scale ? Std.parseFloat(char.xml.att.scale).getDefault(1) : 1);
	}
}

class StageCharacterEditScreen extends UISoftcodedWindow {
	public var button:StageCharacterButton;
	public var char:Character;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("stageElementEditScreen." + id, args);

	public function new(button:StageCharacterButton) {
		this.button = button;
		this.char = button.char;
		super("layouts/stage/characterEditScreen", [
			"stage" => StageEditor.instance.stage,
			"char" => char,
			"charScale" => button.charScale,
			"button" => button,
			"xml" => button.xml,
			"exID" => StageEditor.exID,
			"StringTools" => StringTools,
			"getEx" => function(name:String):Dynamic {
				return char.extra.get(StageEditor.exID(name));
			},
			"setEx" => function(name:String, value:Dynamic) {
				char.extra.set(StageEditor.exID(name), value);
			},
			"translate" => translate,
		]);
	}

	public override function create() {
		super.create();
	}

	public override function saveData() {
		super.saveData();
		button.updateInfo();
	}
}