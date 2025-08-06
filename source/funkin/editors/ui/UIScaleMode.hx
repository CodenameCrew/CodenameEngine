package funkin.editors.ui;

import flixel.system.scaleModes.StageSizeScaleMode;

class UIScaleMode extends StageSizeScaleMode {
	override public function onMeasure(Width:Int, Height:Int):Void {
		if ((Width < FlxG.initialWidth || Height < FlxG.initialHeight) && !Options.bypassEditorsResize) {
			@:privateAccess {
				FlxG.width = FlxG.initialWidth;
				FlxG.height = FlxG.initialHeight;
			}
	
			updateGameSize(Width, Height);
			updateDeviceSize(Width, Height);
			updateScaleOffset();
			updateGamePosition();
		} else {
			super.onMeasure(Width, Height);

			for (camera in FlxG.cameras.list) {
				camera.width = Width;
				camera.height = Height;
			}
		}
	}

	override function updateGameSize(Width:Int, Height:Int):Void
	{
		var ratio:Float = FlxG.width / FlxG.height;
		var realRatio:Float = Width / Height;

		var scaleY:Bool = realRatio < ratio;

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
			for(camera in FlxG.cameras.list) {
				camera.width = FlxG.initialWidth;
				camera.height = FlxG.initialHeight;
			}

			FlxG.width = FlxG.initialWidth;
			FlxG.height = FlxG.initialHeight;
		}
	}
}