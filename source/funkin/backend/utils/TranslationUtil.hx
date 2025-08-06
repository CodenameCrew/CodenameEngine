package funkin.backend.utils;

import funkin.backend.utils.IniUtil;
import funkin.backend.assets.TranslatedAssetLibrary;
import funkin.backend.assets.ModsFolder;
import openfl.utils.Assets;
import haxe.io.Path;
import haxe.xml.Access;
import haxe.Exception;
import funkin.backend.utils.translations.FormatUtil;

/**
 * The class used for translations based on the XMLs inside the translations folders.
 *
 * Made by @NexIsDumb originally for the Poldhub mod.
 */
@:allow(funkin.backend.assets.TranslatedAssetLibrary)
final class TranslationUtil
{
	/**
	 * The current language selected translation map.
	 *
	 * It'll never be `null`.
	 */
	public static var stringMap(default, set):Map<String, IFormatInfo> = [];

	/**
	 * The alternative language selected translation map.
	 * It is filled with the default language.
	 *
	 * This is filled in if the current language is not the same as the default language.
	 * Its used when showMissingIds in the config is false (or is not present).
	 *
	 * It'll never be `null`.
	**/
	public static var alternativeStringMap(default, set):Map<String, IFormatInfo> = [];

	/**
	 * Returns the current language config.
	 */
	public static var config:Map<String, String> = [];
	/**
	 * Returns the current language.
	 */
	public static var curLanguage(get, set):String;
	/**
	 * Returns the current language name.
	 */
	public static var curLanguageName(get, set):String;

	/**
	 * Returns if the current language is the default one (`DEFAULT_LANGUAGE`).
	 */
	public static var isDefaultLanguage(get, never):Bool;

	/**
	 * Returns if any translation are loaded.
	 */
	public static var isLanguageLoaded(get, never):Bool;

	/**
	 * Returns an array has a list of the languages that were found.
	 */
	public static var foundLanguages:Array<String> = [];

	// Private
	private static inline var LANG_FOLDER:String = "languages";
	private static var langConfigs:Map<String, Map<String, String>> = [];
	private static var nameMap:Map<String, String> = [];
	private static inline function getDefaultNameMap():Map<String, String> {
		return [Flags.DEFAULT_LANGUAGE => Flags.DEFAULT_LANGUAGE_NAME];
	}
	private static inline function getDefaultLangConfigs():Map<String, Map<String, String>> {
		return [Flags.DEFAULT_LANGUAGE => getDefaultConfig(Flags.DEFAULT_LANGUAGE)];
	}
	@:noUsing private static inline function getDefaultConfig(name:String):Map<String, String> {
		return ["name" => getLanguageName(name), "credits" => "", "version" => "1.0.0"];
	}

	/**
	 * Updates the language.
	 * Also changes the translations map.
	 *
	 * If `name` is `null`, its gonna use the current language.
	 * If `name` is not `null`, it will load the translations for the given language.
	 */
	public static function setLanguage(?name:String):Void {
		#if TRANSLATIONS_SUPPORT
		if(name == null) name = curLanguage;
		if(!langConfigs.exists(name)) name = Flags.DEFAULT_LANGUAGE;
		if(!langConfigs.exists(name)) name = foundLanguages[0];

		if(curLanguage != name) {
			Logs.traceColored([
				Logs.getPrefix("Language"),
				Logs.logText("Changing saved language to: "),
				Logs.logText('${getLanguageName(name)} ($name)', GREEN)
			], INFO);
			// todo: make this into a notification system for the user
			// notification would be in previous language
			// but only if the user didnt manually change it.
			curLanguage = name;
		} else {
			Logs.traceColored([
				Logs.getPrefix("Language"),
				Logs.logText("Setting Language To: "),
				Logs.logText('${getLanguageName(name)} ($name)', GREEN)
			], VERBOSE);
		}

		for(mod in ModsFolder.getLoadedModsLibs(false))
			if(mod is TranslatedAssetLibrary)
				cast(mod, TranslatedAssetLibrary).langFolder = name;

		config = getConfig(name);
		stringMap = loadLanguage(name);
		alternativeStringMap = name == Flags.DEFAULT_LANGUAGE || config.get("showMissingIds").getDefault("false") == "true" ? [] : loadLanguage(Flags.DEFAULT_LANGUAGE);
		#end
	}

