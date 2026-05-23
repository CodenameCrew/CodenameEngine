package;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.FlxBasic;
#if mobile
class Mouse extends FlxBasic {
    public static var holdDelay:Float = 0.25; 
    public static var clickThreshold:Float = 10.0;

    private var pressTime:Float = 0;
    private var isPressing:Bool = false;
    private var isDragging:Bool = false;
    private var startPos:FlxPoint;

    private var realPressed:Bool = false;
    private var realJustPressed:Bool = false;
    private var realJustReleased:Bool = false;

    public function new() {
        super();
        startPos = FlxPoint.get();
    }

    override public function update(elapsed:Float):Void {
        realPressed = FlxG.mouse.pressed;
        realJustPressed = FlxG.mouse.justPressed;
        realJustReleased = FlxG.mouse.justReleased;

        if (realJustPressed) {
            pressTime = 0;
            isPressing = true;
            isDragging = false;
            startPos.set(FlxG.mouse.x, FlxG.mouse.y);
        }

        if (isPressing && realPressed) {
            pressTime += elapsed;
            if (!isDragging && pressTime >= holdDelay) {
                isDragging = true;
            }
        }

        var forceJustPressed:Bool = false;
        var forceJustReleased:Bool = false;

        if (realJustReleased) {
            if (isPressing) {
                var endPos:FlxPoint = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
                var distance:Float = startPos.distanceTo(endPos);
                endPos.put();

                if (pressTime < holdDelay && distance < clickThreshold) {
                    forceJustPressed = true;
                    forceJustReleased = true;
                }
            }
            isPressing = false;
            isDragging = false;
        }

        @:privateAccess {
            if (isDragging) {
                FlxG.mouse._leftButton.current = 1; 
            } else {
                if (forceJustPressed) {
                    FlxG.mouse._leftButton.current = 2; 
                } else if (forceJustReleased) {
                    FlxG.mouse._leftButton.current = -1; 
                } else {
                    FlxG.mouse._leftButton.current = 0; 
                }
            }
        }

        super.update(elapsed);
    }

    override public function destroy():Void {
        startPos = FlxDestroyUtil.put(startPos);
        super.destroy();
    }
}
#end
