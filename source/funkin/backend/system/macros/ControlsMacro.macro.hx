package funkin.backend.system.macros;


import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

using haxe.macro.Tools;


// Macro made by Ne_Eo
class ControlsMacro
{
	static var _allControls: Array<String> = null;
	static var _allInternalControls: Array<String> = null;
	static var _allDevModeOnlyControls: Array<String> = null;
	static var _currentControls: Map<String, Array<Expr>> = null;
	static var _currentGamepadControls: Map<String, Expr> = null;
	static var _keySet: Map<String, String> = null;
	static var _internalMap: Map<String, String> = null;

	public static macro function build(): Array<Field>
	{
		var fields = Context.getBuildFields();
		var clRef = Context.getLocalClass();
		if (clRef == null)
			return fields;
		var cl = clRef.get();

		_allControls = [];
		_allInternalControls = [];
		_allDevModeOnlyControls = [];
		_currentControls = [];
		_currentGamepadControls = [];
		_keySet = [];
		_internalMap = [];
		var fields = Context.getBuildFields();
		for (field in fields.copy())
		{
			switch (field.kind)
			{
				case FProp(g, s, t, e):
					var controlFields = handleControl(field, g, s, t, e);
					for (field in controlFields)
						if (field != null)
							fields.push(field);
				default:
			}
		}

		// Public fields
		fields.push({
			name: "addDefaultGamepad",
			access: [APublic],
			kind: FFun({
				ret: macro : Void,
				params: [],
				expr: generateGamepadCode(),
				args: [{name: "id", type: macro : Int}]
			}),
			pos: Context.currentPos(),
			doc: null,
			meta: []
		});

		// Private fields, are prefixed with macro_, for readability
		fields.push({
			name: "macro_addKeysToActions",
			access: [APublic, AInline],
			kind: FFun({
				ret: macro : Void,
				params: [],
				expr: macro $b{_allInternalControls.map((s) -> macro add($i{s}))},
				args: []
			}),
			pos: Context.currentPos(),
			doc: null,
			meta: []
		});

		function buildBindControl(s:String, prefix:String) {
			var prefixed = prefix + s;

			return macro bindKeys(Control.$s, Options.$prefixed);
		}

		fields.push({
			name: "macro_bindControls",
			access: [],
			kind: FFun({
				ret: macro : Void,
				params: [],
				expr: macro switch(keyScheme) {
					case Solo:
						$a{_allControls.map(buildBindControl.bind(_, "SOLO_"))};
					case Duo(true):
						$a{_allControls.map(buildBindControl.bind(_, "P1_"))};
					case Duo(false):
						$a{_allControls.map(buildBindControl.bind(_, "P2_"))};
					case None: // nothing
					case Custom: // nothing
				},
				args: [{
					name: "keyScheme",
					type: macro : funkin.backend.system.Controls.KeyboardScheme
				}]
			}),
			pos: Context.currentPos(),
			doc: null,
			meta: []
		});

		fields.push({
			name: "macro_forEachBound",
			access: [],
			kind: FFun({
				ret: macro : Void,
				params: [],
				expr: generateForEachBoundCode(macro control),
				args: [
					{
						name: "control",
						type: macro : Control
					},
					{
						name: "func",
						type: macro : FlxActionDigital -> FlxInputState -> Void
					}
				]
			}),
			pos: Context.currentPos(),
			doc: null,
			meta: []
		});

		fields.push({
			name: "macro_getActionFromControl",
			access: [APrivate],
			kind: FFun({
				ret: macro : FlxActionDigital,
				params: [],
				expr: generateGetActionFromControlCode(macro control),
				args: [{
					name: "control",
					type: macro : Control
				}]
			}),
			pos: Context.currentPos(),
			doc: null,
			meta: []
		});

		// for (field in fields)
		// 	trace(new haxe.macro.Printer().printField(field));

		_allControls = null;
		_allInternalControls = null;
		_allDevModeOnlyControls = null;
		_currentControls = null;
		_currentGamepadControls = null;
		_keySet = null;
		_internalMap = null;

		return fields;
	}

	static function generateSwitchCase(expr:Expr, cases:Array<Case>, defaultCase:Expr): Expr
	{
		return {
			expr: ESwitch(expr, cases, defaultCase),
			pos: Context.currentPos()
		}
	}

	static function generateGetActionFromControlCode(value:Expr): Expr
	{
		return macro return ${generateSwitchCase(value, [
			for (short => internal in _internalMap)
				{
					values: [macro Control.$short],
					expr: macro $i{internal}
				}
		], macro null)};
	}

	static function generateForEachBoundCode(value:Expr): Expr
	{
		return generateSwitchCase(value, [
			for (field => code in _currentControls)
				{
					values: [macro Control.$field],
					expr: macro $b{code}
				}
		], macro {});
	}

	static function generateGamepadCode(): Expr
	{
		var map: Array<Expr> = [];
		for (name in _allControls)
		{
			var expr = _currentGamepadControls.get(name);
			if(expr == null) continue;
			map.push(macro @:pos(expr.pos) Control.$name => ${expr});
		}

		return macro addGamepad(id, $a{map});
	}

