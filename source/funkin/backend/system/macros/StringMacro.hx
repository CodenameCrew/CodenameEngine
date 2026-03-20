package funkin.backend.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class StringMacro {
	@:dox(hide) public static macro function addLine(buf:Expr, args:Array<Expr>):Expr {
		var exprs = [];
		for (arg in args)
			exprs.push(macro $buf.add($arg));
		return macro $b{exprs};
	}
}