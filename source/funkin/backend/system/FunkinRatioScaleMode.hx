package funkin.backend.system;

import flixel.system.scaleModes.RatioScaleMode;

class FunkinRatioScaleMode extends RatioScaleMode {
	@:isVar public var width(get, set):Null<Int> = null;
	@:isVar public var height(get, set):Null<Int> = null;

	public override function updateGameSize(Width:Int, Height:Int):Void
	{
		if (Width <= 0) Width = 1280;
		if (Height <= 0) Height = 720;

		#if android
		super.updateGameSize(Width, Height);
		#else
		var ratio:Float = width / height;
		var realRatio:Float = Width / Height;

		var scaleY:Bool = realRatio < ratio;
		if (fillScreen)
		{
			scaleY = !scaleY;
		}

		if (scaleY)
		{
			gameSize.x = Width;
			gameSize.y = Math.floor(gameSize.x / ratio);
		}
		else
		{
			gameSize.y = Height;
			gameSize.x = Math.floor(gameSize.y * ratio);
		}

		@:privateAccess {

			for(c in FlxG.cameras.list) {
				if (c.width == FlxG.width && c.height == FlxG.height) {
					c.width = width;
					c.height = height;
				}
			}

			FlxG.width = width;
			FlxG.height = height;
		}
		#end
	}

	public function setFillScreen(value:Bool) {
		fillScreen = value;
		if (FlxG.stage == null || FlxG.stage.stageWidth <= 0 || FlxG.stage.stageHeight <= 0)
			return;
		@:privateAccess
		FlxG.game.onResize(null);
	}

	public function resetSize() {
		width = null;
		height = null;
	}
	private inline function get_width():Null<Int>
		return this.width == null ? FlxG.initialWidth : this.width;
	private inline function get_height():Null<Int>
		return this.height == null ? FlxG.initialHeight : this.height;
	private inline function set_width(v:Null<Int>):Null<Int> {
		this.width = v;
		@:privateAccess
		FlxG.game.onResize(null);
		return v;
	}
	private inline function set_height(v:Null<Int>):Null<Int> {
		this.height = v;
		@:privateAccess
		FlxG.game.onResize(null);
		return v;
	}
}