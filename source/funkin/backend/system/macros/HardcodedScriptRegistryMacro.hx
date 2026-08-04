package funkin.backend.system.macros;

#if HARDCODED_SCRIPTS
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
#end

class HardcodedScriptRegistryMacro {
	#if macro
	public static function build() {
		var fields = Context.getBuildFields();
		Context.onGenerate(findRegisteredScripts);
		return fields;
	}

	static function findRegisteredScripts(allTypes:Array<haxe.macro.Type>) {
		var registeredScripts:Array<Expr> = [];
		var registeredClasses:Array<Expr> = [];
		for (type in allTypes) {
			switch (type) {
				case TInst(cl,_):
					var c = cl.get();
					var meta = c.meta.get();
					for (m in meta) {
						if (m.name == ":registerScript") {
							var classPath:String = c.module;
							if (classPath.indexOf(".") != -1) {
								classPath = classPath.substring(0, classPath.lastIndexOf(".")+1) + c.name;
							}
							registeredClasses.push(macro $v{classPath});
							registeredScripts.push(m.params[0]);
						}
					}
				default:
			}
		}

		//store within metadata, which we can get at runtime
		//based on how this lib does it: https://github.com/jasononeil/compiletime/blob/master/src/CompileTime.hx#L268
		switch (Context.getType("funkin.backend.scripting.HardcodedScriptRegistry")) {
			case TInst(cl, _):
				var c = cl.get();
				if (c.meta.has('registeredScripts')) c.meta.remove('registeredScripts');
				c.meta.add('registeredScripts', registeredScripts, Context.currentPos());
				if (c.meta.has('registeredClasses')) c.meta.remove('registeredClasses');
				c.meta.add('registeredClasses', registeredClasses, Context.currentPos());
			default:
		}
	}
	#end
}
#end