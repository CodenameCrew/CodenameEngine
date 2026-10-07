/**
* THIS FILE IS TEMPORARY UNTIL TRANSFORMS ARE AT A USEABLE STATE.
* TODO:
* 		- !!!! MOVE BACK TO SOURCE !!!!
* 		- Rotation
* 		- Skewing
* 		- Angle + Scale (like already at a angle)
*/

import funkin.editors.stage.StageEditor;
import funkin.editors.ui.UIWarningSubstate;
import funkin.backend.utils.WindowUtils;
import funkin.backend.utils.MatrixUtil;
import flixel.math.FlxAngle;
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

var allowClose = false;
function create() {
	WindowUtils.preventClosing = true;
	WindowUtils.resetClosing();
	WindowUtils.onClosing = function() {
		if(!allowClose)
			Lib.application.window.onClose.cancel();

		var substate;
		substate = new UIWarningSubstate("nuh uh", "you dont need to close goofus doofus", [
			{
				label: "Actually Exit",
				onClick: function(t) {
					allowClose = true;
					Lib.application.window.close();
				}
			},
			{
				label: "Reload State",
				onClick: function(t) {
					FlxG.switchState(new StageEditor(StageEditor.__stage));
				}
			},
			{
				label: "oh whoops",
				onClick: function(t) {
					substate.close();
				}
			}
		]);
	
		openSubState(substate);
	}
}

function destroy() {
	WindowUtils.preventClosing = false;
	WindowUtils.resetClosing();
	WindowUtils.onClosing = null;
}

function update() {
	if (FlxG.mouse.justPressed)
		lastRelative.set();

	if(FlxG.keys.justPressed.R) {
		trace("reloading");
		FlxG.switchState(new StageEditor(StageEditor.__stage));
	}
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

var oldSpritePos = FlxPoint.get();
function SCALE_BOTTOM_RIGHT(sprite, relative) {
	preRotBullshit(sprite, relative);
	genericScale(sprite, relative, true, true);
	postRotBullshit(sprite, relative);
}

/**
	ROTATION
**/
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


function SCALE_TOP_RIGHT(sprite, relative) {
	preRotBullshit(sprite, relative);
	genericOppositeScale(sprite, relative, true, true, false, true);
	postRotBullshit(sprite, relative);
}

function MOVE_CENTER(sprite, relative) {
	sprite.x = storedPos.x-relative.x;
	sprite.y = storedPos.y-relative.y;
}

function SCALE_TOP_LEFT(sprite, relative) {
	preRotBullshit(sprite, relative);
	genericOppositeScale(sprite, relative, true, true, true, true);
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

var lastRelative = FlxPoint.get();
var skewPoint1 = FlxPoint.get();
var skewPoint2 = FlxPoint.get();

function SKEW_LEFT(sprite, relative) {
	preRotBullshit(sprite, relative);
	if (!FlxG.keys.pressed.SHIFT) {
		genericOppositeScale(sprite, relative, true, false, true, false);
		postRotBullshit(sprite, relative);
	}

	skewPoint1.set(0, 0);
	skewPoint2.set(1, 0);
	gimmeSkewCorners(sprite, 0, 1);

	sprite.y = storedPos.y - relative.y * 0.5;
	sprite.skew.y += ((relative.y - lastRelative.y) * 0.02);

	lastRelative.set((FlxG.keys.pressed.SHIFT ? lastRelative.x : relative.x), relative.y);
}

function SKEW_BOTTOM(sprite, relative) {
	preRotBullshit(sprite, relative);
	if (!FlxG.keys.pressed.SHIFT) {
		genericScale(sprite, relative, false, true);
		postRotBullshit(sprite, relative);
	}

	skewPoint1.set(0, 0);
	skewPoint2.set(0, 1);
	gimmeSkewCorners(sprite, 0, 2);

	sprite.x = storedPos.x - relative.x * 0.4;
	sprite.skew.x -= ((relative.x - lastRelative.x) * 0.03);

	lastRelative.set(relative.x, (FlxG.keys.pressed.SHIFT ? lastRelative.y : relative.y));
}

function SKEW_TOP(sprite, relative) {
	preRotBullshit(sprite, relative);
	if (!FlxG.keys.pressed.SHIFT) {
		genericOppositeScale(sprite, relative, false, true, false, true);
		postRotBullshit(sprite, relative);
	}

	skewPoint1.set(0, 0);
	skewPoint2.set(0, 1);
	gimmeSkewCorners(sprite, 0, 2);

	sprite.x = storedPos.x - relative.x * 0.4;
	sprite.skew.x += ((relative.x - lastRelative.x) * 0.03);

	lastRelative.set(relative.x, (FlxG.keys.pressed.SHIFT ? lastRelative.y : relative.y));
}

function SKEW_RIGHT(sprite, relative) {
	preRotBullshit(sprite, relative);
	if (!FlxG.keys.pressed.SHIFT) {
		genericScale(sprite, relative, true, false);
		postRotBullshit(sprite, relative);
	}

	skewPoint1.set(0, 0);
	skewPoint2.set(1, 0);
	gimmeSkewCorners(sprite, 0, 1);

	sprite.y = storedPos.y - relative.y * 0.5;
	sprite.skew.y -= ((relative.y - lastRelative.y) * 0.02);

	lastRelative.set((FlxG.keys.pressed.SHIFT ? lastRelative.x : relative.x), relative.y);
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


/*function postDraw() {
	if(storedCenter.x != 0 || storedCenter.y != 0) {
		drawLine(storedCenter, storedRelative, 0.3);
	}
}*/

function gimmeSkewCorners(sprite, index1, index2) {
	if (sprite.angle == 0) {
		var corners = sprite.extra.get(exID("buttonBoxes"));
		skewPoint1.set(corners[index1].x, corners[index1].y);
		skewPoint2.set(corners[index2].x, corners[index2].y);
		return;
	}

	var ogAngle = sprite.angle;
	sprite.angle = 0;
	MatrixUtil.getMatrixPosition(sprite, [skewPoint1, skewPoint2], sprite.camera, sprite.frameWidth, sprite.frameHeight);
	sprite.angle = ogAngle;
}