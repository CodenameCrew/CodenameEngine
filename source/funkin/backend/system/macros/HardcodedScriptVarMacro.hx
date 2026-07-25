package funkin.backend.system.macros;

import haxe.macro.TypeTools;
#if HARDCODED_SCRIPTS
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
using haxe.macro.Tools;
#end

class HardcodedScriptVarMacro {

	#if macro

	public static function build()
	{
		var fields = Context.getBuildFields();

		var newFields:Array<Field> = [];

		var varInits:Array<Expr> = [];

		for (field in fields) {
			for (meta in field.meta) {

				if (meta.name == ":publicVar" || meta.name == ":publicVarRef" || meta.name == ":staticVar" || meta.name == ":staticVarRef" || meta.name == ":dynamicVar" || meta.name == ":dynamicVarRef") {
					var name:String = field.name;
					var ret:Null<ComplexType>;
					switch(field.kind) {
						case FVar(t, e):
							if (t != null) {
								ret = t;
								field.kind = FieldType.FProp("get", "set", t);
							}
							if (meta.name == ":publicVar" && e != null) {
								varInits.push(macro {setPublic($v{name}, ${e});});
							} else if (meta.name == ":staticVar" && e != null) {
								varInits.push(macro {setStatic($v{name}, ${e});});
							} else if (meta.name == ":dynamicVar" && e != null) {
								varInits.push(macro {setDynamic($v{name}, ${e});});
							}
						case FFun(f):
							field.name = "__" + field.name;
							var argTypes:Array<ComplexType> = [];
							for (a in f.args) {
								argTypes.push(a.type);
							}
							ret = macro : Dynamic; //just do dynamic for now, should still work
							//ret = TFunction(argTypes, f.ret);
							//ret = TypeTools.toComplexType()
							newFields.push({
								name: name,
								access: [Access.APrivate],
								kind: FieldType.FProp("get", "set", ret),
								pos: Context.currentPos(),
							});

							if (meta.name == ":publicVar") {
								varInits.push(macro {setPublic($v{name}, $i{field.name});});
							} else if (meta.name == ":staticVar") {
								varInits.push(macro {setStatic($v{name}, $i{field.name});});
							} else if (meta.name == ":dynamicVar") {
								varInits.push(macro {setDynamic($v{name}, $i{field.name});});
							}
						default:
					}

					var getFuncExpr:Expr = null;
					var setFuncExpr:Expr = null;

					if (meta.name == ":publicVar" || meta.name == ":publicVarRef") {
						getFuncExpr = macro return getPublic($v{name});
						setFuncExpr = macro {
							setPublic($v{name}, value);
							return value;
						};
					} else if (meta.name == ":staticVar" || meta.name == ":staticVarRef") {
						getFuncExpr = macro return getStatic($v{name});
						setFuncExpr = macro {
							setStatic($v{name}, value);
							return value;
						};
					} else if (meta.name == ":dynamicVar" || meta.name == ":dynamicVarRef") {
						getFuncExpr = macro return getDynamic($v{name});
						setFuncExpr = macro {
							setDynamic($v{name}, value);
							return value;
						};
					}

					var getterField:Field = {
						name: "get_" + name,
						access: [Access.APrivate, Access.AInline],
						kind: FieldType.FFun({
							expr: getFuncExpr,
							ret: ret,
							args: [],
						}),
						pos: Context.currentPos(),
					};
					var setterField:Field = {
						name: "set_" + name,
						access: [Access.APrivate, Access.AInline],
						kind: FieldType.FFun({
							expr: setFuncExpr,
							ret: ret,
							args: [{name: "value", type: ret}]
						}),
						pos: Context.currentPos(),
					};
					newFields.push(getterField);
					newFields.push(setterField);
				}
			}
		}
		for (field in newFields) fields.push(field);

		fields.push({
			pos: Context.currentPos(),
			name: "initVars",
			kind: FFun({
				args: [],
				expr: {
					pos: Context.currentPos(),
					expr: EBlock(varInits)
				}
			}),
			access: [Access.APrivate]
		});

		return fields;
	}

	#end
}
#end