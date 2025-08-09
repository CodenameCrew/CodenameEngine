package funkin.backend.utils;

import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;

final class DrawUtil {
	public static var line:FlxSprite = null;
	public static var dot:FlxSprite = null;
	public static var square:FlxSprite = null;

	public static inline function drawSquare(x:Float, y:Float, ?scale:Float = 1) {
		if (square == null) createDrawers();

		square.setPosition(x, y);

		square.scale.set(scale, scale);
		square.updateHitbox();
		
		square.x -= square.width / 2;
		square.y -= square.height / 2;
		square.draw();
	}

	public static inline function drawDot(x:Float, y:Float, ?scale:Float = 1) {
		if (dot == null) createDrawers();

		dot.setPosition(x, y);

		dot.scale.set(scale, scale);
		dot.updateHitbox();
		
		dot.x -= dot.width / 2;
		dot.y -= dot.height / 2;
		dot.draw();
	}

	public static inline function drawLine(point1:FlxPoint, point2:FlxPoint, thickness:Float = 1, ?color:Null<FlxColor>) {
		if (line == null) createDrawers();

		var dx:Float = point2.x - point1.x;
		var dy:Float = point2.y - point1.y;

		var angle:Float = Math.atan2(dy, dx);
		var distance:Float = Math.sqrt(dx * dx + dy * dy);

		// Math.ceil to prevent flickering
		line.setPosition(point1.x, point1.y);
		line.angle = angle * FlxAngle.TO_DEG;
		line.origin.set(0, line.frameHeight / 2);
		line.scale.x = distance / line.frameWidth;
		line.scale.y = thickness;
		line.y -= line.height / 2;
		if (color != null) line.color = color;
		line.draw();

		line.angle = 0;
		line.scale.x = line.scale.y = 1;
		line.updateHitbox();

		point1.putWeak(); point2.putWeak();
	}
 
	public static inline function drawRect(rect:FlxRect, thickness:Float = 1, ?color:Null<FlxColor>) {
		if (rect.width <= 0 || rect.height <= 0) return;
		DrawUtil.drawLine(FlxPoint.weak(rect.x, rect.y), FlxPoint.weak(rect.x + rect.width, rect.y), thickness, color);
		DrawUtil.drawLine(FlxPoint.weak(rect.x, rect.y), FlxPoint.weak(rect.x, rect.y + rect.height), thickness, color);
		DrawUtil.drawLine(FlxPoint.weak(rect.x + rect.width, rect.y), FlxPoint.weak(rect.x + rect.width, rect.y + rect.height), thickness, color);
		DrawUtil.drawLine(FlxPoint.weak(rect.x, rect.y + rect.height), FlxPoint.weak(rect.x + rect.width, rect.y + rect.height), thickness, color);
	}

	public static inline function createDrawers() {
		dot = new FlxSprite().loadGraphic(Paths.image("editors/stage/selectionDot"), true, 32, 32);
		dot.antialiasing = true;
		dot.animation.add("default", [0], 0, false);
		dot.animation.add("hollow", [1], 0, false);
		dot.animation.play("default");
		dot.camera = FlxG.camera;
		dot.forceIsOnScreen = true;

		line = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		line.camera = FlxG.camera;
		line.forceIsOnScreen = true;

		square = new FlxSprite().makeGraphic(32, 32, FlxColor.WHITE);
		square.camera = FlxG.camera;
		square.forceIsOnScreen = true;
	}

	public static function destroyDrawers() {
		if(dot != null) {
			dot.destroy();
			dot = null;
		}
		if(line != null) {
			line.destroy();
			line = null;
		}
		if(square != null) {
			square.destroy();
			square = null;
		}
	}
}