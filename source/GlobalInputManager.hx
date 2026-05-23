package;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.FlxBasic;
import flixel.input.touch.FlxTouch;
import mobile.controls.VirtualPad;

#if mobile
class GlobalInputManager extends FlxBasic {
    public static var holdDelay:Float = 0.25; 
    public static var clickThreshold:Float = 10.0;

    private var pressTime:Float = 0;
    private var isPressing:Bool = false;
    private var isDragging:Bool = false;
    private var startPos:FlxPoint;
    
    private var trackedTouchID:Int = -1;

    private var simulatedState:Int = 0; 
    private var pendingTapRelease:Bool = false;

    public function new() {
        super();
        startPos = FlxPoint.get();
    }

    override public function update(elapsed:Float):Void {
        if (VirtualPad.touchingPad) {
            isPressing = false;
            isDragging = false;
            trackedTouchID = -1;
            simulatedState = 0;
            pendingTapRelease = false;
            
            @:privateAccess FlxG.mouse._leftButton.current = 0;
            super.update(elapsed);
            return;
        }

        var activeTouch:FlxTouch = null;

        if (trackedTouchID != -1) {
            for (touch in FlxG.touches.list) {
                if (touch.touchPointID == trackedTouchID) {
                    activeTouch = touch;
                    break;
                }
            }
        } else {
            for (touch in FlxG.touches.list) {
                if (touch.justPressed) {
                    activeTouch = touch;
                    trackedTouchID = touch.touchPointID;
                    break;
                }
            }
        }

        var rawJustPressed:Bool = false;
        var rawPressed:Bool = false;
        var rawJustReleased:Bool = false;
        var tx:Float = 0;
        var ty:Float = 0;

        if (activeTouch != null) {
            rawJustPressed = activeTouch.justPressed;
            rawPressed = activeTouch.pressed;
            rawJustReleased = activeTouch.justReleased;
            tx = activeTouch.x;
            ty = activeTouch.y;
            
            if (rawJustReleased) {
                trackedTouchID = -1;
            }
        }

        if (rawJustPressed) {
            pressTime = 0;
            isPressing = true;
            isDragging = false;
            startPos.set(tx, ty);
        }

        if (isPressing && rawPressed) {
            pressTime += elapsed;
            var currentPos = FlxPoint.weak(tx, ty);
            var distance = startPos.distanceTo(currentPos);

            if (!isDragging && (pressTime >= holdDelay || distance >= clickThreshold)) {
                isDragging = true;
                simulatedState = 2;
            }
        }

        if (rawJustReleased && isPressing) {
            if (!isDragging) {
                simulatedState = 2;
                pendingTapRelease = true;
            } else {
                simulatedState = -1;
            }
            isPressing = false;
            isDragging = false;
        }

        @:privateAccess {
            if (simulatedState == -1) {
                FlxG.mouse._leftButton.current = -1;
                simulatedState = 0;
            }
            else if (simulatedState == 2) {
                FlxG.mouse._leftButton.current = 2;
                if (activeTouch != null) {
                    FlxG.mouse.x = Std.int(tx);
                    FlxG.mouse.y = Std.int(ty);
                    FlxG.mouse.screenX = activeTouch.screenX;
                    FlxG.mouse.screenY = activeTouch.screenY;
                }
                
                if (pendingTapRelease) {
                    simulatedState = -1;
                    pendingTapRelease = false;
                } else {
                    simulatedState = 1;
                }
            }
            else if (simulatedState == 1) {
                if (!isDragging && !isPressing) {
                    simulatedState = 0;
                    FlxG.mouse._leftButton.current = 0;
                } else {
                    FlxG.mouse._leftButton.current = 1;
                    if (activeTouch != null) {
                        FlxG.mouse.x = Std.int(tx);
                        FlxG.mouse.y = Std.int(ty);
                        FlxG.mouse.screenX = activeTouch.screenX;
                        FlxG.mouse.screenY = activeTouch.screenY;
                    }
                }
            }
            else {
                FlxG.mouse._leftButton.current = 0;
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
