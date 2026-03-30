package funkin.backend.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.io.Path;
import sys.io.File;
#end

class StringMacro {
	@:dox(hide) public static macro function addLine(buf:Expr, args:Array<Expr>):Expr {
		var exprs = [];
		for (arg in args) {
			var expanded = expandInterpolatedString(buf, arg);
			if (expanded != null) {
				exprs = exprs.concat(expanded);
			} else {
				exprs.push(macro $buf.add($arg));
			}
		}
		return macro $b{exprs};
	}

	#if macro
	static function expandInterpolatedString(buf:Expr, arg:Expr):Array<Expr> {
		var posInfos = Context.getPosInfos(arg.pos);
		if (posInfos == null || posInfos.file == null) return null;

		var fileContent = File.getContent(posInfos.file);
		var lineStart = posInfos.min;
		var lineEnd = posInfos.max;

		if (lineEnd <= lineStart || lineEnd > fileContent.length) return null;

		var original = fileContent.substring(lineStart, lineEnd);

		var dollarBrace = "$" + "{";
		if (original.indexOf(dollarBrace) == -1) return null;

		var result = [];
		var regex = ~/\$\{([^}]+)\}/g;
		var lastIndex = 0;
		var isFirst = true;

		while (regex.matchSub(original, lastIndex)) {
			var matchPos = regex.matchedPos();
			var prefix = original.substring(lastIndex, matchPos.pos);
			if (prefix.length > 0) {
				if (isFirst && (prefix.charAt(0) == '"' || prefix.charAt(0) == "'".charAt(0))) {
					prefix = prefix.substr(1);
				}
				if (prefix.length > 0) {
					prefix = escapeString(prefix);
					result.push(macro $buf.add($v{prefix}));
				}
			}

			var exprStr = regex.matched(1);
			if (exprStr != null && exprStr.length > 0) {
				var expr = Context.parse(exprStr, arg.pos);
				result.push(macro $buf.add($expr));
			}

			lastIndex = matchPos.pos + matchPos.len;
			isFirst = false;
		}

		var remaining = original.substring(lastIndex);
		if (remaining.length > 0) {
			if (remaining.charAt(remaining.length - 1) == '"' || remaining.charAt(remaining.length - 1) == "'".charAt(0)) {
				remaining = remaining.substr(0, remaining.length - 1);
			}
			if (remaining.length > 0) {
				remaining = escapeString(remaining);
				result.push(macro $buf.add($v{remaining}));
			}
		}

		return result.length > 0 ? result : null;
	}

	static function escapeString(s:String):String {
		var r = new StringBuf();
		var i = 0;
		while (i < s.length) {
			var c = s.charAt(i);
			if (c == "\\" && i + 1 < s.length) {
				var next = s.charAt(i + 1);
				switch (next) {
					case "n": r.add("\n"); i += 2; continue;
					case "t": r.add("\t"); i += 2; continue;
					case "r": r.add("\r"); i += 2; continue;
					case "\\": r.add("\\"); i += 2; continue;
					case '"': r.add('"'); i += 2; continue;
					default: r.add(c); i++;
				}
			} else {
				r.add(c);
				i++;
			}
		}
		return r.toString();
	}
	#end
}