package funkin.backend.utils;

import haxe.macro.Expr;

final class MathUtil {
	/**
	 * Returns the maximum value in the arguments.
	 * @param args Array of values
	 *
	 * @return The maximum value
	**/
	public static function maxInt(...args:Int):Int {
		var max = args[0];
		for(i in 1...args.length) {
			var arg = args[i];
			if(arg > max)
				max = arg;
		}
		return max;
	}

	/**
	 * Returns the minimum value in the arguments.
	 * @param args Array of values
	 *
	 * @return The minimum value
	**/
	public static function minInt(...args:Int):Int {
		var min = args[0];
		for(i in 1...args.length) {
			var arg = args[i];
			if(arg < min)
				min = arg;
		}
		return min;
	}

	/**
	 * Returns the maximum value in the arguments.
	 *
	 * NOTE: If you are using this in compile time, you should use `MathUtil.maxSmart` instead of this for better performance.
	 *
	 * @param args Array of values
	 *
	 * @return The maximum value
	**/
	public static function max(...args:Float):Float {
		var max = args[0];
		for(i in 1...args.length) {
			var arg = args[i];
			if(arg > max)
				max = arg;
		}
		return max;
	}

	/**
	 * Returns the minimum value in the arguments.
	 *
	 * NOTE: If you are using this in compile time, you should use `MathUtil.minSmart` instead of this for better performance.
	 *
	 * @param args Array of values
	 *
	 * @return The minimum value
	**/
	public static function min(...args:Float):Float {
		var min = args[0];
		for(i in 1...args.length) {
			var arg = args[i];
			if(arg < min)
				min = arg;
		}
		return min;
	}

	/**
	 * Checks if a is less than b with considering a margin of error.
	 * 
	 * @param a Float
	 * @param b Float
	 * @param margin Float (Default: EPSILON)
	 * 
	 * @return Bool
	**/
	public static function lessThan(a:Float, b:Float, margin:Float = 0.0000001):Bool {
		return a < b - margin;
	}

	/**
	 * Checks if a is less than or equally b with considering a margin of error.
	 * 
	 * @param a Float
	 * @param b Float
	 * @param margin Float (Default: EPSILON)
	 * 
	 * @return Bool
	**/
	public static function lessThanEqual(a:Float, b:Float, margin:Float = 0.0000001):Bool {
		return a <= b - margin;
	}

	/**
	 * Checks if a is greater than b with considering a margin of error.
	 * 
	 * @param a Float
	 * @param b Float
	 * @param margin Float (Default: EPSILON)
	 * 
	 * @return Bool
	**/
	public static function greaterThan(a:Float, b:Float, margin:Float = 0.0000001):Bool {
		return a > b + margin;
	}

	/**
	 * Checks if a is greater than or equally b with considering a margin of error.
	 * 
	 * @param a Float
	 * @param b Float
	 * @param margin Float (Default: EPSILON)
	 * 
	 * @return Bool
	**/
	public static function greaterThanEqual(a:Float, b:Float, margin:Float = 0.0000001):Bool {
		return a >= b + margin;
	}

	/**
	 * Checks if a is approximately equal to b.
	 * 
	 * @param a Float
	 * @param b Float
	 * @param margin Float (Default: EPSILON)
	 * 
	 * @return Bool
	**/
	public static function equal(a:Float, b:Float, margin:Float = 0.0000001):Bool {
		return Math.abs(a - b) <= margin;
	}

	/**
	 * Checks if a are not approximately equal to b.
	 * 
	 * @param a Float
	 * @param b Float
	 * @param margin Float (Default: EPSILON)
	 * 
	 * @return Bool
	**/
	public static function notEqual(a:Float, b:Float, margin:Float = 0.0000001):Bool {
		return Math.abs(a - b) > margin;
	}

	/**
	 * Shortcut to `Math.max` but with infinite amount of arguments
	 *
	 * Might not preserve the order of arguments, please test this.
	 *
	 * Dont use this in hscript, it doesnt work, it only works on compile time
	**/
	@:dox(hide) public static macro function maxSmart(..._args:Expr):Expr {
		return genericMinMaxSmart(_args.toArray(), "Math.max");
	}

	/**
	 * Shortcut to `Math.min` but with infinite amount of arguments
	 *
	 * Might not preserve the order of arguments, please test this.
	 *
	 * Dont use this in hscript, it doesnt work, it only works on compile time
	**/
	@:dox(hide) public static macro function minSmart(..._args:Expr):Expr {
		return genericMinMaxSmart(_args.toArray(), "Math.min");
	}

	#if macro
	@:dox(hide) private static function genericMinMaxSmart(_args:Array<Expr>, funcPath:String):Expr {
		var args = _args.copy();
		if (args.length == 0) return macro 0;

		var func = funcPath.split(".");

		function nested(lst:Array<Expr>):Expr {
			if (lst.length == 1) {
				return macro ${lst[0]};
			} else if (lst.length == 2) {
				return macro $p{func}(${lst[0]}, ${lst[1]});
			} else {
				var mid = Std.int(lst.length / 2);
				return macro $p{func}(${nested(lst.slice(0, mid))}, ${nested(lst.slice(mid, lst.length))});
			}
		}

		var expr = nested(args);

		//var printer = new haxe.macro.Printer();
		//trace(printer.printExpr(expr));

		return macro $expr;
	}
	#end
}