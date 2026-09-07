package hscript;

class Config {
	// Runs support for custom classes in these
	public static final ALLOWED_CUSTOM_CLASSES = [
		#if !DOCUMENTATION
		"flixel",

		"funkin",
		#if MODCHARTING_FEATURES
		"modchart.engine",
		"modchart.backend.standalone",
		#end
		#end
	];

	// Runs support for abstract support in these
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		#if !DOCUMENTATION
		"flixel",
		"openfl",

		"haxe.xml",
		"haxe.CallStack",
		"funkin",
		#end
	];

	// Incase any of your files fail
	// These are the module names
	public static final DISALLOW_CUSTOM_CLASSES = [
		
	];

	public static final DISALLOW_ABSTRACT_AND_ENUM = [
		"funkin.backend.scripting.events.sprite.PlayAnimContext", // Error: expected member name or ';' after declaration specifiers, Due to define macro from math.h
	];

	@:unreflective
	public static final IMPORT_BLACKLIST:Array<String> = [
		"funkin.backend.system.gamejolt.GameJoltSecurity", // don't want people getting those gamejolt keys!
		"funkin.backend.system.gamejolt.GameJoltData", // Global data items and really bad things to modify
	];
}
