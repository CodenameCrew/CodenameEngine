package funkin.backend.system.macros;

#if macro
import haxe.macro.*;
import haxe.macro.Expr;

/**
 * Macros containing additional help functions to expand HScript capabilities.
 */
class Macros {
	public static function addAdditionalClasses() {
		for(inc in [
			// FLIXEL
			"flixel.util", "flixel.ui", "flixel.tweens", "flixel.tile", "flixel.text",
			"flixel.system", "flixel.sound", "flixel.path", "flixel.math", "flixel.input",
			"flixel.group", "flixel.graphics", "flixel.effects", "flixel.animation",
			// FLIXEL ADDONS
			"flixel.addons.api", "flixel.addons.display", "flixel.addons.effects", "flixel.addons.ui",
			"flixel.addons.plugin", "flixel.addons.text", "flixel.addons.tile", "flixel.addons.transition",
			"flixel.addons.util",
			// OTHER LIBRARIES & STUFF
			#if THREE_D_SUPPORT "away3d", "flx3d", #end
			#if VIDEO_CUTSCENES "hxvlc.flixel", "hxvlc.openfl", #end
			#if NAPE_ENABLED "nape", "flixel.addons.nape", #end
			// BASE HAXE
			"DateTools", "EReg", "Lambda", "StringBuf", "haxe.crypto", "haxe.display", "haxe.exceptions", "haxe.extern", "scripting", "animate"
		])
			Compiler.include(inc);

		var isHl = Context.defined("hl");

		var compathx4 = [
			"sys.db.Sqlite",
			"sys.db.Mysql",
			"sys.db.Connection",
			"sys.db.ResultSet",
			"haxe.remoting.Proxy",
		];

		if(Context.defined("sys")) {
			for(inc in ["sys", "openfl.net", "funkin.backend.system.net"]) {
				if(!isHl) Compiler.include(inc, compathx4);
				else {

					// TODO: Hashlink
					//Compiler.include(inc, compathx4.concat(["sys.net.UdpSocket", "openfl.net.DatagramSocket"]); // fixes FATAL ERROR : Failed to load function std@socket_set_broadcast
				}
			}
		}

		Compiler.include("funkin", [#if !UPDATE_CHECKING 'funkin.backend.system.updating' #end]);
	}

	public static function initMacros() {
		if (Context.defined("hl")) {
			for (c in ["lime", "std", "Math", ""]) Compiler.addGlobalMetadata(c, "@:build(funkin.backend.system.macros.HashLinkFixer.build())");
		}

		final macroPath = 'funkin.backend.system.macros.Macros';
		Compiler.addMetadata('@:build($macroPath.buildLimeAssetLibrary())', 'lime.utils.AssetLibrary');
		Compiler.addMetadata('@:build($macroPath.buildLimeApplication())', 'lime.app.Application');
		Compiler.addMetadata('@:build($macroPath.buildLimeWindow())', 'lime.ui.Window');
		Compiler.addMetadata('@:build($macroPath.buildOpenflAssets())', 'openfl.utils.Assets');

		//Adds Compat for #if hscript blocks when you have hscript improved
		if (Context.defined("hscript_improved") && !Context.defined("hscript")) {
			Compiler.define('hscript');
		}
	}

	public static function buildLimeAssetLibrary():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();

		fields.push({name: 'tag', access: [APublic], pos: pos, kind: FVar(macro :funkin.backend.assets.AssetSource)});
		fields.push({name: 'isCompressed', access: [APublic], pos: pos, kind: FVar(macro :Bool, macro false)});

		return fields;
	}

	public static function buildLimeApplication():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		for (f in fields) switch (f.kind) {
			case FFun(func): switch (f.name) {
				case "exec": switch (func.expr.expr) {
					case EBlock(exprs): exprs.insert(1, macro funkin.backend.system.Main.preInit());
					default:
				}
			}
			default:
		}

		return fields;
	}

	public static function buildLimeWindow():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		if (!Context.defined("DARK_MODE_WINDOW")) return fields;

		for (f in fields) switch (f.kind) {
			case FFun(func): switch (f.name) {
				case "new": switch (func.expr.expr) {
					case EBlock(exprs): exprs.push(macro funkin.backend.utils.NativeAPI.setDarkMode(title, true));
					default:
				}
			}
			default:
		}

		return fields;
	}

	public static function buildOpenflAssets():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();
		for (f in fields) switch (f.name) {
			case "allowHardwareTextures": fields.remove(f);
			default:
		}

		fields.push({name: 'allowHardwareTextures', access: [APublic, AStatic], pos: pos, kind: FProp("get", "set", macro :Bool)});
		fields.push({name: '__allowHardwareTextures', access: [APrivate, AStatic], pos: pos, kind: FVar(macro :Null<Bool>)});

		fields.push({name: "get_allowHardwareTextures", access: [APublic, AStatic, AInline], pos: pos, kind: FFun({ret: macro :Bool, args: [], expr: macro {
			return __allowHardwareTextures != null ? __allowHardwareTextures : !funkin.backend.system.Main.forceGPUOnlyBitmapsOff && funkin.options.Options.gpuOnlyBitmaps;
		}})});
		fields.push({name: "set_allowHardwareTextures", access: [APublic, AStatic, AInline], pos: pos, kind: FFun({ret: macro :Bool, args: [{name: "value", type: macro :Bool}], expr: macro {
			__allowHardwareTextures = value;
			return get_allowHardwareTextures();
		}})});

		return fields;
	}
}
#end