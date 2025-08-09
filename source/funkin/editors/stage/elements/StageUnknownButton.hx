package funkin.editors.stage.elements;

import funkin.game.Character;
import funkin.game.Stage.StageCharPos;
import haxe.xml.Access;

class StageUnknownButton extends StageElementButton {
	public var lowMemory:Bool = false;
	public var highMemory:Bool = false;
	public var basic:FlxBasic;

	public function new(x:Float,y:Float, basic:FlxBasic, xml:Access) {
		this.basic = basic;
		super(x,y, xml);

		if(xml.x.parent != null) {
			lowMemory = xml.x.parent.nodeName == "low-memory";
			highMemory = xml.x.parent.nodeName == "high-memory";
		}

		color = 0xff000000;

		visibilityButton.exists = false;
		members.remove(visibilityButton);

		visibilityIcon.exists = false;
		members.remove(visibilityIcon);

		setEditAdvanced();

		updateInfo();
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
	}

	public override function updateInfo() {
		super.updateInfo();
	}

	public override function getSprite():FunkinSprite {
		var sprite = new FunkinSprite(); // to allow it to be saved
		sprite.extra.set(StageEditor.exID("lowMemory"), lowMemory);
		sprite.extra.set(StageEditor.exID("highMemory"), highMemory);
		sprite.extra.set(StageEditor.exID("button"), this);
		return sprite;
	}

	public override function canRender() {
		return false;
	}

	public override function onSelect() {
	}

	public override function onEdit() {
		FlxG.state.openSubState(new StageUnknownEditScreen(this));
	}

	//public override function onEdit() {
	//	UIState.state.displayNotification(new UIBaseNotification("Editing a character isnt implemented yet!", 2, BOTTOM_LEFT));
	//	CoolUtil.playMenuSFX(WARNING, 0.45);
	//}

	public override function onVisiblityToggle() {
	}

	public override function getName():String {
		return xml.name;
	}

	public override function getPos():FlxPoint {
		return FlxPoint.get(0, 0);
	}

	public override function getInfoText():String {
		return TU.translate("stageElement.unknown", [getName()]);
	}

	public override function updatePos() {
		super.updatePos();
	}
}

class StageUnknownEditScreen extends UISoftcodedWindow {
	public var button:StageUnknownButton;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("stageElementEditScreen." + id, args);

	public function new(button:StageUnknownButton) {
		this.button = button;
		super("layouts/stage/unknownEditScreen", [
			"stage" => StageEditor.instance.stage,
			"button" => button,
			"xml" => button.xml,
			"exID" => StageEditor.exID,
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