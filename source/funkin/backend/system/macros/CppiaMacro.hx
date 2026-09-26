package funkin.backend.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

class CppiaMacro {
	public static function build():Array<Field>
	{
		var fields = Context.getBuildFields();
		var localClass = Context.getLocalClass();
		if (localClass == null) return fields;
		var cl = localClass.get();

		var parentExpr:Expr = null;
		for (m in cl.meta.get()) {
			if (m.name == ":scriptParent") {
				if (m.params.length > 0) parentExpr = m.params[0];
				else Context.error('@:scriptParent requires a type parameter (ex: @:scriptParent(funkin.game.PlayState))', cl.pos);
				break;
			}
		}
		if (parentExpr == null) return fields;

		var parentCl:ClassType = null;
		var parentType:Type = null;
		try {
			var te = Context.typeExpr(parentExpr);
			switch (te.expr) {
				case TTypeExpr(TClassDecl(t)):
					parentCl = t.get();
					parentType = TInst(t, []);
				default:
			}
			if (parentCl == null) {
				switch (te.t) {
					case TInst(t, _):
						parentCl = t.get();
						parentType = te.t;
					default:
				}
			}
		} catch (e:Dynamic) {}
		if (parentCl == null) {
			Context.error('@:scriptParent: "${exprToPath(parentExpr)}" is not a class', parentExpr.pos);
			return fields;
		}

		var parentPath = classPath(parentCl);
		var parentComplexType = Context.toComplexType(parentType);
		var pos = Context.currentPos();

		var existing = new Map<String, Bool>();
		for (f in fields) {
			existing.set(f.name, true);
			existing.set('get_${f.name}', true);
			existing.set('set_${f.name}', true);
		}

		if (!existing.exists("__parent")) {
			fields.push({
				name: "__parent",
				kind: FVar(parentComplexType, null),
				access: [APublic],
				pos: pos,
				doc: "Parent object injected by the engine via Script.setParent (CppiaScript)."
			});
		}

		if (!existing.exists("__parentType")) {
			fields.push({
				name: "__parentType",
				kind: FVar(macro :Class<Dynamic>, Context.parse(parentPath, pos)),
				access: [APublic, AStatic, AFinal],
				pos: pos,
				doc: "Expected parent type (from @:scriptParent), used by CppiaScript for runtime validation."
			});
		}

		for (f in parentCl.fields.get()) {
			if (existing.exists(f.name) || StringTools.startsWith(f.name, "__")) continue;

			var kindName = Type.enumConstructor(f.kind);
			if (StringTools.endsWith(kindName, "FFun")) continue;
			var writable = StringTools.endsWith(kindName, "FVar");
			var t = f.type;
			if (t == null) continue;

			if (f.isPublic) {
				var complexT = Context.toComplexType(t);
				if (complexT == null) continue;
				fields.push(mkProperty(f.name, complexT, pos, writable));
				fields.push(mkGetter(f.name, pos));
				if (writable)
					fields.push(mkSetter(f.name, complexT, pos));
			} else {
				fields.push(mkReflectProperty(f.name, pos));
				fields.push(mkReflectGetter(f.name, pos));
			}
		}

		for (f in parentCl.statics.get()) {
			if (existing.exists(f.name) || StringTools.startsWith(f.name, "__")) continue;

			if (!StringTools.endsWith(Type.enumConstructor(f.kind), "FVar")) continue;
			if (!f.isPublic || f.type == null) continue;

			var complexT = Context.toComplexType(f.type);
			if (complexT == null) continue;

			fields.push({
				name: f.name,
				kind: FProp("get", "never", complexT, null),
				access: [APrivate, AStatic],
				pos: pos
			});
			fields.push({
				name: 'get_${f.name}',
				kind: FFun({
					args: [],
					ret: null,
					expr: parseExpr('return $parentPath.${f.name}', pos),
					params: []
				}),
				access: [APrivate, AStatic],
				pos: pos
			});
		}

		return fields;
	}

	static function mkProperty(name:String, t:ComplexType, pos:Position, writable:Bool):Field
	{
		return {
			name: name,
			kind: FProp("get", writable ? "set" : "never", t, null),
			access: [APublic],
			pos: pos
		};
	}

	static function mkGetter(name:String, pos:Position):Field
	{
		return {
			name: 'get_$name',
			kind: FFun({
				args: [],
				ret: null,
				expr: parseExpr('return __parent.$name', pos),
				params: []
			}),
			access: [APrivate],
			pos: pos
		};
	}

	static function mkSetter(name:String, t:ComplexType, pos:Position):Field
	{
		return {
			name: 'set_$name',
			kind: FFun({
				args: [{name: "v", type: t, opt: false, value: null}],
				ret: t,
				expr: parseExpr('{ __parent.$name = v; return v; }', pos),
				params: []
			}),
			access: [APrivate],
			pos: pos
		};
	}

	static function mkReflectProperty(name:String, pos:Position):Field
	{
		return {
			name: name,
			kind: FProp("get", "never", macro :Dynamic, null),
			access: [APublic],
			pos: pos
		};
	}

	static function mkReflectGetter(name:String, pos:Position):Field
	{
		return {
			name: 'get_$name',
			kind: FFun({
				args: [],
				ret: null,
				expr: macro return Reflect.field(__parent, $v{name}),
				params: []
			}),
			access: [APrivate],
			pos: pos
		};
	}

	static function exprToPath(e:Expr):String
	{
		return switch (e.expr) {
			case EConst(CIdent(s)): s;
			case EField(e2, f):
				var p = exprToPath(e2);
				p == null ? null : p + "." + f;
			default: null;
		}
	}

	static function classPath(cl:ClassType):String
	{
		var path = cl.pack.join(".");
		if (path.length > 0) path += ".";
		path += cl.module;
		if (cl.module != cl.name) path += "." + cl.name;
		return path;
	}

	static function parseExpr(s:String, pos:Position):Expr
	{
		return try Context.parse(s, pos) catch (e:Dynamic) {
			Sys.stderr().writeString('[CppiaMacro] parse failed: "$s" (${Std.string(e)})\n');
			throw e;
		};
	}
}
#end
