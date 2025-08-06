package funkin.editors.stage.elements;

import funkin.editors.stage.StageEditor.StageXMLEditScreen;
import funkin.editors.stage.elements.StageElementButton;
import funkin.editors.ui.UISoftcodedWindow;
import haxe.xml.Access;

class StageSpriteButton extends StageElementButton {
	public var sprite:FunkinSprite;

	public function new(x:Float,y:Float, sprite:FunkinSprite, xml:Access) {
		this.sprite = sprite;
		super(x,y, xml);

		//color = 0xFFD9FF50;

		hasAdvancedEdit = true;

		updateInfo();
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
	}

	public override function updateInfo() {
		sprite.visible = !isHidden;
		super.updateInfo();
	}

	public override function getSprite():FunkinSprite {
		return sprite;
	}

	public override function onSelect() {
		StageEditor.instance.selectSprite(sprite);
	}

	public override function onVisiblityToggle() {
		isHidden = !isHidden;
		updateInfo();
	}

	public override function onEdit() {
		if(!FlxG.keys.pressed.SHIFT) {
			FlxG.state.openSubState(new StageSpriteEditScreen(this));
		} else {
			FlxG.state.openSubState(new StageXMLEditScreen(this.xml, updateInfo, "Sprite"));
		}
	}

	public override function onDelete() {
		sprite.destroy();
		xml.x.parent.removeChild(xml.x);
		StageEditor.instance.stage.stageSprites.remove(sprite.name);
		StageEditor.instance.xmlMap.remove(sprite);
		StageEditor.instance.stageSpritesWindow.remove(this);
	}

	public override function getName():String {
		return xml.att.name;
	}

	public override function getPos():FlxPoint {
		return FlxPoint.get(sprite.x, sprite.y);
	}

	public override function updatePos() {
		super.updatePos();
	}
}

class StageSpriteEditScreen extends UISoftcodedWindow {
	public var newSprite:Bool = false;
	public var button:StageSpriteButton;
	public var sprite:FunkinSprite;
	var isSaving:Bool = false;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("stageElementEditScreen." + id, args);

	public function new(button:StageSpriteButton) {
		this.button = button;
		this.sprite = button.getSprite();
		super("layouts/stage/spriteEditScreen", [
			"stage" => StageEditor.instance.stage,
			"sprite" => sprite,
			"button" => button,
			"xml" => button.xml,
			"exID" => StageEditor.exID,
			"getEx" => function(name:String):Dynamic {
				return sprite.extra.get(StageEditor.exID(name));
			},
			"setEx" => function(name:String, value:Dynamic) {
				sprite.extra.set(StageEditor.exID(name), value);
			},
			"translate" => translate,
		]);
	}

	public override function create() {
		super.create();
	}

	public override function saveData() {
		isSaving = true;
		super.saveData();
		button.updateInfo();
	}

	public override function close() {
		if (!isSaving && newSprite) {
			button.onDelete();
			trace("deleting sprite");
		}
		super.close();
	}
}