/**
* THIS FILE IS TEMPORARY UNTIL TRANSFORMS ARE AT A USEABLE STATE.
* TODO:
* 		- !!!! MOVE BACK TO SOURCE !!!!
* 		- Rotation
* 		- Skewing
* 		- Angle + Scale (like already at a angle)
*/

import flixel.FlxSprite;
import funkin.editors.stage.StageEditor;
import funkin.editors.ui.UIWarningSubstate;
import funkin.backend.utils.WindowUtils;
import funkin.backend.utils.MatrixUtil;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import openfl.Lib;

var exID = StageEditor.exID;

function tryUpdateHitbox(sprite) {
	var spriteNode = sprite.extra.get(exID("node"));
	if (spriteNode.exists("updateHitbox") && spriteNode.get("updateHitbox") == "true") {
		sprite.updateHitbox();
		return true;
	}

	if (!FlxG.keys.pressed.ALT) {
		sprite.x = storedPos.x - (sprite.frameWidth * (storedScale.x - sprite.scale.x) * 0.5);
		sprite.y = storedPos.y - (sprite.frameHeight * (storedScale.y - sprite.scale.y) * 0.5);
	}
	return false;
}

function genericScale(sprite, relative, doX, doY) {
	var relativeMult = 1 / (FlxMath.lerp(1, stageCamera.zoom, sprite.zoomFactor) / stageCamera.zoom) * (FlxG.keys.pressed.ALT ? 2 : 1);
	relative.x *= relativeMult;
	relative.y *= relativeMult;

	var width = sprite.frameWidth * storedScale.x;
	var height = sprite.frameHeight * storedScale.y;
	if(doX) width -= relative.x;
	if(doY) height -= relative.y;
	CoolUtil.setGraphicSizeFloat(sprite, width, height);

	if(FlxG.keys.pressed.SHIFT) {
		var nscale = Math.max(sprite.scale.x, sprite.scale.y);
		sprite.scale.set(nscale, nscale);
	}

	var updatedHitbox = tryUpdateHitbox(sprite);
	if (FlxG.keys.pressed.ALT) {
		sprite.x = storedPos.x;
		sprite.y = storedPos.y;
		if(updatedHitbox) {
			sprite.x += (sprite.frameWidth * (storedScale.x - sprite.scale.x) * 0.5);
			sprite.y += (sprite.frameHeight * (storedScale.y - sprite.scale.y) * 0.5);
		}
		return true;
	}
	return !updatedHitbox;
}

function genericOppositeScale(sprite, relative, scaleX, scaleY, repositionX, repositionY) {
	if(repositionX) relative.x *= -1;
	if(repositionY) relative.y *= -1;
	var repositioned = genericScale(sprite, relative, scaleX, scaleY);
	if (!repositioned) {
		if(repositionX) sprite.x = storedPos.x + (sprite.frameWidth * (storedScale.x - sprite.scale.x));
		if(repositionY) sprite.y = storedPos.y + (sprite.frameHeight * (storedScale.y - sprite.scale.y));
	} else if (!FlxG.keys.pressed.ALT) {
		if(repositionX) sprite.x += (sprite.frameWidth * (storedScale.x - sprite.scale.x));
		if(repositionY) sprite.y += (sprite.frameHeight * (storedScale.y - sprite.scale.y));
	}
}

function mouseModeChanged(sprite) {
	// SKEW_TOP = 10, LEFT = 11, RIGHT = 12, BOTTOM = 13
	if (mouseMode == 10 || mouseMode == 13) {
		skewPoint1.set(0, 0);
		skewPoint2.set(0, 1);
		gimmeSkewBounds(sprite);
		applySkewPoints(sprite);
		lastSkewSize = skewSize.x;
	} else if (mouseMode == 11 || mouseMode == 12) {
		skewPoint1.set(0, 0);
		skewPoint2.set(1, 0);
		gimmeSkewBounds(sprite);
		applySkewPoints(sprite);
		lastSkewSize = skewSize.y;
	}
}

/**
	ROTATION
**/
var oldSpritePos = FlxPoint.get();
function preRotBullshit(sprite, relative) {
	if (sprite.angle != 0)
		relative = rotateByDegrees(relative, -sprite.angle);

	if (FlxG.mouse.justPressed) {
		oldSpritePos.x = sprite.x;
		oldSpritePos.y = sprite.y;
	}
}

