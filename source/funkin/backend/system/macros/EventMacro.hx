package funkin.backend.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * Macro that generates all additional fields, making events much easier to code in.
 * It adds the `recycle` function, which allows you to "reset" an event's values.
 */
class EventMacro {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();

		var curClassRest = Context.getLocalClass();
		if (curClassRest == null) return fields;

		var curClass = curClassRest.get();
		if (curClass == null || curClass.name == "CancellableEvent") return fields;

		for(f in fields)
			if (f.name == "recycle")
				return fields;

		// gets all fields
		var values:Array<EventVar> = [];
		var hiddenValues:Array<EventVar> = [];
		for(field in fields) {
			if (field.access.contains(AStatic)) continue;

			var hidden = false;
			if (field.meta != null)
				for(m in field.meta)
					if (m.name == ":dox")
						hidden = true;
			if (!field.access.contains(APublic)) hidden = true;

			switch(field.kind) {
				case FVar(type, expr):
					(hidden ? hiddenValues : values).push({
						name: field.name,
						type: type,
						expr: expr
					});
				default:
					continue;
			}
		}

		// add recycle option
		var func:Function = {
			args: [for(a in values) {
				value: a.expr,
				type: a.type,
				opt: false,
				name: a.name
			}],
			expr: {
				pos: Context.currentPos(),
				expr: EBlock([])
			}
		};

		var funcField:Field = {
			pos: Context.currentPos(),
			name: "recycle",
			kind: FFun(func),
			access: [APublic]
		};

		fields.push(funcField);

		switch(func.expr.expr) {
			case EBlock(exprs):
				// add a "set this" expr for each variable
				for(v in values) {
					var name = v.name;
					exprs.push(macro this.$name = $i{name});
				}

				// add a "set this" expr to reset each private/hidden variables
				for(v in hiddenValues) {
					var name = v.name;
					exprs.push(macro this.$name = ${v.expr});
				}

				exprs.push(macro return this);
				exprs.insert(0, macro recycleBase());
			default:
				// nothing
		}

		return fields;
	}
}

typedef EventVar = {
	var name:String;
	var type:ComplexType;
	var expr:Expr;
}
#end