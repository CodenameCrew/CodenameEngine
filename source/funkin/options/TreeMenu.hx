package funkin.options;

import flixel.tweens.FlxTween;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import funkin.backend.FunkinText;
import funkin.backend.system.framerate.Framerate;
import funkin.editors.ui.UIState;

interface ITreeOption {
	var desc:String;
	var selected:Bool;

	function changeSelection(change:Int):Void;
	function select():Void;
}

interface ITreeFloatOption extends ITreeOption {
	function changeValue(change:Float):Void;
}

class TreeMenu extends UIState {
	public var onMenuClosed:FlxTypedSignal<TreeMenuScreen->Void> = new FlxTypedSignal();
	public var onMenuChanged:FlxTypedSignal<TreeMenuScreen->Void> = new FlxTypedSignal();

	public var tree(default, null):Array<TreeMenuScreen> = [];
	public var treeLength(default, null):Int = 0;
	public var previousMenus:Array<TreeMenuScreen> = [];
	public var destroyMenus:Bool = true;

	public var exitCallback:TreeMenu->Void;

	public var titleLabel:FunkinText;
	public var descLabel:FunkinText;
	public var bgLabel:FlxSprite;

	var menuChangeTween:FlxTween;
	var __drawer:TreeMenuDrawer;
	var __treeCreated:Bool = false;

	public function new(?exitCallback:TreeMenu->Void,
		scriptsAllowed:Bool = true, ?scriptName:String)
	{
		super(scriptsAllowed, scriptName);
		this.exitCallback = exitCallback;
	}

	override function create() {
		super.create();

		bgLabel = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bgLabel.alpha = 0.25;
		bgLabel.scrollFactor.set();

		titleLabel = new FunkinText(4, 4, FlxG.width - 8, 32);
		titleLabel.borderSize = 1.25;
		titleLabel.scrollFactor.set();

		descLabel = new FunkinText(4, 0, FlxG.width - 8, 16);
		descLabel.scrollFactor.set();
	}

	override function createPost() {
		super.createPost();

		if ((treeLength = tree.length) != 0) {
			updateMenuPositions(true);
			tree.last().inputEnabled = true;
		}
		else
			addMenu(new TreeMenuScreen("Fallback TreeMenuScreen", "Please insert menus into \"tree\" variable in your extended class in create or before createPost"));

		add(__drawer = new TreeMenuDrawer(this));
		add(bgLabel);
		add(titleLabel);
		add(descLabel);

		FlxG.camera.scroll.x = -FlxG.width;
		menuChanged();

		__treeCreated = true;
	}

	public function updateMenuPositions(fromIndex:Int = 0, cameraScroll = false) {
		var last = tree[fromIndex - 1], menu:TreeMenuScreen;
		while (fromIndex < treeLength) if ((menu = tree[fromIndex++]) != null) {
			menu.x = last == null ? 0 : last.x + Math.max(FlxG.width, last.width);
			(last = menu).parent = this;
		}

		if (cameraScroll && last != null) {
			if (menuChangeTween != null && menuChangeTween.active) menuChangeTween.cancel();
			FlxG.camera.scroll.x = last.x;

			for (menu in tree) if (menu != null) menu.transitioning = false;
			for (menu in previousMenus) if (menu != null) menu.transitioning = false;
		}
	}

	public function updateLabels() {
		var s = "", last = tree.last();
		for (menu in tree) if (menu != null) s += menu.name + " > ";

		titleLabel.text = s;
		descLabel.y = titleLabel.y + titleLabel.height + 2;

		updateDesc();
	}

	public function updateDesc(?customText:String) {
		var last = tree.last();

		descLabel.text = last.desc;
		if (customText != null && customText.length > 0) descLabel.text += "\n" + customText;
		else if (last.curSelected >= 0 && last.curSelected < last.length && last.members[last.curSelected] is ITreeOption)
			descLabel.text += "\n" + cast(last.members[last.curSelected], ITreeOption).desc;

		bgLabel.scale.set(FlxG.width, descLabel.y + descLabel.height + 2);
		bgLabel.updateHitbox();

		Framerate.offset.y = bgLabel.height + 2;
	}

	public function addMenu(menu:TreeMenuScreen):TreeMenuScreen {
		if (menu == null) return null;
		if (tree.indexOf(menu) != -1) return menu;

		tree.push(menu);
		if (!__treeCreated) return menu;

		menu.parent = this;
		treeLength++;

		var prev = tree[treeLength - 2];
		menu.x = prev == null ? 0 : prev.x + Math.max(FlxG.width, prev.width);

		destroyPreviousMenus();
		menuChanged();
		menu.inputEnabled = true;
		if (prev != null) prev.inputEnabled = false;

		return menu;
	}

