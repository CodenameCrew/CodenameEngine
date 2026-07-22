package funkin.backend;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.system.Flags;

class FunkinText extends FlxText
{
    public var zoomFactor:Float = 1;
    public var zoomFactorEnabled:Bool = true;
    public var angleFactor:Float = 1;
    public var angleFactorEnabled:Bool = true;

    public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, ?Size:Int, Border:Bool = true)
    {
        if (Size == null)
            Size = Flags.DEFAULT_FONT_SIZE;

        super(X, Y, FieldWidth, Text, Size);

        setFormat(Paths.font(Flags.DEFAULT_FONT), Size, FlxColor.WHITE);

        if (Border)
        {
            borderStyle = OUTLINE;
            borderSize = 1;
            borderColor = 0xFF000000;
        }
    }

    private inline function __shouldDoZoomFactor():Bool
    {
        return zoomFactorEnabled && zoomFactor != 1;
    }

    private inline function __getZoomScaleX(camera:FlxCamera):Float
    {
        return (camera.scaleX > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleX, 1, zoomFactor));
    }

    private inline function __getZoomScaleY(camera:FlxCamera):Float
    {
        return (camera.scaleY > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleY, 1, zoomFactor));
    }

    private inline function __getZoomAnchorX(camera:FlxCamera):Float
    {
        if (Flags.USE_LEGACY_ZOOM_FACTOR)
            return camera.width * 0.5 - origin.x;

        return camera.width * 0.5 + camera.scroll.x * scrollFactor.x - origin.x;
    }

    private inline function __getZoomAnchorY(camera:FlxCamera):Float
    {
        if (Flags.USE_LEGACY_ZOOM_FACTOR)
            return camera.height * 0.5 - origin.y;

        return camera.height * 0.5 + camera.scroll.y * scrollFactor.y - origin.y;
    }

    private inline function __getAngleAnchorX(camera:FlxCamera):Float
    {
        if (Flags.USE_LEGACY_ZOOM_FACTOR)
            return camera.width * 0.5 - origin.x;

        return camera.width * 0.5 + camera.scroll.x * scrollFactor.x - origin.x;
    }

    private inline function __getAngleAnchorY(camera:FlxCamera):Float
    {
        if (Flags.USE_LEGACY_ZOOM_FACTOR)
            return camera.height * 0.5 - origin.y;

        return camera.height * 0.5 + camera.scroll.y * scrollFactor.y - origin.y;
    }

    private inline function __shouldDoAngleFactor():Bool
    {
        return angleFactorEnabled && angleFactor != 1;
    }

    private inline function __prepareAngleFactor(camera:FlxCamera):Float
    {
        return FlxMath.lerp(-camera.angle, 0, angleFactor);
    }

    override public function draw():Void
    {
        if (!__shouldDoZoomFactor() && !__shouldDoAngleFactor())
        {
            super.draw();
            return;
        }

        var camera:FlxCamera = this.camera;

        if (camera == null)
            camera = FlxG.camera;

        var oldX:Float = x;
        var oldY:Float = y;
        var oldScaleX:Float = scale.x;
        var oldScaleY:Float = scale.y;
        var oldAngle:Float = angle;

        if (__shouldDoZoomFactor())
        {
            var zoomScaleX:Float = __getZoomScaleX(camera);
            var zoomScaleY:Float = __getZoomScaleY(camera);

            var anchorX:Float = __getZoomAnchorX(camera);
            var anchorY:Float = __getZoomAnchorY(camera);

            x = (x - anchorX) * zoomScaleX + anchorX;
            y = (y - anchorY) * zoomScaleY + anchorY;

            scale.set(scale.x * zoomScaleX, scale.y * zoomScaleY);
        }

        if (__shouldDoAngleFactor())
        {
            var anchorX:Float = __getAngleAnchorX(camera);
            var anchorY:Float = __getAngleAnchorY(camera);
            var prepAngle:Float = __prepareAngleFactor(camera);

            var rad:Float = prepAngle * (Math.PI / 180);
            var cos:Float = Math.cos(rad);
            var sin:Float = Math.sin(rad);

            var dx:Float = x - anchorX;
            var dy:Float = y - anchorY;

            x = dx * cos - dy * sin + anchorX;
            y = dx * sin + dy * cos + anchorY;
            angle += prepAngle;
        }

        super.draw();

        x = oldX;
        y = oldY;
        scale.set(oldScaleX, oldScaleY);
        angle = oldAngle;
    }
}