function postRotBullshit(sprite, relative) {
	if (sprite.angle != 0) {
		var p = rotateAround(FlxPoint.get(sprite.x, sprite.y), oldSpritePos, sprite.angle);
		sprite.x = p.x;
		sprite.y = p.y;
	}
}

function rotateAround(p, origin, angle) {
	var rel = FlxPoint.get(p.x - origin.x, p.y - origin.y);
	rotateByDegrees(rel, angle);
	p.x = origin.x + rel.x;
	p.y = origin.y + rel.y;
	rel.put();
	return p;
}
function rotateByDegrees(p, angle) {
	var rads = angle * FlxAngle.TO_RAD;
	var s:Float = Math.sin(rads);
	var c:Float = Math.cos(rads);
	var tempX:Float = p.x;

	p.x = tempX * c - p.y * s;
	p.y = tempX * s + p.y * c;
}
 /**
	END OF ROTATION
 **/


function MOVE_CENTER(sprite, relative) {
	sprite.x = storedPos.x-relative.x;
	sprite.y = storedPos.y-relative.y;
}

function SCALE_TOP_RIGHT(sprite, relative) {
	preRotBullshit(sprite, relative);
	genericOppositeScale(sprite, relative, true, true, false, true);
	postRotBullshit(sprite, relative);
}

function SCALE_TOP_LEFT(sprite, relative) {
	preRotBullshit(sprite, relative);
	genericOppositeScale(sprite, relative, true, true, true, true);
	postRotBullshit(sprite, relative);
}

function SCALE_BOTTOM_RIGHT(sprite, relative) {
	preRotBullshit(sprite, relative);
	genericScale(sprite, relative, true, true);
	postRotBullshit(sprite, relative);
}

function SCALE_BOTTOM_LEFT(sprite, relative) {
	preRotBullshit(sprite, relative);
	genericOppositeScale(sprite, relative, true, true, true, false);
	postRotBullshit(sprite, relative);
}

function SCALE_LEFT(sprite, relative) {
	preRotBullshit(sprite, relative);
	genericOppositeScale(sprite, relative, true, false, true, false);
	postRotBullshit(sprite, relative);
}

function SCALE_RIGHT(sprite, relative) {
	preRotBullshit(sprite, relative);
	genericScale(sprite, relative, true, false);
	postRotBullshit(sprite, relative);
}

function SCALE_TOP(sprite, relative) {
	preRotBullshit(sprite, relative);
	genericOppositeScale(sprite, relative, false, true, false, true);
	postRotBullshit(sprite, relative);
}

function SCALE_BOTTOM(sprite, relative) {
	preRotBullshit(sprite, relative);
	genericScale(sprite, relative, false, true);
	postRotBullshit(sprite, relative);
}

var toDeg = 180 / Math.PI; // the constants stopped working
var toRad = Math.PI / 180;
var skewInfo = FlxRect.get();
var skewSize = FlxPoint.get();
var lastSkewSize = 0;
var skewPoint1 = FlxPoint.get();
var skewPoint2 = FlxPoint.get();

function SKEW_LEFT(sprite, relative) {
	if (!FlxG.keys.pressed.SHIFT) {
		var lastX = relative.x;
		var lastY = relative.y;
		preRotBullshit(sprite, relative);
		genericOppositeScale(sprite, relative, true, false, true, false);
		postRotBullshit(sprite, relative);
		relative.set(lastX, lastY);
	}

	sprite.skew.y = CoolUtil.bound(Math.atan2(
		skewPoint2.y - (skewPoint1.y - relative.y),
		skewPoint2.x - (skewPoint1.x - (FlxG.keys.pressed.SHIFT ? 0 : relative.x))
	) * toDeg, -89, 89);
	gimmeSkewBounds(sprite);
	sprite.y = storedPos.y - (skewSize.y - lastSkewSize) * 0.5;
}

