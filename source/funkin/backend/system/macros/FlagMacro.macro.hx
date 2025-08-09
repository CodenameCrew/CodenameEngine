package funkin.backend.system.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

using haxe.macro.Tools;

using funkin.backend.system.macros.FlagMacro;

class FlagMacro {
	private static function hasMeta(meta:Array<MetadataEntry>, name:String):Bool {
		for(m in meta) {
			if(m.name == name) {
				return true;
			}
		}
		return false;
	}

	public static function build():Array<Field> {
		var fields = Context.getBuildFields();

		var clRef = Context.getLocalClass();
		if (clRef == null)
			return fields;

		var cl = clRef.get();

		var resetExprs:Array<Expr> = [];
		var parserExprs:Array<Expr> = [];
		resetExprs.push(macro $i{"customFlags"} = $v{[]});

		for (field in fields) {
			if (field.meta.hasMeta(":bypass")) continue;
			var hasLazy = field.meta.hasMeta(":lazy");

			switch (field.kind) {
				case FVar(type, expr):
					var isNullable = false;
					switch(type) {
						case TPath({name: "Null", pack: [], params: [TPType(p)]}):
							type = p;
							isNullable = true;
						default:
					}

					var alsos:Array<Expr> = [];
					for(meta in field.meta) {
						if(meta.name == ":also") {
							for(param in meta.params) {
								switch(param.expr) {
									case EField(_, _):
										alsos.push(param);
									default:
										Context.error("Invalid :also parameter", param.pos);
								}
							}
						}
					}

					if (expr == null) Context.error('Flag ' + field.name + ' must have a default value', field.pos);
					if (type == null) {
						switch(expr.expr) {
							case EConst(CIdent("true")) | EConst(CIdent("false")):
								type = macro: Bool;
							case EConst(CInt(_)):
								type = macro: Int;
							case EConst(CFloat(_)):
								type = macro: Float;
							case EConst(CString(_)):
								type = macro: String;
							default:
								Context.error('Flag ' + field.name + ' must have a type', field.pos);
						}
					}

					var parser:Expr = null;
					var customCheck:Expr = null;

					switch(type) {
						case macro: Array<TrimmedString>:
							field.kind = FVar(macro: Array<String>, expr);
							parser = macro value.split(",").map((e) -> e == 'NULL' ? null : e.trim());
						case macro: Array<String>:
							parser = macro value.split(",").map((e) -> e == 'NULL' ? null : e);
						case (macro: Array<Int>) | (macro: Array<FlxColor>):
							parser = macro value.split(",").map((e) -> e == 'NULL' ? null : Std.parseInt(e));
						case macro: Array<Float>:
							parser = macro value.split(",").map((e) -> e == 'NULL' ? null : Std.parseFloat(e));
						case macro: Array<Bool>:
							parser = macro value.split(",").map(parseBool);
						case macro: TrimmedString:
							field.kind = FVar(macro: String, expr);
							parser = macro value.trim();
						case macro: String:
							parser = macro value;
						case (macro: Int) | (macro: FlxColor):
							parser = macro Std.parseInt(value);
						case macro: Float:
							parser = macro Std.parseFloat(value);
						case macro: Bool:
							parser = macro parseBool(value);
						case TPath({name: "Allow", pack: [], params: params}):
							final NONE = 0;
							final STRING = 1;
							final INT = 2;
							var chosenType = NONE;

							var values:Array<String> = [];

							for(param in params) {
								switch(param) {
									case TPExpr(e):
										switch(e.expr) {
											case EConst(CString(s, kind)):
												if(chosenType != NONE && chosenType != STRING)
													Context.error("Flag " + field.name + " Allow<> can only have one type", field.pos);
												chosenType = STRING;

												values.push(s);
											case EConst(CInt(num)):
												if(chosenType != NONE && chosenType != INT)
													Context.error("Flag " + field.name + " Allow<> can only have one type", field.pos);
												chosenType = INT;

												values.push(num);
											default:
												Context.error("Flag " + field.name + " Allow<> unknown type", field.pos);
										}
									default:
										Context.error("Flag " + field.name + " Unknown type when using Allow<>", field.pos);
								}
							}

							var didFind = false;
							for(v in values) {
								switch(expr.expr) {
									case EConst(CString(s, kind)):
										if(v == s)
											didFind = true;
									case EConst(CInt(num)):
										if(v == num)
											didFind = true;
									default:
								}
							}
							if(!didFind)
								Context.error("Flag " + field.name + "'s Allow<> must have a default value that is allowed, " + expr.toString() + " is not allowed", field.pos);

							if(chosenType == NONE)
								Context.error("Flag " + field.name + "'s Allow<> must have atleast one value", field.pos);

							var errorMessage = 'Flag ${field.name} must be one of ${values.join(", ")}';

							var checkExpr = macro value == $v{values.shift()};
							for(v in values)
								checkExpr = macro $checkExpr || value == $v{v};

							if(chosenType == STRING) {
								parser = macro value;
								field.kind = FVar(macro: String, expr);
							} else if(chosenType == INT) {
								parser = macro Std.parseInt(value);
								field.kind = FVar(macro: Int, expr);
							} else {
								field.kind = FVar(macro: Any, expr);
							}

							customCheck = macro @:mergeBlock {
								if(name == $v{field.name}) {
									if($checkExpr)
										$i{field.name} = $parser;
									else
										throw $v{errorMessage};
									return true;
								}
							}

						case TPath({name: "Array", pack: []}):
							Context.error("Flag " + field.name + " cannot be an Array that isn't a String or Bool or TrimmedString or Int or Float", field.pos);
						case TPath({name: "Map", pack: []}):
							//Context.error("Flag " + field.name + " cannot be a Map<K, V>", field.pos);
							resetExprs.push(macro $i{field.name} = ${expr});
							continue;
						default:
							Context.error("Flag " + field.name + " must be either a Bool, Int, Float, String, Array<String>, Array<Int>, Array<Float>, Array<Bool> or Array<TrimmedString>", field.pos);
					}

					if (parser == null) {
						Context.error("Flag " + field.name + " must be either a Bool, Int, Float, String, Array<String>, Array<Int>, Array<Float>, Array<Bool> or Array<TrimmedString>", field.pos);
						continue;
					}

					if(isNullable) {
						switch(field.kind) {
							case FVar(t, e):
								field.kind = FVar(TPath({name: "Null", pack: [], params: [TPType(t)]}), e);
							default:
						}
					}

					resetExprs.push(macro $i{field.name} = ${expr});

					// parse(name: String, value: String)

					if(customCheck != null) {
						parserExprs.push(customCheck);
					} else {
						var alsoExpr = alsos.length > 0 ? macro @:mergeBlock $b{alsos.map((e) -> return macro $e = val)} : macro {};

						if(isNullable) {
							parserExprs.push(macro @:mergeBlock {
								if(name == $v{field.name}) {
									var val = value == "NULL" ? null : $parser;
									$i{field.name} = val;
									$alsoExpr;
									return true;
								}
							});
						} else {
							parserExprs.push(macro @:mergeBlock {
								if(name == $v{field.name}) {
									var val = $parser;
									$i{field.name} = val;
									$alsoExpr;
									return true;
								}
							});
						}
					}
				default:
					// nothing
			}

			if(hasLazy) {
				switch(field.kind) {
					case FVar(t, expr):
						field.kind = FVar(t, null);
					default:
				}
			}
		}

		fields.push({
			name: "reset",
			access: [APublic, AStatic],
			kind: FFun({
				args: [],
				expr: macro $b{resetExprs},
				ret: macro: Void
			}),
			pos: Context.currentPos(),
			doc: null,
			meta: []
		});

		fields.push({
			name: "parse",
			access: [APublic, AStatic],
			kind: FFun({
				args: [{name: "name", type: macro: String}, {name: "value", type: macro: String}],
				expr: macro {
					@:mergeBlock $b{parserExprs};

					return false;
				},
				ret: macro: Bool
			}),
			pos: Context.currentPos(),
			doc: null,
			meta: []
		});

		fields.push({
			name: "parseBool",
			access: [APrivate, AStatic],
			kind: FFun({
				args: [{name: "e", type: macro: String}],
				expr: macro {
					e = e.trim();
					return e == "true" || e == "t" || e == "1";
				},
				ret: macro: Bool
			}),
			pos: Context.currentPos(),
			doc: null,
			meta: []
		});

		//var printer = new haxe.macro.Printer();
		//for(field in fields) {
		//	trace(printer.printField(field));
		//}
		//trace(printer.printField(fields[fields.length - 2]));
		//trace(printer.printField(fields[fields.length - 1]));

		return fields;
	}
}