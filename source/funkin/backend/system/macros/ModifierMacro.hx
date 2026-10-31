package funkin.backend.system.macros;

import haxe.macro.ExprTools;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class ModifierMacro {
	public static macro function createModifier():Array<Field> {
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();

		var cls = Context.getLocalClass().get();
		var clsName = cls.name;

		var floats:Array<Field> = [];
		var bools:Array<Field> = [];
		var ints:Array<Field> = [];
		var lanes:Array<Field> = [];
		var fieldMap:Map<String, Field> = [];

		for (field in fields) {
			fieldMap.set(field.name, field);

			switch (field.kind) {
				case FVar(TPath({name: "ModifierFloat"}), _):
					floats.push(field);
				case FVar(TPath({name: "ModifierBool"}), _):
					bools.push(field);
				case FVar(TPath({name: "ModifierInt"}), _):
					ints.push(field);
				case FVar(TPath({name: "LaneModValue"}), _):
					lanes.push(field);
				default: // nothing
			}
		}
		if (floats.length <= 0 && bools.length <= 0 && ints.length <= 0 && lanes.length <= 0)
			return fields;

		var names:Array<String> = [];
		var requires:Array<String> = [];
		var requiredLanes:Array<String> = [];
		var defaults:Map<String, Float> = [];
		var aliases:Map<String, String> = [];

		for (mod in floats)
			editModifierField(mod, names, requires, defaults, aliases, fields);
		for (mod in bools)
			editModifierField(mod, names, requires, defaults, aliases, fields);
		for (mod in ints)
			editModifierField(mod, names, requires, defaults, aliases, fields);
		for (laneMod in lanes) {
			var optional = false;
			for (meta in (laneMod.meta ?? []))
				optional = optional || meta.name == ":optional";

			if (!optional)
				requiredLanes.push(laneMod.name);
		}

		fields.push({
			name: "defaults",
			access: [APublic],
			kind: FVar(macro:Map<String, Float>, macro $v{defaults}),
			pos: pos
		});
		var laneList = macro [${for (laneMod in lanes) macro $i{laneMod.name}}];
		fields.push({
			name: "ready",
			access: [AOverride, APublic],
			kind: FFun({
				args: [],
				expr: macro {
					for (map in parent.storage) {
						for (name => val in defaults)
							map.set(name, val);
					}
					var aliases:Map<String, String> = $v{aliases};
					for (alias => name in aliases)
						parent.aliases.set(alias.toLowerCase(), name.toLowerCase());

					for (laneMod in ${laneList})
						laneMod.ready(this);
				}
			}),
			pos: pos
		});

		if (!fieldMap.exists("isActive") && (requires.length > 0 || requiredLanes.length > 0)) {
			var result = macro false;
			for (i in 0...requires.length) {
				var requireName:String = requires[i].toLowerCase();
				var def:Float = defaults[requireName];
				result = macro ${result} || get($v{requireName}, field) != $v{def};
			}

			for (laneMod in requiredLanes) {
				result = macro ${result} || $i{laneMod}.isActive(field);
			}

			fields.push({
				name: "isActive",
				access: [AOverride, APublic],
				kind: FFun({
					args: [{
						name: "field",
						type: macro:Int
					}],
					ret: macro:Bool,
					expr: macro return ${result}
				}),
				pos: pos
			});
		}

		var initExpr = macro {
			var refs = funkin.game.modchart.ModchartManager.references;
			if (refs == null)
				funkin.game.modchart.ModchartManager.references = refs = [];
			
			var aliases:Map<String, String> = $v{aliases};
			for (name in $v{names})
				refs.set(name.toLowerCase(), $i{clsName});
			for (name in aliases.keys())
				refs.set(name.toLowerCase(), $i{clsName});

			${applyLaneReferences(clsName, lanes)}
		};
		if (fieldMap.exists("__init__")) {
			switch (fieldMap.get("__init__").kind) {
				case FFun({expr: e}):
					e.expr = EBlock([e, initExpr]);
				default: // nothin
			}
		} else {
			fields.push({
				name: "__init__",
				access: [AStatic],
				kind: FFun({
					args: [],
					expr: initExpr
				}),
				pos: pos
			});
		}

		return fields;
	}

	static function editModifierField(mod:Field, names:Array<String>, requires:Array<String>, defaults:Map<String, Float>, aliases:Map<String, String>, fields:Array<Field>):Void {
		var name = mod.name;
		var optional = false;
		names.push(name);

		for (meta in (mod.meta ?? [])) {
			optional = optional || meta.name == ":optional";

			if (meta.name != ":alias")
				continue;
			for (param in (meta.params ?? [])) {
				switch (param.expr) {
					case EConst(CString(s, _) | CIdent(s)):
						aliases.set(s.toLowerCase(), name.toLowerCase());
					default: // nothing
				}
			}
		}
		if (!optional)
			requires.push(name);

		var type = macro:ModifierFloat;
		switch (mod.kind) {
			case FVar(t, e):
				type = t;
				switch (e.expr) {
					case EConst(CInt(f, s) | CFloat(f, s)):
						defaults.set(name.toLowerCase(), Std.parseFloat(f));
					case EConst(CIdent(s)):
						defaults.set(name.toLowerCase(), s == "true" ? 1 : 0);
					default:
						defaults.set(name.toLowerCase(), 0);
				}
			default: // nothin
		}
		mod.kind = FProp("get", "never", type);
		fields.push({
			name: "get_" + name,
			access: [AInline, AExtern],
			kind: FFun({
				args: [],
				ret: type,
				expr: giveModifierGetter(name.toLowerCase(), type)
			}),
			pos: Context.currentPos()
		});
	}

	static function giveModifierGetter(name:String, type:ComplexType):Expr {
		return switch (type) {
			case TPath({name: "ModifierBool"}):
				macro return get($v{name}, parent.curField) != 0;
			case TPath({name: "ModifierInt"}):
				macro return Std.int(get($v{name}, parent.curField));
			default:
				macro return get($v{name}, parent.curField);
		}
	}

	static function applyLaneReferences(clsName:String, lanes:Array<Field>) {
		var prefixes:Array<String> = [];
		var suffixes:Array<String> = [];
		var aliases:Array<Array<String>> = [];

		for (laneMod in lanes) {
			switch (laneMod.kind) {
				case FVar(_, e):
					if (e == null) {
						Context.warning('$clsName.${laneMod.name}: Lane Modifers need a default expression for proper referencing', laneMod.pos);
						continue;
					}

					switch (e.expr) {
						case ENew(t, params):
							prefixes.push(ExprTools.getValue(params[0]).toLowerCase());
							suffixes.push(ExprTools.getValue(params[1]).toLowerCase());
							if (params.length >= 4 && params[3] != (macro null))
								aliases.push(ExprTools.getValue(params[3]));
							else
								aliases.push([]);
						default: // nothin
					}
				default: // nothin
			}
		}

		return macro {
			var prefixes:Array<String> = $v{prefixes};
			var suffixes:Array<String> = $v{suffixes};
			var aliases:Array<Array<String>> = $v{aliases};

			for (i in 0...prefixes.length) {
				funkin.game.modchart.ModchartManager.references.set(prefixes[i] + suffixes[i], $i{clsName});
				funkin.game.modchart.ModchartManager.references.set(prefixes[i] + "%c" + suffixes[i], $i{clsName});
			}
			for (aliasArr in aliases) {
				for (alias in aliasArr) {
					funkin.game.modchart.ModchartManager.references.set(StringTools.replace(alias, "%c", ""), $i{clsName});
					funkin.game.modchart.ModchartManager.references.set(alias, $i{clsName});
				}
			}
		}
	}
}
#end