	public function insertMenu(position:Int, menu:TreeMenuScreen):TreeMenuScreen {
		if (menu == null) return null;
		if (tree.indexOf(menu) != -1) return menu;

		if (position < 0) position = treeLength - ((-position - 1) % treeLength);

		tree.insert(position, menu);
		if (!__treeCreated) return menu;

		menu.parent = this;

		var lastChanged = position >= treeLength++;
		updateMenuPositions(position, !lastChanged);

		if (lastChanged) {
			destroyPreviousMenus();
			menuChanged();
			menu.inputEnabled = true;
			if (treeLength > 0) tree[treeLength - 2].inputEnabled = false;
		}

		return menu;
	}

	public function popMenu():TreeMenuScreen
		return removeMenuPosition(treeLength - 1);

	public function removeMenu(menu:TreeMenuScreen):TreeMenuScreen
		return if (menu == null) null; else removeMenuPosition(tree.indexOf(menu));

	public function removeMenuPosition(position:Int):TreeMenuScreen {
		if (position < 0 || position >= treeLength || treeLength == 0) return null;

		tree[position] = tree[tree.length - 1];
		var menu = tree.pop();
		menu.parent = null;

		if (!__treeCreated) return menu;

		previousMenus.push(menu);
		if (position == --treeLength) {
			menuChanged();
			menu.inputEnabled = false;
			if (treeLength > 0) tree[treeLength - 1].inputEnabled = true;
		}
		else {
			updateMenuPositions(position, true);
			updateLabels();
		}

		onMenuClosed.dispatch(menu);
		return menu;
	}

	public function menuChanged() {
		if (treeLength == 0) exit();
		else {
			updateLabels();

			if (menuChangeTween != null && menuChangeTween.active) menuChangeTween.cancel();
			menuChangeTween = FlxTween.tween(FlxG.camera.scroll, {x: tree.last().x}, 1.5, {ease: menuTransitionEase, onComplete: (t) -> {
				for (menu in tree) if (menu != null) menu.transitioning = false;
				for (menu in previousMenus) if (menu != null) menu.transitioning = false;
			}});

			for (menu in tree) if (menu != null) menu.transitioning = true;
		}

		for (menu in previousMenus) if (menu != null) menu.transitioning = true;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var i = 0, menu:TreeMenuScreen;
		while (i < treeLength) {
			if ((menu = tree[i++]) == null || !menu.active || !menu.exists) continue;
			if (i == treeLength || menu.persistentUpdate || menu.transitioning) menu.update(elapsed);
		}

		i = previousMenus.length;
		while (i-- > 0) {
			if ((menu = previousMenus[i]).transitioning) menu.update(elapsed);
			else {
				menu.destroy();
				FlxArrayUtil.swapAndPop(previousMenus, i);
			}
		}

		// in case path gets so long it goes offscreen, ALTHOUGH this nevers happens anyway since we have set a expected width to the label.
		//titleLabel.x = lerp(titleLabel.x, Math.max(0, FlxG.width - 4 - titleLabel.width), 0.125);
	}

	override function destroy() {
		super.destroy();
		destroyPreviousMenus();
	}

	override function onResize(width:Int, height:Int) {
		super.onResize(width, height);
		if (!UIState.resolutionAware) return;

		if (width < FlxG.initialWidth || height < FlxG.initialHeight) {
			width = FlxG.initialWidth;
			height = FlxG.initialHeight;
		}

		updateMenuPositions(true);
		descLabel.width = titleLabel.width = (bgLabel.scale.x = width) - 8;
		bgLabel.updateHitbox();
	}

	public function reloadStrings() {
		for (menu in tree) if (menu != null) menu.reloadStrings();
		updateLabels();
	}

	public function destroyPreviousMenus() {
		for (menu in previousMenus) menu.destroy();
		previousMenus.resize(0);
	}

	public function exit() {
		if (exitCallback != null) return exitCallback(this);

		FlxG.switchState(new funkin.menus.MainMenuState());
	}

	public function updateAll(elapsed:Float) {
		for (menu in tree) if (menu != null && menu.active && menu.exists) menu.update(elapsed);
	}

	public dynamic function menuTransitionEase(e:Float) return FlxEase.quintInOut(FlxEase.cubeOut(e));
}

final class TreeMenuDrawer extends FlxBasic {
	public var parent:TreeMenu;
	public function new(parent:TreeMenu) {
		super();
		this.parent = parent;
	}

	override function draw() {
		var i = 0, menu:TreeMenuScreen;
		while (i < parent.treeLength) {
			if ((menu = parent.tree[i++]) == null || !menu.active || !menu.exists) continue;
			if (i == parent.treeLength || menu.persistentUpdate || menu.transitioning) menu.draw();
		}

		i = parent.previousMenus.length;
		while (i-- > 0) if (parent.previousMenus[i] != null) parent.previousMenus[i].draw();
	}
}