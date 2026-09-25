package funkin.options;

import haxe.xml.Access;
import flixel.util.typeLimit.OneOfThree;
import funkin.editors.ui.UIState;
import funkin.options.categories.*;
import funkin.options.type.*;

typedef OptionCategory = {
	var name:String;
	var desc:String;
	var ?state:OneOfThree<TreeMenuScreen, Class<TreeMenuScreen>, (name:String, desc:String) -> TreeMenuScreen>;
	var ?substate:OneOfThree<MusicBeatSubstate, Class<MusicBeatSubstate>, (name:String, desc:String) -> MusicBeatSubstate>;
	var ?suffix:String;
}

class OptionsMenu extends TreeMenu {
	public static var mainOptions:Array<OptionCategory> = [
		{  // name and desc are actually the translations ids!  - Nex
			name: 'optionsTree.controls-name',
			desc: 'optionsTree.controls-desc',
			suffix: '',
			substate: funkin.options.keybinds.KeybindsOptions
		},
		{
			name: 'optionsTree.gameplay-name',
			desc: 'optionsTree.gameplay-desc',
			state: GameplayOptions
		},
		{
			name: 'optionsTree.appearance-name',
			desc: 'optionsTree.appearance-desc',
			state: AppearanceOptions
		},
		#if TRANSLATIONS_SUPPORT
		{
			name: 'optionsTree.language-name',
			desc: 'optionsTree.language-desc',
			state: LanguageOptions
		},
		#end
		{
			name: 'optionsTree.miscellaneous-name',
			desc: 'optionsTree.miscellaneous-desc',
			state: MiscOptions
		}
	];

	var bg:FlxSprite;
	var debugOption:TextOption;

	override function create() {
		super.create();

		CoolUtil.playMenuSong();

		DiscordUtil.call("onMenuLoaded", ["Options Menu"]);

		add(bg = new FlxSprite().loadAnimatedGraphic(Paths.image('menus/menuBGBlue')));
		bg.antialiasing = true;
		bg.scrollFactor.set();
		updateBG();

		for (i in mainOptions) if (i.name == "optionsTree.language-name" && Flags.DISABLE_LANGUAGES) mainOptions.remove(i);

		addMenu(new TreeMenuScreen('optionsMenu.header.title', 'optionsMenu.header.desc', [for (o in mainOptions) new TextOption(o.name, o.desc, o.suffix != null ? o.suffix : " >", () -> {
			if (o.substate != null) {
				persistentUpdate = false;
				persistentDraw = true;

				if (o.substate is MusicBeatSubstate)
					openSubState(o.substate);
				else if(Reflect.isFunction(o.substate)) {
					var substate:(name:String, desc:String) -> MusicBeatSubstate = o.substate;
					openSubState(substate(o.name, o.desc));
				}
				else // o.substate is Class<TreeMenuScreen>
					openSubState(Type.createInstance(o.substate, [o.name, o.desc]));
			}
			else {
				if (o.state is TreeMenuScreen)
					addMenu(o.state);
				else if (Reflect.isFunction(o.state)) {
					var state:(name:String, desc:String) -> TreeMenuScreen = o.state;
					addMenu(state(o.name, o.desc));
				}
				else { // o.state is Class<TreeMenuScreen>
					addMenu(Type.createInstance(o.state, [o.name, o.desc]));
				}
			}
		})]));

		checkDebugOption();
		var first = tree.first();

		for (i in funkin.backend.assets.ModsFolder.getLoadedMods()) {
			var xmlPath = Paths.xml('config/options/LIB_$i');

			if (Paths.assetsTree.existsSpecific(xmlPath, "TEXT")) {
				var access:Access = null;
				try access = new Access(Xml.parse(Paths.assetsTree.getSpecificAsset(xmlPath, "TEXT")))
				catch(e) Logs.trace('Error while parsing options.xml: ${Std.string(e)}', ERROR);
				if (access != null) for (o in parseOptionsFromXML(first, access)) first.add(o);
			}
		}
	}

