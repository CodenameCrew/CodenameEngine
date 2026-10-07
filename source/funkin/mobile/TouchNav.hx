package funkin.mobile;

import flixel.FlxObject;

class TouchNav {
	public static function pointerJustPressed():Bool {
		#if (FLX_MOUSE && !mobile)
		if (FlxG.mouse.justPressed && !TouchControls.mouseCaptured) return true;
		#end
		#if FLX_TOUCH
		for (touch in FlxG.touches.list) if (isTap(touch)) return true;
		#end
		return false;
	}

	public static function justHit(object:FlxObject, ?camera:flixel.FlxCamera):Bool {
		return object != null && pointerJustPressed() && hits(object, camera);
	}

	public static function hits(object:FlxObject, ?camera:flixel.FlxCamera):Bool {
		if (object == null) return false;
		var cam = camera != null ? camera : (object.camera != null ? object.camera : FlxG.camera);

		#if (FLX_MOUSE && !mobile)
		if (FlxG.mouse.justPressed && !TouchControls.mouseCaptured && FlxG.mouse.overlaps(object, cam))
			return true;
		#end
		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
			if (isTap(touch) && touch.overlaps(object, cam)) {
				TouchControls.vibrate();
				return true;
			}
		#end
		return false;
	}

	#if FLX_TOUCH
	static inline function isTap(touch:flixel.input.touch.FlxTouch):Bool {
		return touch != null && touch.justReleased && TouchControls.isTap(touch.touchPointID) && !TouchControls.isCaptured(touch.touchPointID);
	}
	#end
}