	/**
	 * This is for checking and getting a translation, `defString` it's just the string that gets returned just in case it won't find the translation OR the current language selected is ``DEFAULT_LANGUAGE``.
	 *
	 * If `id` is `null` then it's gonna search using `defString`.
	 */
	public static inline function get(?id:String, ?params:Array<Dynamic>, ?def:String):String
		return getRaw(id, def).format(params);

	public static inline function translate(?id:String, ?params:Array<Dynamic>, ?def:String):String
		return get(id, params, def);

	public static inline function translateDiff(?id:String, ?params:Array<Dynamic>):String
		return get("diff." + id.toLowerCase(), params, id);

	public static function exists(id:String):Bool {
		#if TRANSLATIONS_SUPPORT
		for (map in [stringMap, alternativeStringMap]) if (map.exists(id)) return true;
		#end
		return false;
	}

	public static function getRaw(id:String, ?def:String):IFormatInfo
	{
		#if TRANSLATIONS_SUPPORT
		for (map in [stringMap, alternativeStringMap]) if (map.exists(id))
			return map.get(id);
		#end

		if(def != null)
			return FormatUtil.get(def);

		return FormatUtil.getStr("{" + id + "}");

		/*if(curLanguage == Flags.DEFAULT_LANGUAGE) {
			return FormatUtil.getStr("{" + id + "}");
		} else {

		}

		return FormatUtil.get(showMissingIds ? "{" + id + "}" : id);*/
	}

	/**
	 * Formats a normal string into an ID for translations.
	 *
	 * Example: `Resume Song` => `resumeSong`
	 */
	public static function raw2Id(str:String):String
	{
		str = str.trim().toLowerCase();
		return [for(i => s in str.split(" "))
			i != 0 ? s.charAt(0).toUpperCase() + s.substr(1) : s
		].join("");
	}

	public static inline function isBlacklisted(lang:String):Bool
		return Flags.BLACKLISTED_LANGUAGES.contains(lang);

	public static inline function isWhitelisted(lang:String):Bool
		return Flags.WHITELISTED_LANGUAGES.length == 0 || Flags.WHITELISTED_LANGUAGES.contains(lang);

	public static inline function isAllowed(lang:String):Bool
		return isWhitelisted(lang) && !isBlacklisted(lang);

	/**
	 * Returns an array that specifies which languages were found.
	 */
	public static function findAllLanguages():Void
	{
		#if TRANSLATIONS_SUPPORT
		foundLanguages = [];
		nameMap = getDefaultNameMap();
		langConfigs = getDefaultLangConfigs();
		var mainPath:String = translationsMain("");
		var langName:String = null;
		for (lang in Paths.assetsTree.getFolders("assets/" + mainPath)) {
			if (!isAllowed(lang)) continue;

			var path:String = Path.join([mainPath, lang, "config.ini"]);
			var config = getDefaultConfig(lang);

			if(Assets.exists(path)) {
				var c = IniUtil.parseAsset(path);
				for (i => v in c)
					for (key => value in v)
						config[key] = value;
			} else { // if there was no config.ini, use the file name as the language name
				for(file in Paths.getFolderContent(mainPath + lang).sortAlphabetically()) {
					if(Path.extension(file) == "xml") {
						config["name"] = Path.withoutExtension(file);
						break;
					}
				}
			}
			langName = config["name"];
			nameMap.set(lang, langName);
			langConfigs.set(lang, config);
			foundLanguages.push('$lang/$langName');
		}

		// Ensure that the default language is always first
		var defaultName = Flags.DEFAULT_LANGUAGE + "/" + getLanguageName(Flags.DEFAULT_LANGUAGE);
		if(foundLanguages.contains(defaultName)) foundLanguages.remove(defaultName);
		foundLanguages.insert(0, defaultName);

		if(!nameMap.exists(curLanguage)) curLanguage = Flags.DEFAULT_LANGUAGE;
		Logs.trace("Found languages: " + foundLanguages.join(", "), "Language");
		#end
	}

