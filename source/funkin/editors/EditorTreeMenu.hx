package funkin.editors;

import flixel.addons.display.FlxBackdrop;
import funkin.options.type.OptionType;

class EditorTreeMenu extends funkin.options.TreeMenu {
	public var bg:FlxBackdrop;
	public var bgType:String = "default";
	public var bgMovement:FlxPoint = new FlxPoint();

	override function create() {
		super.create();
		UIState.setResolutionAware();
		FlxG.camera.fade(0xFF000000, 0.5, true);
	}

	override function createPost() {
		insert(0, bg = new FlxBackdrop());
		bg.loadGraphic(Paths.image('editors/bgs/${bgType}'));
		bg.antialiasing = true;
		setBackgroundRotation(-5);
		super.createPost();

		if (Paths.assetsTree.hasCompressedLibrary) warnCompressLibrary();
	}

	public inline function setBackgroundRotation(rotation:Float) {
		bg.rotation = rotation;
		bg.velocity.set(85, 0).degrees = bg.rotation;
	}

	override function exit() {
		FlxG.switchState(new funkin.menus.MainMenuState());
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		bg.colorTransform.redOffset = lerp(bg.colorTransform.redOffset, 0, 0.0625);
		bg.colorTransform.greenOffset = lerp(bg.colorTransform.greenOffset, 0, 0.0625);
		bg.colorTransform.blueOffset = lerp(bg.colorTransform.blueOffset, 0, 0.0625);
		bg.colorTransform.redMultiplier = lerp(bg.colorTransform.redMultiplier, 1, 0.0625);
		bg.colorTransform.greenMultiplier = lerp(bg.colorTransform.greenMultiplier, 1, 0.0625);
		bg.colorTransform.blueMultiplier = lerp(bg.colorTransform.blueMultiplier, 1, 0.0625);
	}

	override function menuChanged() @:privateAccess {
		super.menuChanged();
		if (previousMenus.length > 0) return; // selected a sub-menu

		var prev = tree[tree.length - 2];
		if (prev == null || prev.curOption == null || !(prev.curOption is OptionType)) return;

		// small flashbang
		var color = cast(prev.curOption, OptionType).editorFlashColor;
		bg.colorTransform.redOffset = 0.25 * color.red;
		bg.colorTransform.greenOffset = 0.25 * color.green;
		bg.colorTransform.blueOffset = 0.25 * color.blue;
		bg.colorTransform.redMultiplier = FlxMath.lerp(1, color.redFloat, 0.25);
		bg.colorTransform.greenMultiplier = FlxMath.lerp(1, color.greenFloat, 0.25);
		bg.colorTransform.blueMultiplier = FlxMath.lerp(1, color.blueFloat, 0.25);
	}

	private function warnCompressLibrary() {
		var warningMessage = "It seems you have libraries loaded that are compressed, and can not have files written to them.\n
		This is just a friendly reminder that if you're loading a Mod and wish to edit files, you need to uncompress it to be able to use any editors!\n\nCompressed Libraries: ";
		var compressedList = Paths.assetsTree.libraries.filter(l -> funkin.backend.assets.AssetsLibraryList.getCleanLibrary(l).isCompressed);
		var modNameList = [for (l in compressedList) {
			l = funkin.backend.assets.AssetsLibraryList.getCleanLibrary(l);
			if (l is funkin.backend.assets.IModsAssetLibrary) cast(l, funkin.backend.assets.IModsAssetLibrary).modName;
		}];
		warningMessage += modNameList.join(", ");
		var zipLibraryWarning = new funkin.editors.ui.UIWarningSubstate("Compressed Library Detected!", warningMessage, [{label: "Ok", color: 0x969533, onClick: (state) -> {} }], false);

		openSubState(zipLibraryWarning);
	}

}

class EditorTreeMenuScreen extends funkin.options.TreeMenuScreen {
	public function new(name:String, desc:String, ?prefix:String, ?objects:Array<FlxSprite>,
		?newButton:String, ?newButtonDesc:String, ?newCallback:Void->Void)
	{
		super(name, desc, prefix, objects);
		if (newCallback != null) {
			insert(0, new funkin.options.type.NewOption(getID(newButton), getID(newButtonDesc), newCallback));
			curSelected = 1;
		}
	}
}