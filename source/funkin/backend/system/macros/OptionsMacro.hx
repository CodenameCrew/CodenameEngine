package funkin.backend.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

/**
 * Macro used in the options class to add getters for the SOLO keybinds.
 */
class OptionsMacro {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();

		for(f in fields) {
			switch(f.kind) {
				case FProp(get, set, t, e):
					if (f.name.startsWith('SOLO_') && get == "get" && set == "null") {
						// Auto-create getters for solo (P1/P2) keybinds
						var name = f.name.substr(5);
						var getterName = 'get_SOLO_$name';
						var ponename = 'P1_$name';
						var ptwoname = 'P2_$name';
						var newFuncExpr:Expr = macro {
							var a:Array<FlxKey> = [];
							for(e in $i{ponename}) a.push(e);
							for(e in $i{ptwoname}) a.push(e);
							return a;
						};

						fields.push({
							name: getterName,
							kind: FFun({
								expr: newFuncExpr,
								args: []
							}),
							pos: Context.currentPos(),
							access: [APrivate, AStatic, AInline]
						});
					}
				default:
					// nothing
			}
		}

		return fields;
	}
}
#end