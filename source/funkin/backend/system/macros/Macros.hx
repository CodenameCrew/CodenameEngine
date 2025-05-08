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
			"flxsvg",
			// BASE HAXE
			"DateTools", "EReg", "Lambda", "StringBuf", "haxe.crypto", "haxe.display", "haxe.exceptions", "haxe.extern", "scripting"
		])
			Compiler.include(inc);

		var isHl = Context.defined("hl");

		if(Context.defined("sys")) {
			for(inc in ["sys", "openfl.net", "funkin.backend.system.net"]) {
				if(!isHl)
					Compiler.include(inc);
				else {
					// TODO: Hashlink
					//Compiler.include(inc, ["sys.net.UdpSocket", "openfl.net.DatagramSocket"]); // fixes FATAL ERROR : Failed to load function std@socket_set_broadcast
				}
			}
		}

		Compiler.include("funkin", [#if !UPDATE_CHECKING 'funkin.backend.system.updating' #end]);
	}

	public static function initMacros() {
		if(Context.defined("hl"))
			HashLinkFixer.init();
	}
}
#end
