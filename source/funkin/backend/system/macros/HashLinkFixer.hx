package funkin.backend.system.macros;

#if macro
import haxe.macro.Expr;
import haxe.macro.*;

using StringTools;

class HashLinkFixer {
	public static function build():Array<Field> {
		final fields = Context.getBuildFields(), clRef = Context.getLocalClass();

		if (clRef == null) return fields;
		final cl = clRef.get();

		if (
			cl.isAbstract || cl.isExtern || cl.isInterface || cl.params.length > 0 ||
			cl.name.endsWith("_Impl_") || cl.name.endsWith("_HSX") || cl.name.endsWith("_HSC")
		) return fields;

		final pos = Context.currentPos();
		for (i in 0...fields.length) {
			final f = fields[i];
			if (f == null || f.name == 'new') continue;

			switch (f.kind) {
				case FFun(func):
					if (func == null) continue;

					var hlNativeMeta = null;
					final cleanMeta = f.meta.filter((m) -> {
						if (m.name != ':hlNative') return true;
						else {
							hlNativeMeta = m;
							return false;
						}
					});
					if (hlNativeMeta == null) continue;

					switch (hlNativeMeta.params) {
						case []: hlNativeMeta.params = [macro "std", macro $v{f.name}];
						case [_.expr => EConst(CString(name))]: hlNativeMeta.params = [macro "std", macro $v{name}];
						case [_.expr => EConst(CFloat(version))]:
							final curVersion = Context.definedValue("hl_ver");
							if (curVersion != null && version > curVersion) {
								if (f.meta.filter((m) -> return m.name == ":noExpr").length > 0)
									Context.error("Missing function body", hlNativeMeta.pos);
							}
							else
								hlNativeMeta.params = [macro "std", macro $v{f.name}];
						default:
					}

					final name = 'hlf_${f.name}';
					fields.push({
						name: name,
						pos: pos,
						kind: FFun({ret: func.ret, params: func.params, expr: func.expr, args: func.args}),
						access: f.access.filter((a) -> return a != APublic && a != APrivate).concat([APrivate]),
						meta: [hlNativeMeta]
					});

					final args = func.args == null ? [] : [for (a in func.args) macro $i{a.name}];

					f.meta = cleanMeta;
					func.expr = args.length == 0 ? macro $i{name}() : macro $i{name}($a{args});
					if (func.ret != null && !func.ret.match(TPath({name: 'Void'})))
						func.expr = macro return ${func.expr};
				default:
			}
		}

		return fields;
	}
}
#end