	function checkDebugOption() {
		var first = tree.first();
		if (Options.devMode) {
			if (debugOption == null) {
				first.insert(CoolUtil.minInt(first.length, mainOptions.length),
					debugOption = new TextOption('optionsTree.debug-name', 'optionsTree.debug-desc', ' >', () -> addMenu(new DebugOptions()))
				);
			}
		}
		else if (debugOption != null) {
			first.remove(debugOption, true);
			debugOption = flixel.util.FlxDestroyUtil.destroy(debugOption);
			if (first.curSelected >= first.length) first.changeSelection(0, true);
		}
	}

	public function updateBG() {
		var scaleX:Float = FlxG.width / bg.width;
		var scaleY:Float = FlxG.height / bg.height;
		bg.scale.x = bg.scale.y = Math.max(scaleX, scaleY) * 1.15;
		bg.screenCenter();
	}

	override function onResize(width:Int, height:Int) {
		super.onResize(width, height);
		if (!UIState.resolutionAware) return;

		updateBG();
	}

	override function menuChanged() {
		super.menuChanged();
		checkDebugOption();
	}

	override function exit() {
		Options.save();
		Options.applySettings();
		super.exit();
	}

	// XML STUFF
	public function parseOptionsFromXML(screen:TreeMenuScreen, xml:Access):Array<FlxSprite> {
		var options:Array<FlxSprite> = [];

		for(node in xml.elements) {
			switch(node.name) {
				case "separator":
					options.push(new Separator(node.has.height ? Std.parseFloat(node.att.height) : 67));
			}

			if (!node.has.name) {
				Logs.warn("An option node requires a name attribute.");
				continue;
			}
			var name = node.getAtt("name");
			var desc = node.getAtt("desc").getDefault("optionsMenu.desc-missing");
			if (screen.prefix?.length > 0) {
				name = screen.prefix + name;
				if (node.has.desc) desc = screen.prefix + desc;
			}

			switch(node.name) {
				case "checkbox":
					if (!node.has.id) {
						Logs.warn("A checkbox option requires an \"id\" for option saving.");
						continue;
					}
					options.push(new Checkbox(name, desc, node.att.id, null, FlxG.save.data));
				case "number":
					if (!node.has.id) {
						Logs.warn("A number option requires an \"id\" for option saving.");
						continue;
					}
					var step = node.has.change ? Std.parseFloat(node.att.change) : (node.has.step ? Std.parseFloat(node.att.step) : null);
					options.push(new NumOption(name, desc, Std.parseFloat(node.att.min), Std.parseFloat(node.att.max), step, node.att.id, null, FlxG.save.data));
				case "choice":
					if (!node.has.id) {
						Logs.warn("A choice option requires an \"id\" for option saving.");
						continue;
					}

					var optionOptions:Array<Dynamic> = [];
					var optionDisplayOptions:Array<String> = [];

					for(choice in node.elements) {
						optionOptions.push(choice.att.value);
						optionDisplayOptions.push(choice.att.name);
					}

					if(optionOptions.length > 0)
						options.push(new ArrayOption(name, desc, optionOptions, optionDisplayOptions, node.att.id, null, FlxG.save.data));
				case 'radio':
					if (!node.has.id) {
						Logs.warn("A radio option requires an \"id\" for option saving.");
						continue;
					}
					var f = Std.parseFloat(node.att.value);
					options.push(new RadioButton(screen, name, desc, node.att.id, Math.isNaN(f) ? node.att.value : f, null, FlxG.save.data, node.has.forId ? node.att.forId : null));
				case 'slider':
					if (!node.has.id) {
						Logs.warn("A slider option requires an \"id\" for option saving.");
						continue;
					}
					var step = node.has.change ? Std.parseFloat(node.att.change) : (node.has.step ? Std.parseFloat(node.att.step) : null);
					var segments = node.has.segments ? Std.parseInt(node.att.segments) : 5;
					options.push(new SliderOption(name, desc, Std.parseFloat(node.att.min), Std.parseFloat(node.att.max), step, segments, node.att.id, Std.parseInt(node.att.barWidth), null, FlxG.save.data));
				case "menu":
					options.push(new TextOption(name, desc, ' >', () -> {
						var screen = new TreeMenuScreen(name, desc, node.getAtt("prefix").getDefault(""));
						for (o in parseOptionsFromXML(screen, node)) screen.add(o);
						addMenu(screen);
					}));
			}
		}

		return options;
	}
}
