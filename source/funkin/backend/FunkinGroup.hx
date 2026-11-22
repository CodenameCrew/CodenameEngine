package funkin.backend;

import flixel.util.FlxSignal;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxAngle;
import flixel.addons.effects.FlxSkewedSprite;
import openfl.geom.ColorTransform;
import animate.FlxAnimate;
import animate.internal.RenderTexture;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.FlxCamera;
import flixel.text.FlxText;
import openfl.display.BlendMode;

/**
 * the FunkinGroup from vslice-modpack.... in source :D
 *
 * ---
 *
 * its kind of like CustomGroup except transforms are More advanced
 * and actually do stack unlike FlxSpriteGroup
 * (thats what i would say if i could get FunkinGroup inside FunkinGroup working)
 *
 * this should only be used when necessary, dont overuse it as its
 * quite complicated and can tear down performance
 * (would defnitely run better in source)
 * pls credit if used outside of this project ok thx
 */
class FunkinGroup extends FunkinSprite {
    var length(get, null):Int;
    function get_length():Int return members.length;

    public var memberAdded:FlxTypedSignal<(a:FlxSprite) -> Void> = new FlxTypedSignal<(a:FlxSprite) -> Void>();
    public var memberRemoved:FlxTypedSignal<(a:FlxSprite) -> Void> = new FlxTypedSignal<(a:FlxSprite) -> Void>();

	public var members:Array<FlxSprite> = [];
	public function add(a) { 
        members.push(a);
        memberAdded.dispatch(a);
        return a;
    }

	public function insert(x, a) {
        members.insert(x, a);
        memberAdded.dispatch(a);
        return a;
    }

	public function remove(a, ?s) {
        memberRemoved.dispatch(a);
        members.remove(a);
        return a;
    }

	public function new() {
		super();
	}

	public function forEach(f) {
		for (i in members) {
			if (i != null) f(i);
		}
	}
	public function forEachAlive(f) {
		for (i in members) {
			if (i == null || !i.alive || !i.exists) continue;
			f(i);
		}
	}
    override function destroy() {
		while (members.length > 0) {
            var bember = members.shift();
			bember.kill();
			bember.destroy();
		}
		super.destroy();
	}

    override public function update(elapsed) {
		super.update(elapsed);
		for (child in members) {
            if (child == null || !child.alive || !child.active || !child.exists) continue;
            child.update(elapsed);
        }
	}

    // TODO:automatic width and height updating
    override public function isOnScreen(?camera:FlxCamera) {
        return forceIsOnScreen || (
            x >= ((camera.scroll.x * scrollFactor.x) - width ) && x <= ((camera.scroll.x * scrollFactor.x) + camera.width) &&
            y >= ((camera.scroll.y * scrollFactor.y) - height) && y <= ((camera.scroll.y * scrollFactor.y) + camera.height)
        );
    }

