package funkin.options;

import funkin.editors.ui.UIState;
import flixel.FlxState;
import funkin.backend.FunkinText;
import flixel.tweens.FlxTween;
import funkin.menus.MainMenuState;
import flixel.util.typeLimit.OneOfTwo;
import funkin.options.type.OptionType;
import funkin.options.type.TextOption;
import funkin.backend.system.framerate.Framerate;

class TreeMenu extends UIState {
	public var main:OptionsScreen;
	public var optionsTree:OptionsTree;
	public var pathLabel:FunkinText;
	public var pathDesc:FunkinText;
	public var pathBG:FlxSprite;

	public static var lastState:Class<FlxState> = null;  // Static for fixing the softlock bugs when resetting the state  - Nex

	public function new(scriptsAllowed:Bool = true, ?scriptName:String) {
		if(lastState == null) lastState = Type.getClass(FlxG.state);
		super(scriptsAllowed, scriptName);
	}

	public override function createPost() {
		if (main == null) main = new OptionsScreen("Fallback Treemenu", "Please set the \"main\" variable in your extended class before createPost", [new TextOption("Oops! No Options", "This doesn't look like it was supposed to happen...", () -> FlxG.resetState() ) ]);

		FlxG.camera.scroll.set(-FlxG.width, 0);

		pathLabel = new FunkinText(4, 4, FlxG.width - 8, "> Tree Menu", 32, true);
		pathLabel.borderSize = 1.25;
		pathLabel.scrollFactor.set();

		pathDesc = new FunkinText(4, pathLabel.y + pathLabel.height + 2, FlxG.width - 8, "Current Tree Menu Description", 16, true);
		pathDesc.scrollFactor.set();

		pathBG = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		pathBG.scale.set(FlxG.width, pathDesc.y + pathDesc.height + 2);
		pathBG.updateHitbox();
		pathBG.alpha = 0.25;
		pathBG.scrollFactor.set();

		optionsTree = new OptionsTree();
		optionsTree.onMenuChange = onMenuChange;
		optionsTree.onMenuClose = onMenuClose;
		optionsTree.treeParent = this;
		optionsTree.add(main);


		add(optionsTree);
		add(pathBG);
		add(pathLabel);
		add(pathDesc);


		super.createPost();
	}

	public function onMenuChange() {
		if (optionsTree.members.length <= 0) {
			exit();
		} else {
			if (menuChangeTween != null)
				menuChangeTween.cancel();

			menuChangeTween = FlxTween.tween(FlxG.camera.scroll, {x: FlxG.width * Math.max(0, (optionsTree.members.length-1))}, 1.5, {ease: menuTransitionEase, onComplete: function(t) {
				optionsTree.clearLastMenu();
				menuChangeTween = null;
			}});

			var t = "";
			for(o in optionsTree.members)
				t += '${o.name} > ';
			pathLabel.text = t;

			var idk:OptionsScreen = optionsTree.members.last();
			if (idk.members.length > 0) updateDesc(idk.members[idk.curSelected].desc);
		}
	}

	public function updateDesc(moreTxt:String = '') {
		pathDesc.text = optionsTree.members.last().desc;
		if (moreTxt != null && moreTxt.length > 0) pathDesc.text += '\n' + moreTxt;
		pathBG.scale.set(FlxG.width, pathDesc.y + pathDesc.height + 2);
		pathBG.updateHitbox();
	}

	public function exit() {
		FlxG.switchState((lastState != null) ? Type.createInstance(lastState, []) : new MainMenuState());
		lastState = null;
	}

	public function onMenuClose(m:OptionsScreen) {
		CoolUtil.playMenuSFX(CANCEL);
	}

	var menuChangeTween:FlxTween;
	public override function update(elapsed:Float) {
		super.update(elapsed);
		
		Framerate.offset.y = pathBG.height;

		// in case path gets so long it goes offscreen
		pathLabel.x = lerp(pathLabel.x, Math.max(0, FlxG.width - 4 - pathLabel.width), 0.125);
	}

	public static inline function menuTransitionEase(e:Float)
		return FlxEase.quintInOut(FlxEase.cubeOut(e));
}

typedef OptionCategory = {
	var name:String;
	var desc:String;
	var state:OneOfTwo<OptionsScreen, Class<OptionsScreen>>;
	var ?substate:OneOfTwo<MusicBeatSubstate, Class<MusicBeatSubstate>>;
}

typedef OptionTypeDef = {
	var type:Class<OptionType>;
	var args:Array<Dynamic>;
}
