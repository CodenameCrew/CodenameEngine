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
			"DateTools", "EReg", "Lambda", "StringBuf", "haxe.crypto", "haxe.display", "haxe.exceptions", "haxe.extern", "scripting"
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

		//Adds Compat for #if hscript blocks when you have hscript improved
		if (Context.defined("hscript_improved") && !Context.defined("hscript")) {
			Compiler.define('hscript');
		}
	}

	public static function buildLimeAssetLibrary():Array<Field> {
		final fields:Array<Field> = Context.getBuildFields(), pos:Position = Context.currentPos();

		fields.push({name: 'tag', access: [APublic], pos: pos, kind: FVar(macro :funkin.backend.assets.AssetSource)});

		return fields;
	}
}
#end