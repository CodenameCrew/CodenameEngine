package funkin.backend.utils;

final class MathUtil {
    //Remind me to add the descriptions for the Wiki later - sen
    public static inline function lessThan(aVal:Float, bVal:Float, diff:Float = FlxMath.EPSILON):Bool {
        return aVal < bVal - diff;
    }

    public static inline function lessThanEqual(aVal:Float, bVal:Float, diff:Float = FlxMath.EPSILON):Bool {
        return aVal <= bVal + diff;
    }

    public static inline function greaterThan(aVal:Float, bVal:Float, diff:Float = FlxMath.EPSILON):Bool {
        return aVal > bVal + diff;
    }

    public static inline function greaterThanEqual(aVal:Float, bVal:Float, diff:Float = FlxMath.EPSILON):Bool {
        return aVal >= bVal - diff;
    }

    public static inline function equal(aVal:Float, bVal:Float, diff:Float = FlxMath.EPSILON):Bool {
        return Math.abs(aVal - bVal) <= diff;
    }

    public static inline function notEqual(aVal:Float, bVal:Float, diff:Float = FlxMath.EPSILON):Bool {
        return Math.abs(aVal - bVal) > diff;
    }
}