    static var dumpCT = new ColorTransform();
	override public function draw() @:privateAccess {
        if (!visible || alpha <= 0 || !alive || !exists) return;
        var oldDefaultCameras = @:privateAccess FlxCamera._defaultCameras;
		if (_cameras != null) @:privateAccess FlxCamera._defaultCameras = _cameras;

        @:privateAccess for (camera in FlxCamera._defaultCameras) {
            if (!isOnScreen(camera)) return;
        }

        @:privateAccess dumpCT.__copyFrom(colorTransform);
		for (child in members) {
            if (child is FlxText) @:privateAccess cast(child, FlxText).regenGraphic();

            if (child.isFrameNull)
		    	child.checkEmptyFrame();

		    child.checkClipRect();
            if ((child.alpha <= 0) || (child._frame.type == FlxFrameType.EMPTY))
			    continue;
		
		    if (child.dirty) // rarely
			    child.calcFrame(child.useFramePixels);

            if ((child.shader != null) && (child.shader is FlxGraphicsShader))
			    child.shader.setCamSize(child._frame.frame.x, child._frame.frame.y, child._frame.frame.width, child._frame.frame.height);

            // dear santa, i wish for flixel to separate matrix math from actual screen drawing
            if (!child.visible || !child.exists || !child.alive) continue;
            for (camera in FlxCamera._defaultCameras) {
                if (!camera.visible || !camera.exists) continue;
                // shitty fix
                var ogX = camera.scroll.x, ogY = camera.scroll.y;
                camera.scroll.set();
                dumpCT.concat(child.colorTransform);

                var input = prepareDrawChild(child, camera);
                prepareDrawMatrix(_matrix, camera);
                /*if (
                    //child is FunkinGroup // for source
                    child.members != null // hscript only
                ) {
                    //child._matrix.concat(_matrix);
                    //child.draw();
                    funkin.backend.system.Logs.warn('[FunkinGroup] Nested groups are not supported! (yet)');
                    remove(child);
                } else {*/
                    var achild:FlxAnimate = null;
                    if (child is FlxAnimate) cast(child, FlxAnimate);
                    if (achild != null && achild.isAnimate) {
                        drawAnimateChild(achild, camera, ogX, ogY);
                    } else {
                        input.concat(_matrix);
                        input.translate(
                            -ogX * child.scrollFactor.x * scrollFactor.x,
                            -ogY * child.scrollFactor.y * scrollFactor.y
                        );
                        if (child.pixelPerfectRender ?? camera.pixelPerfectRender)
                        {
                            input.tx = Math.floor(input.tx);
                            input.ty = Math.floor(input.ty);
                        }
                        if (child._frame != null) {
                            if (layer != null) {
                                layer.drawPixels(
                                    child, camera,
                                    child._frame,
                                    child.framePixels,
                                    input,
                                    dumpCT,
                                    child.blend ?? blend,
                                    antialiasing && child.antialiasing,
                                    child.shaderEnabled ? child.shader : null,
                                    child.wrapMode
                                );
                            } else {
                                camera.drawPixels(
                                    child._frame,
                                    child.framePixels,
                                    input,
                                    dumpCT,
                                    child.blend ?? blend,
                                    antialiasing && child.antialiasing,
                                    child.shaderEnabled ? child.shader : null,
                                    child.wrapMode
                                );
                            }
                        }
                    }
                //}
                // reset everything
                child._matrix.identity();
                _matrix.identity();
                @:privateAccess dumpCT.__copyFrom(colorTransform);
                camera.scroll.set(ogX, ogY);
                _point.set(0, 0);
                child._point.set(0, 0);

                #if FLX_DEBUG
                FlxBasic.visibleCount++;
                #end
            }
        }
        
        FlxCamera._defaultCameras = oldDefaultCameras;
	}

    public function prepareDrawChild(child:FlxSprite, camera:FlxCamera) {
        final matrix = child._matrix;
        var achild:FlxAnimate = null;
        if (child is FlxAnimate) achild = cast(child, FlxAnimate);
        var isSkewable = false;
        if (achild != null) {
            isSkewable = true;
            if (achild.isAnimate) {
                achild.prepareAnimateMatrix(matrix, camera, achild.timeline._bounds);
                return matrix;
            }
        }
        final TO_RAD = 0.017453292519943295; // FlxAngle.TO_RAD is null in hscript (pls fix ???)

        child._frame.prepareMatrix(matrix, 0, child.checkFlipX(), child.checkFlipY());

        matrix.translate(-child.origin.x, -child.origin.y);

		if (child.frameOffsetAngle != null && child.frameOffsetAngle != child.angle)
		{
			var angleOff = (child.frameOffsetAngle - child.angle) * FlxAngle.TO_RAD;
			var cos = Math.cos(angleOff), sin = Math.sin(angleOff);
			// cos doesnt need to be negated
			matrix.rotateWithTrig(cos, -sin);
			matrix.translate(-child.frameOffset.x, -child.frameOffset.y);
			matrix.rotateWithTrig(cos, sin);
		}
		else
			matrix.translate(-child.frameOffset.x, -child.frameOffset.y);

		matrix.scale(child.scale.x, child.scale.y);

		if (child.bakedRotationAngle <= 0)
		{
            // updateTrig
			if (child._angleChanged)
            {
                var radians:Float = child.angle * TO_RAD;
                child._sinAngle = Math.sin(radians);
                child._cosAngle = Math.cos(radians);
                child._angleChanged = false;
            }
			
			matrix.rotateWithTrig(child._cosAngle, child._sinAngle);
		}

        if (isSkewable) {
            if (achild.matrixExposed) matrix.concat(achild.transformMatrix);
            else {
                if (achild.skew.x != 0 || achild.skew.y != 0)
                {
                    // updateSkew
                    FlxAnimate._skewMatrix.setTo(1, Math.tan(achild.skew.y * TO_RAD), Math.tan(achild.skew.x * TO_RAD), 1, 0, 0);
                    matrix.concat(FlxAnimate._skewMatrix);
                }
            }
        }

		//child.getScreenPosition(child._point, camera);
        child._point.set(child.x, child.y);
		if (child.pixelPerfectPosition)
			child._point.floor();

        child._point.subtract(
            camera.scroll.x * child.scrollFactor.x,
            camera.scroll.y * child.scrollFactor.y
        );

		camera.alterScreenPosition(child, child._point);

        child._point.x -= child.offset.x; child._point.y -= child.offset.y;
        child._point.x += child.origin.x; child._point.y += child.origin.y;
		matrix.translate(child._point.x, child._point.y);

		if (child.pixelPerfectRender ?? camera.pixelPerfectRender)
		{
			matrix.tx = Math.floor(matrix.tx);
			matrix.ty = Math.floor(matrix.ty);
		}

		//child.doAdditionalMatrixStuff(matrix, camera);
        return matrix;
    }