function SKEW_BOTTOM(sprite, relative) {
	if (!FlxG.keys.pressed.SHIFT) {
		var lastX = relative.x;
		var lastY = relative.y;
		preRotBullshit(sprite, relative);
		genericScale(sprite, relative, false, true);
		postRotBullshit(sprite, relative);
		relative.set(lastX, lastY);
	}

	sprite.skew.x = CoolUtil.bound(Math.atan2(
		(skewPoint2.x - relative.x) - skewPoint1.x,
		(skewPoint2.y - (FlxG.keys.pressed.SHIFT ? 0 : relative.y)) - skewPoint1.y
	) * toDeg, -89, 89);
	gimmeSkewBounds(sprite);
	sprite.x = storedPos.x + (skewSize.x - lastSkewSize) * 0.5;
}

function SKEW_TOP(sprite, relative) {
	if (!FlxG.keys.pressed.SHIFT) {
		var lastX = relative.x;
		var lastY = relative.y;
		preRotBullshit(sprite, relative);
		genericOppositeScale(sprite, relative, false, true, false, true);
		postRotBullshit(sprite, relative);
		relative.set(lastX, lastY);
	}

	sprite.skew.x = CoolUtil.bound(Math.atan2(
		skewPoint2.x - (skewPoint1.x - relative.x),
		skewPoint2.y - (skewPoint1.y - (FlxG.keys.pressed.SHIFT ? 0 : relative.y))
	) * toDeg, -89, 89);
	gimmeSkewBounds(sprite);
	sprite.x = storedPos.x - (skewSize.x - lastSkewSize) * 0.5;
}

function SKEW_RIGHT(sprite, relative) {
	if (!FlxG.keys.pressed.SHIFT) {
		var lastX = relative.x;
		var lastY = relative.y;
		preRotBullshit(sprite, relative);
		genericScale(sprite, relative, true, false);
		postRotBullshit(sprite, relative);
		relative.set(lastX, lastY);
	}

	sprite.skew.y = CoolUtil.bound(Math.atan2(
		(skewPoint2.y - relative.y) - skewPoint1.y,
		(skewPoint2.x - (FlxG.keys.pressed.SHIFT ? 0 : relative.x)) - skewPoint1.x
	) * toDeg, -89, 89);
	gimmeSkewBounds(sprite);
	sprite.y = storedPos.y + (skewSize.y - lastSkewSize) * 0.5;
}

function ROTATE(sprite, relative) {
	var buttonBoxes:Array<FlxPoint> = sprite.extra.get(exID("buttonBoxes"));
	var p:FlxPoint = buttonBoxes[8];

	FlxG.mouse.getWorldPosition(stageCamera, _point);

	var dx:Float = _point.x - p.x;
	var dy:Float = _point.y - p.y;
	var angle = FlxAngle.angleFromOrigin(dx, dy, true) + angleOffset;
	if(FlxG.keys.pressed.SHIFT) angle = Std.int(angle / 45) * 45;
	sprite.angle = angle;
}


function gimmeSkewBounds(sprite) {
	skewInfo.set(
		sprite.x + sprite.offset.x + sprite.frameWidth * 0.5,
		sprite.y + sprite.offset.y + sprite.frameHeight * 0.5,
		sprite.frameWidth * sprite.scale.x * sprite._cosAngle + sprite.frameHeight * sprite.scale.y * sprite._sinAngle,
		sprite.frameWidth * sprite.scale.x * sprite._sinAngle + sprite.frameHeight * sprite.scale.y * sprite._cosAngle
	);
	skewSize.set(
		skewInfo.height * Math.tan(sprite.skew.x * toRad),
		skewInfo.width * Math.tan(sprite.skew.y * toRad)
	);
}
function applySkewPoints(sprite) {
	skewPoint1.set(
		(skewInfo.x + skewSize.x * (skewPoint1.y - 0.5)) + skewInfo.width * skewPoint1.x,
		(skewInfo.y + skewSize.y * (skewPoint1.x - 0.5)) + skewInfo.height * skewPoint1.y
	);
	skewPoint2.set(
		(skewInfo.x + skewSize.x * (skewPoint2.y - 0.5)) + skewInfo.width * skewPoint2.x,
		(skewInfo.y + skewSize.y * (skewPoint2.x - 0.5)) + skewInfo.height * skewPoint2.y
	);
}