	/**
	 * Returns a map of translations based on its XML.
	 */
	public static function loadLanguage(lang:String):Map<String, IFormatInfo>
	{
		#if TRANSLATIONS_SUPPORT
		FormatUtil.clear(); // Clean up the format cache
		var mainPath:String = translationsMain(lang);
		var leMap:Map<String, IFormatInfo> = [];
		var translations:Array<TranslationPair> = [];

		final NODE_NAMES = ["text", "trans", "lang", "string", "str"];
		function parseXml(xml:Access, prefix:String = "") {
			for(node in xml.elements) {
				if (node.name == "group") // Cosmetic name
					parseXml(node, prefix + (node.has.prefix ? node.att.prefix : ""));
				else if(NODE_NAMES.contains(node.name))
					translations.push({
						prefix: prefix,
						node: node
					});
			}
		}

		// todo make it load the default languages in a second string map

		for(mod in ModsFolder.getLoadedModsLibs(true)) for(file in mod.getFiles("assets/" + mainPath).sortAlphabetically().map((v)->'$mainPath/$v')) {
			if(Path.extension(file).toLowerCase() != "xml") continue;

			// Parse the XML
			var xml:Access = null;
			try xml = new Access(Xml.parse(Assets.getText("assets/" + file)))
			catch(e) Logs.error('Error while parsing $file: ${Std.string(e)}', "Language");

			if (xml == null) continue;
			if (!xml.hasNode.language) {
				Logs.warn('File $file requires a <language> root element.', "Language");
				continue;
			}

			var langNode = xml.node.language;
			var prefix = langNode.getAtt("prefix").getDefault("");

			//if (langNode.has.name) {
			//	getConfig(lang).set("name", langNode.att.name);
			//}

			parseXml(langNode, prefix);
		}

		for(pair in translations) {
			var node = pair.node;
			if (!node.has.id) {
				Logs.warn('A <${node.name}> node requires an ID attribute.', "Language");
				continue;
			}
			var prefix = pair.prefix;

			var id = prefix + node.att.id;

			if(leMap.exists(id)) continue;
			var value:String = node.has.string ? node.att.string : node.innerData;
			if(node.getAtt("notrim").getDefault("true") != "true") value = value.trim();
			// make it so you can escape the backslash
			value = value.replace("\\n", "\n").replace("\r", ""); // remove stupid windows line breaks and convert newline literals to newlines
			leMap.set(id, FormatUtil.get(value));
			//leMap.set(id, FormatUtil.getStr("{" + id + "}"));
			//Logs.trace("Added " + id + " -> `" + value + "`", "Language");
		}

		return leMap;
		#else
		return [];
		#end
	}

	// Utils

	public static function getLanguageName(lang:String):String {
		return nameMap.exists(lang) ? nameMap.get(lang) : lang;
	}

	public static function getLanguageFromName(name:String):String {
		var reverseMap = new Map<String, String>();
		for(key => val in nameMap) reverseMap.set(val, key);
		return reverseMap.exists(name) ? reverseMap.get(name) : name;
	}

	public static function getConfig(lang:String):Map<String, String> {
		return langConfigs.exists(lang) ? langConfigs.get(lang) : getDefaultConfig(lang);
	}

	public static inline function isShowingMissingIds():Bool {
		return Lambda.count(alternativeStringMap) > 0;
	}

	public static inline function translationsMain(key:String):String
		return '$LANG_FOLDER/$key';

	public static inline function translations(key:String):String
		return translationsMain('$curLanguage/$key');

	// getters & setters

	@:noCompletion private static function set_stringMap(value:Map<String, IFormatInfo>):Map<String, IFormatInfo> {
		if (value == null) value = [];
		return stringMap = value;
	}

	@:noCompletion private static function set_alternativeStringMap(value:Map<String, IFormatInfo>):Map<String, IFormatInfo> {
		if (value == null) value = [];
		return alternativeStringMap = value;
	}

	@:noCompletion private static function get_curLanguage():String {
		return Options.language;
	}
	@:noCompletion private static function set_curLanguage(value:String):String {
		return Options.language = value;
	}

	@:noCompletion private static function get_curLanguageName():String {
		return getLanguageName(Options.language);
	}
	@:noCompletion private static function set_curLanguageName(value:String):String {
		return Options.language = getLanguageFromName(value);
	}

	@:noCompletion private static function get_isDefaultLanguage():Bool
		return Options.language == Flags.DEFAULT_LANGUAGE;

	@:noCompletion private static function get_isLanguageLoaded():Bool
		return Lambda.count(stringMap) > 0 || isShowingMissingIds();
}

@:structInit
class TranslationPair {
	public var prefix:String;
	public var node:Access;
}