    // hook because i have to
    public function drawAnimateChild(child:FlxAnimate, camera:FlxCamera, ?ogX:Float, ?ogY:Float):Void
	{
		final willUseRenderTexture = child.checkRenderTexture() || (alpha < 1 || blend != null || blend != BlendMode.NORMAL);
		final matrix = child._matrix;
        matrix.identity();

		@:privateAccess
		var bounds = child.timeline._bounds;
		if (!willUseRenderTexture)
			matrix.translate(-bounds.x, -bounds.y);

        child.prepareAnimateMatrix(matrix, camera, bounds);

		if (child.renderStage)
			child.drawStage(camera);

		final command = child._drawCommand;
		command.parentSprite = child;
		command.transform = dumpCT;
		command.blend = child.blend;
		command.antialiasing = child.antialiasing;
		command.shader = child.shaderEnabled ? child.shader : null;
		command.wrapMode = child.wrapMode;
		//command.depthCompareMode = depthCompareMode;
		command.onSymbolDraw = child.onSymbolDraw;

		child.timeline.currentFrame = child.animation.frameIndex;

        function postMatrixShit() {
            //prepareDrawMatrix(_matrix, camera);
            matrix.concat(_matrix);
            matrix.translate(
                -ogX * child.scrollFactor.x * scrollFactor.x,
                -ogY * child.scrollFactor.y * scrollFactor.y
            );
            if (child.pixelPerfectRender ?? camera.pixelPerfectRender)
            {
                matrix.tx = Math.floor(matrix.tx);
                matrix.ty = Math.floor(matrix.ty);
            }
        }

		#if !flash
		if (willUseRenderTexture)
		{
            child.setupRenderTexture(camera, bounds, command, matrix);
            // this change
            postMatrixShit();
            child.drawRenderTexture(camera, matrix, command);
		}
		else
		#end
		{
            // this change
            postMatrixShit();
			child.timeline.draw(camera, matrix, command);
		}
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
// example script
var group = new FunkinGroup();
var groupCam = new FlxCamera();
function postCreate() {
    add(group);

    var test1 = new FunkinSprite(0, 0, Paths.image('menus/menuBG'));
    test1.setGraphicSize(400, 400);
    test1.updateHitbox();
    group.add(test1);

    var test2 = new FlxSprite(300, 300, Paths.image('icon'));
    group.add(test2);

    var richard = new FunkinSprite(0, 0, Paths.image('characters/gf'));
    richard.useRenderTexture = true;
    richard.antialiasing = true;
    richard.scale.set(0.67, 0.67);
    richard.addAnim('ou', 'GF Dancing Beat', 67, true);
    richard.playAnim('ou', true);
    richard.updateHitbox();
    richard.screenCenter();
    group.add(richard);

    // errors for now
    var group2 = new FunkinGroup();
    group.add(group2);

    var test3 = new FlxSprite(200, 100, Paths.image('mario'));
    group2.add(test2);

    group.antialiasing = true;

    //FlxG.cameras.add(groupCam, false);
    //groupCam.bgColor = 0x99000000;
    //group.camera = groupCam;
}

function postUpdate(elapsed) {
    final fuck = elapsed * 150;

    if (controls.LEFT) group.x -= fuck;
    if (controls.DOWN) group.y += fuck;
    if (controls.UP) group.y -= fuck;
    if (controls.RIGHT) group.x += fuck;

    if (FlxG.keys.pressed.Q) group.angle -= fuck * 0.5;
    if (FlxG.keys.pressed.E) group.angle += fuck * 0.5;

    if (FlxG.keys.pressed.J) group.scale.x -= fuck * 0.015;
    if (FlxG.keys.pressed.K) group.scale.y += fuck * 0.015;
    if (FlxG.keys.pressed.I) group.scale.y -= fuck * 0.015;
    if (FlxG.keys.pressed.L) group.scale.x += fuck * 0.015;

    if (FlxG.keys.pressed.NUMPADFOUR ) group.skew.x -= fuck * 0.55;
    if (FlxG.keys.pressed.NUMPADTWO  ) group.skew.y += fuck * 0.55;
    if (FlxG.keys.pressed.NUMPADEIGHT) group.skew.y -= fuck * 0.55;
    if (FlxG.keys.pressed.NUMPADSIX  ) group.skew.x += fuck * 0.55;
}
*/