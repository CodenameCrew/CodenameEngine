package funkin.game.stage;

import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

class StageCharPos implements IFlxDestroyable {
	public var extra:Map<String, Dynamic> = [];

	public var name:String;
	public var layer:Layer;
	public var position:Int = -1;
	public var x:Float = 0;
	public var y:Float = 0;
	public var charSpacingX:Float = 20;
	public var charSpacingY:Float = 0;
	public var camxoffset:Float = 0;
	public var camyoffset:Float = 0;
	public var skewX:Float = 0;
	public var skewY:Float = 0;
	public var alpha:Float = 1;
	public var angle:Float = 0;
	public var flipX:Bool = false;
	public var scale:FlxPoint = FlxPoint.get(1, 1);
	public var scrollFactor:FlxPoint = FlxPoint.get(1, 1);
	public var zoomFactor:Float = 1;

	public function new() {}

	private var _id:Float = -1;

	private var oldInfo:OldCharInfo = null;

	public inline function setPosition(x = 0.0, y = 0.0):Void {
		this.x = x;
		this.y = y;
	}

	public function prepareCharacter(char:Character, id:Float = 0) {
		_id = id;
		oldInfo = getOldInfo(char);
		char.setPosition(x + (id * charSpacingX), y + (id * charSpacingY));
		char.scrollFactor.set(scrollFactor.x, scrollFactor.y);
		if (!Std.isOfType(FlxG.state, funkin.editors.character.CharacterEditor)) {
			char.scale.x *= scale.x; char.scale.y *= scale.y;
		}
		char.cameraOffset += FlxPoint.weak(camxoffset, camyoffset);
		char.skew.x += skewX; char.skew.y += skewY;
		char.alpha *= alpha;
		char.angle += angle;
		char.zoomFactor *= zoomFactor;
	}

	public function getOldInfo(char:Character):OldCharInfo {
		return {
			x: char.x, y: char.y,
			scrollX: char.scrollFactor.x, scrollY: char.scrollFactor.y,
			scaleX: char.scale.x, scaleY: char.scale.y,
			camxoffset: char.cameraOffset.x, camyoffset: char.cameraOffset.y,
			skewX: char.skew.x, skewY: char.skew.y,
			alpha: char.alpha, zoomFactor: char.zoomFactor,
			angle: char.angle
		}
	}

	public function revertCharacter(char:Character) {
		if(oldInfo == null) return;
		for(field in Reflect.fields(oldInfo)) {
			switch(field) {
				case "scrollX": char.scrollFactor.x = oldInfo.scrollX;
				case "scrollY": char.scrollFactor.y = oldInfo.scrollY;
				case "scaleX": char.scale.x = oldInfo.scaleX;
				case "scaleY": char.scale.y = oldInfo.scaleY;
				case "camxoffset": char.cameraOffset.x = oldInfo.camxoffset;
				case "camyoffset": char.cameraOffset.y = oldInfo.camyoffset;
				case "skewX": char.skew.x = oldInfo.skewX;
				case "skewY": char.skew.y = oldInfo.skewY;
				default: Reflect.setProperty(char, field, Reflect.field(oldInfo, field));
			}
		}
		oldInfo = null;
	}

	public function destroy() {
		layer = null;
		scale.put();
		scrollFactor.put();
	}
}

typedef StageCharPosInfo = {
	var x:Float;
	var y:Float;
	var flip:Bool;
	var scroll:Float;
}

typedef OldCharInfo = {
	var x:Float;
	var y:Float;
	var scrollX:Float;
	var scrollY:Float;
	var scaleX:Float;
	var scaleY:Float;
	var camxoffset:Float;
	var camyoffset:Float;
	var skewX:Float;
	var skewY:Float;
	var alpha:Float;
	var zoomFactor:Float;
	var angle:Float;
}