package funkin.backend.system.macros;

#if macro
import haxe.macro.Expr;
import haxe.macro.*;

using StringTools;
using haxe.macro.PositionTools;

class HashLinkFixer {
	public static var buildMacroString = '@:build(funkin.backend.system.macros.HashLinkFixer.build())';

	public static var applyOn:Array<String> = [
		"lime",
		"std",
		"Math",
		"",
	];

	public static var modifiedClasses:Array<String> = [];

	public static function init() {
		#if !display
		if(Context.defined("hl")) {
			for(apply in applyOn) {
				compile(apply);
			}
		}
		#end
	}

	public static function compile(name:String) {
		#if !display
		Compiler.addGlobalMetadata(name, buildMacroString);
		#end
	}

	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var clRef = Context.getLocalClass();
		if (clRef == null) return fields;
		var cl = clRef.get();

		if (cl.isAbstract || cl.isExtern || cl.isInterface) return fields;
		if (!cl.name.endsWith("_Impl_") && !cl.name.endsWith("_HSX") && !cl.name.endsWith("_HSC")) {
			if(cl.params.length > 0)
				return fields;

			var definedFields = [];

			for(f in fields.copy()) {
				if (f == null)
					continue;
				if (f.name == "new")
					continue;

				if(definedFields.contains(f.name)) continue; // no duplicate fields

				var hlNativeMeta = null;
				var hasHlNative = false;
				for(m in f.meta)
					if (m.name == ":hlNative") {
						hasHlNative = true;
						hlNativeMeta = m;
						break;
					}

				if(!hasHlNative) continue;

				switch(f.kind) {
					case FFun(fun):
						if (fun == null)
							continue;
						if (fun.params != null && fun.params.length > 0) // TODO: Support for this maybe?
							continue;

						if(fun.params == null)
							fun.params = [];

						var overrideExpr:Expr;
						var returns:Bool = !fun.ret.match(TPath({name: "Void"}));

						var printer = new haxe.macro.Printer();
						if(cl.module == "hl.Gc" && fun.ret == null) returns = false; // fix since they dont explicitly set :Void
						if(cl.module == "hl.Format" && fun.ret == null) returns = false; // fix since they dont explicitly set :Void

						var name = 'hlf_${f.name}';

						var arguments = fun.args == null ? [] : [for(a in fun.args) macro $i{a.name}];

						var funcExpr:Expr = macro @:privateAccess $i{name}($a{arguments});
						if(returns) funcExpr = macro return $funcExpr;

						var cleanMeta = f.meta.copy().filter(function(m) return m.name != ":hlNative");
						var hasBareMeta = hlNativeMeta.params.length == 0;

						var meta = f.meta.copy();
						switch hlNativeMeta {
							case {params: []}:
								meta = [{name: ":hlNative", params: [macro "std", macro $v{f.name}], pos: Context.currentPos()}].concat(cleanMeta);
							case {params: [_.expr => EConst(CString(name))]}:
								meta = [{name: ":hlNative", params: [macro "std", macro $v{name}], pos: Context.currentPos()}].concat(cleanMeta);
							case {params: [_.expr => EConst(CFloat(version))]}:
								var curVersion = Context.definedValue("hl_ver");
								if(curVersion == null) curVersion = "";
								if(version > curVersion) {
									meta = cleanMeta;
									if(f.meta.filter((m) -> m.name == ":noExpr").length > 0)
										Context.error("Missing function body", f.pos);
									funcExpr = fun.expr; // restore to default behaviour
								} else {
									meta = [{name: ":hlNative", params: [macro "std", macro $v{f.name}], pos: Context.currentPos()}].concat(cleanMeta);
								}
							default:
						}

						var fiel:Field = {
							name: name,
							pos: Context.currentPos(),
							kind: FFun({
								ret: fun.ret,
								params: fun.params.copy(),
								expr: funcExpr,
								args: fun.args.copy()
							}),
							access: f.access.copy().filter(function(a) return a != APublic && a != APrivate).concat([APrivate]),
							meta: meta
						};
						fields.push(fiel);
						definedFields.push(f.name);

						// Remove meta from original function
						for(m in f.meta.copy())
							if (m.name == ":hlNative") {
								f.meta.remove(m);
							}

					default:
				}
			}

			/*if(definedFields.length > 0) {
				trace(cl.module);

				var printer = new haxe.macro.Printer();
				for(field in fields) if(field.name.startsWith("hlf_"))
					Sys.println(printer.printField(field));
			}*/
		}

		return fields;
	}
}
#else
class HashLinkFixer {
}
#end