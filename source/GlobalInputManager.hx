package;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.FlxBasic;

#if mobile
class GlobalInputManager extends FlxBasic {
    public static var holdDelay:Float = 0.25; 
    public static var clickThreshold:Float = 10.0;

    private var pressTime:Float = 0;
    private var isPressing:Bool = false;
    private var isDragging:Bool = false;
    private var startPos:FlxPoint;

    public function new() {
        super();
        startPos = FlxPoint.get();
    }

    override public function update(elapsed:Float):Void {
        var rawPressed:Bool = FlxG.mouse.pressed;
        var rawJustPressed:Bool = FlxG.mouse.justPressed;
        var rawJustReleased:Bool = FlxG.mouse.justReleased;

        if (rawJustPressed) {
            pressTime = 0;
            isPressing = true;
            isDragging = false;
            startPos.set(FlxG.mouse.x, FlxG.mouse.y);
        }

        if (isPressing && rawPressed) {
            pressTime += elapsed;
            if (!isDragging && pressTime >= holdDelay) {
                isDragging = true;
            }
        }

        var triggerClick:Bool = false;

        if (rawJustReleased) {
            if (isPressing) {
                var endPos:FlxPoint = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
                var distance:Float = startPos.distanceTo(endPos);
                endPos.put();

                if (pressTime < holdDelay && distance < clickThreshold) {
                    triggerClick = true;
                }
            }
            isPressing = false;
            isDragging = false;
        }

        @:privateAccess {
            if (isDragging && rawPressed) {
                FlxG.mouse._leftButton.current = 1;
            } else if (triggerClick) {
                FlxG.mouse._leftButton.current = 2;
            } else if (rawJustReleased && !isDragging) {
                FlxG.mouse._leftButton.current = -1;
            } else {
                FlxG.mouse._leftButton.current = FlxG.mouse.pressed ? 1 : 0;
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
