package funkin.editors.stage;

import funkin.editors.stage.elements.StageElementButton;
import funkin.editors.stage.elements.*;

class StageSpritesWindow extends UIButtonList<StageElementButton> {

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("stageSprites." + id, args);

	public function new(x:Float, y:Float) {
		super(x, y, 400, FlxG.height-25, translate("win-title"), FlxPoint.get(400, 64));

		collapsable = true;
		topAlpha = 0.9;
		middleAlpha = 0.5;
		bottomAlpha = 0.5;
		buttonSpacing = 0;
		dragCallback = (button, oldID, newID) -> {
			var sprite:FlxBasic = (button is StageUnknownButton) ? cast(button, StageUnknownButton).basic : button.getSprite();
			var idx = StageEditor.instance.members.indexOf(sprite);
			StageEditor.instance.members.splice(idx, 1);
			StageEditor.instance.members.insert(newID, sprite);
		}
		addButton.callback = () -> @:privateAccess {
			var lastDrawCam = addButton.__lastDrawCameras[0];
			var screenPos = addButton.getScreenPosition(null, lastDrawCam == null ? FlxG.camera : lastDrawCam);
			StageEditor.instance.openContextMenu([
				{
					label: translate("sprite"),
					onSelect: StageEditor.instance._sprite_new,
					color: 0xFF00FF00,
					icon: 2
				},
				{
					label: translate("box"),
					onSelect: function(_) {
						UIState.state.displayNotification(new UIBaseNotification(translate("warnings.not-implemented"), 2, BOTTOM_LEFT));
						CoolUtil.playMenuSFX(WARNING, 0.45);
					},
					color: 0xFF00FF00,
					icon: 2
				},
				{
					label: translate("character"),
					onSelect: StageEditor.instance._character_new,
					color: 0xFF00FF00,
					icon: 2
				}
			], null, lastDrawCam.x + screenPos.x, lastDrawCam.y + screenPos.y + addButton.bHeight, addButton.bWidth);
			screenPos.put();
		}
	}
}