	static function extractString(e: Expr): String
	{
		switch (e.expr)
		{
			case EConst(CString(s)):
				return s;
			default:
				Context.error("Expected a string", e.pos);
				throw "Expected a String";
		}
	}

	static function camelCase(s: String): String
	{
		s = s.split("_").map((s) ->
		{
			return s.charAt(0).toUpperCase() + s.substr(1).toLowerCase();
		}).join("");

		return s.charAt(0).toLowerCase() + s.substr(1);
	}

	static function swapAB(e: Expr): Expr
	{
		return switch (e.expr)
		{
			case EConst(CIdent('A')): macro B;
			case EConst(CIdent('B')): macro A;
			default: e.map(swapAB);
		}
	}

	static function handleControl(field: Field, get: String, set: String, _: ComplexType, e: Expr): Array<Field>
	{
		var name = field.name;
		var shortName = name;
		var type = "";
		if (shortName.endsWith(type = "_P"))
			shortName = shortName.substr(0, shortName.length - 2);
		else if (shortName.endsWith(type = "_R"))
			shortName = shortName.substr(0, shortName.length - 2);
		else if (shortName.endsWith(type = "_H"))
			shortName = shortName.substr(0, shortName.length - 2);
		else if (shortName.endsWith(type = "_HOLD"))
			shortName = shortName.substr(0, shortName.length - 5);
		else
			type = "";

		var internalName = "_" + camelCase(shortName);
		var internalNameNoType = internalName;
		if (type != "")
			internalName += type.substr(1);

		var keyset: Null<String> = null;
		var expr: Expr = null;
		var metasToRemove = [];
		for (meta in field.meta)
		{
			var shouldRemove = true;
			switch (meta.name)
			{
				case ":gamepad" | ":rawGamepad":
					if (!_currentGamepadControls.exists(shortName))
					{
						var expr = meta.params[0];
						var shouldRemap = meta.name != ":rawGamepad";
						if (shouldRemap && Context.defined("switch"))
						{
							expr = swapAB(expr);
						}
						_currentGamepadControls.set(shortName, expr);
					}
				case ":pressed":
					keyset = extractString(meta.params[0]);
					expr = macro func($i{internalName}, PRESSED);
				case ":justPressed":
					keyset = extractString(meta.params[0]);
					expr = macro func($i{internalName}, JUST_PRESSED);
				case ":released":
					keyset = extractString(meta.params[0]);
					expr = macro func($i{internalName}, RELEASED);
				case ":justReleased":
					keyset = extractString(meta.params[0]);
					expr = macro func($i{internalName}, JUST_RELEASED);
				case ":devModeOnly":
					if (!_allDevModeOnlyControls.contains(shortName))
						_allDevModeOnlyControls.push(shortName);
				default:
					shouldRemove = false;
			}

			if (shouldRemove)
				metasToRemove.push(meta);
		}

		for (meta in metasToRemove)
			field.meta.remove(meta);

		if (_currentControls.exists(shortName))
			_currentControls.get(shortName).push(expr);
		else
			_currentControls.set(shortName, [expr]);

		if (!_allInternalControls.contains(internalName))
			_allInternalControls.push(internalName);
		if (!_allControls.contains(shortName))
			_allControls.push(shortName);

		_keySet.set(shortName, keyset);
		if (!_internalMap.exists(internalNameNoType))
			_internalMap.set(shortName, internalNameNoType);

		// Generated Code: var _uiUp = new FlxActionDigital("_uiUp");
		var internalField: Field = {
			name: internalName,
			access: [APrivate],
			kind: FVar(macro : FlxActionDigital, macro new FlxActionDigital($v{internalName})),
			pos: field.pos,
			doc: null,
			meta: []
		};

		// Generated Code:
		// inline function get_UI_UP(): Bool
		//     return _uiUp.check(); or return Options.devMode && _uiUp.check(); depending if its dev mode
		var getField: Field = {
			name: "get_" + name,
			access: [APrivate, AInline],
			kind: FFun({
				ret: macro : Bool,
				params: [],
				expr: _allDevModeOnlyControls.contains(shortName) ?
					(macro return Options.devMode && $i{internalName}.check()) :
					(macro return $i{internalName}.check()),
				args: []
			}),
			pos: field.pos,
			doc: field.doc,
			meta: []
		};

		// Generated Code:
		// inline function set_UI_UP(val: Bool): Bool
		//     return @:privateAccess _uiUp._checked = val;
		var setField: Field = {
			name: "set_" + name,
			access: [APrivate, AInline],
			kind: FFun({
				ret: macro : Bool,
				params: [],
				expr: macro
				{
					return @:privateAccess $i{internalName}._checked = val;
				},
				args: [{name: "val", type: macro : Bool}]
			}),
			pos: field.pos,
			doc: field.doc,
			meta: []
		};

		return [internalField, getField, set == "set" ? setField : null];
	}
}
