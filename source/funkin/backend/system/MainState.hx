package funkin.backend.system;

#if MOD_SUPPORT
import sys.FileSystem;
#end
import flixel.FlxState;
import funkin.backend.assets.AssetsLibraryList;
import funkin.backend.assets.ModsFolder;
import funkin.backend.assets.ModsFolderLibrary;
import funkin.backend.chart.EventsData;
import funkin.backend.system.framerate.Framerate;
import funkin.editors.ModConfigWarning;
import funkin.menus.TitleState;
import haxe.io.Path;

@dox(hide)
typedef AddonInfo = {
	var name:String;
	var path:String;
}

/**
 * Simple state used for loading the game
 */
class MainState extends FlxState {
	public static var initiated:Bool = false;
	public override function create() {
		super.create();
		if (!initiated) {
			Main.loadGameSettings();
		}

		initiated = true;

		#if sys
		CoolUtil.deleteFolder('./.temp/'); // delete temp folder
		#end
		Options.save();

		ControlsUtil.resetCustomControls();
		FlxG.bitmap.reset();
		FlxG.sound.destroy(true);

		Paths.assetsTree.reset();

		#if MOD_SUPPORT
		inline function isDirectory(path:String):Bool
			return FileSystem.exists(path) && FileSystem.isDirectory(path);

		inline function ltrim(str:String, prefix:String):String
			return str.substr(prefix.length).ltrim();

		inline function loadLib(path:String, name:String)
			Paths.assetsTree.addLibrary(ModsFolder.loadModLib(path, name));

		var _lowPriorityAddons:Array<AddonInfo> = [];
		var _highPriorityAddons:Array<AddonInfo> = [];
		var _noPriorityAddons:Array<AddonInfo> = [];

		var addonPaths = [
			ModsFolder.addonsPath,
			(
				ModsFolder.currentModFolder != null ?
					ModsFolder.modsPath + ModsFolder.currentModFolder + "/addons/" :
					null
			)
		];

		for (path in addonPaths) {
			if (path == null) continue;
			if (!isDirectory(path)) continue;

			for (addon in FileSystem.readDirectory(path)) {
				if (!FileSystem.isDirectory(path + addon)) {
					switch(Path.extension(addon).toLowerCase()) {
						case 'zip':
							addon = Path.withoutExtension(addon);
						default:
							continue;
					}
				}

				var data:AddonInfo = {
					name: addon,
					path: path + addon
				};

				if (addon.startsWith("[LOW]")) _lowPriorityAddons.insert(0, data);
				else if (addon.startsWith("[HIGH]")) _highPriorityAddons.insert(0, data);
				else _noPriorityAddons.insert(0, data);
			}
		}
		#end

		funkin.backend.scripting.Script.staticVariables.clear();

		#if MOD_SUPPORT
		for (addon in _lowPriorityAddons)
			loadLib(addon.path, ltrim(addon.name, "[LOW]"));

		if (ModsFolder.currentModFolder != null)
			loadLib(ModsFolder.modsPath + ModsFolder.currentModFolder, ModsFolder.currentModFolder);

		for (addon in _noPriorityAddons)
			loadLib(addon.path, addon.name);

		for (addon in _highPriorityAddons)
			loadLib(addon.path, ltrim(addon.name, "[HIGH]"));
		#end

		Flags.reset();
		Flags.load();
		funkin.savedata.FunkinSave.init();

		TranslationUtil.findAllLanguages();
		TranslationUtil.setLanguage(Flags.DISABLE_LANGUAGES ? Flags.DEFAULT_LANGUAGE : null);
		ModsFolder.onModSwitch.dispatch(ModsFolder.currentModFolder); // Loads global.hx
		MusicBeatTransition.script = Flags.DEFAULT_TRANSITION_SCRIPT;
		WindowUtils.resetAffixes(false);
		WindowUtils.setWindow();
		Main.refreshAssets();
		DiscordUtil.init();
		EventsData.reloadEvents();
		ControlsUtil.loadCustomControls();
		TitleState.initialized = false;

		if (Framerate.isLoaded)
			Framerate.instance.reload();

		#if sys
		CoolUtil.safeAddAttributes('./.temp/', NativeAPI.FileAttribute.HIDDEN);
		#end

		var startState:Class<FlxState> = Flags.DISABLE_WARNING_SCREEN ? TitleState : funkin.menus.WarningState;

		if (Options.devMode && Options.allowConfigWarning) {
			var lib:ModsFolderLibrary;
			for (e in Paths.assetsTree.libraries) if ((lib = cast AssetsLibraryList.getCleanLibrary(e)) is ModsFolderLibrary
				&& lib.modName == ModsFolder.currentModFolder)
			{
				if (lib.exists(Paths.ini("config/modpack"), lime.utils.AssetType.TEXT)) break;

				FlxG.switchState(new ModConfigWarning(lib, startState));
				return;
			}
		}

		FlxG.switchState(cast Type.createInstance(startState, []));
	}
}
