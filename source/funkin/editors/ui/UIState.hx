package funkin.editors.ui;

import openfl.Lib;
import funkin.editors.ui.notifications.UIBaseNotification;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.utils.NativeAPI.CodeCursor;
import funkin.editors.ui.UIContextMenu.UIContextMenuCallback;
import funkin.editors.ui.UIContextMenu.UIContextMenuOption;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import flixel.system.scaleModes.StageSizeScaleMode;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;

class UIState extends MusicBeatState {
	public var curContextMenu:UIContextMenu = null;

	public static var state(get, never):UIState;

	private inline static function get_state()
		return FlxG.state is UIState ? cast FlxG.state : null;

	public var buttonHandler:Void->Void = null;
	public var hoveredSprite:UISprite = null;
	public var currentFocus:IUIFocusable = null;

	public var currentCursor:CodeCursor = ARROW;

	public var uiCameras:Array<FlxCamera> = [];

	private var __rect:FlxRect;
	private var __mousePos:FlxPoint;

	static var __point:FlxPoint = new FlxPoint();

	public override function create() {
		__rect = new FlxRect();
		__mousePos = FlxPoint.get();
		super.create();
		Framerate.offset.y = 30;
		FlxG.mouse.visible = true;

		FlxG.stage.window.onKeyDown.add(onKeyDown);
		FlxG.stage.window.onKeyUp.add(onKeyUp);
		FlxG.stage.window.onTextInput.add(onTextInput);
		FlxG.stage.window.onTextEdit.add(onTextEdit);
	}

	private function onKeyDown(e:KeyCode, modifier:KeyModifier) {
		if (currentFocus != null)
			currentFocus.onKeyDown(e, modifier);
	}

	private function onKeyUp(e:KeyCode, modifier:KeyModifier) {
		if (currentFocus != null)
			currentFocus.onKeyUp(e, modifier);
	}

	private function onTextInput(str:String) {
		if (currentFocus != null)
			currentFocus.onTextInput(str);
	}
	private function onTextEdit(str:String, start:Int, end:Int) {
		if (currentFocus != null)
			currentFocus.onTextEdit(str, start, end);
	}

	public function updateButtonHandler(spr:UISprite, buttonHandler:Void->Void) {
		spr.updateSpriteRect();
		updateRectButtonHandler(spr, spr.__rect, buttonHandler);
	}

	public function isOverlapping(spr:UISprite, rect:FlxRect) {
		for(camera in spr.__lastDrawCameras) {
			var pos = FlxG.mouse.getScreenPosition(camera, __point);
			__rect.copyFrom(rect);

			__rect.x = __rect.x - camera.scroll.x * spr.scrollFactor.x;
			__rect.y = __rect.y - camera.scroll.y * spr.scrollFactor.y;

			if (((pos.x > __rect.x) && (pos.x < __rect.x + __rect.width)) && ((pos.y > __rect.y) && (pos.y < __rect.y + __rect.height))) {
				return true;
			}
		}
		return false;
	}

	public function updateRectButtonHandler(spr:UISprite, rect:FlxRect, buttonHandler:Void->Void) {
		if(isOverlapping(spr, rect)) {
			spr.hoveredByChild = true;
			this.hoveredSprite = spr;
			this.buttonHandler = buttonHandler;
		}
	}

	public override function tryUpdate(elapsed:Float) {
		FlxG.mouse.getScreenPosition(FlxG.camera, __mousePos);

		super.tryUpdate(elapsed);

		if (buttonHandler != null) {
			buttonHandler();
			buttonHandler = null;
		}

		if (FlxG.mouse.justPressed) {
			playEditorSound(Flags.DEFAULT_EDITOR_CLICK_SOUND);
		}

		if (FlxG.mouse.justReleased)
			currentFocus = (hoveredSprite is IUIFocusable) ? (cast hoveredSprite) : null;

		FlxG.sound.keysAllowed = currentFocus != null ? !(currentFocus is UITextBox) : true;

		if (hoveredSprite != null && hoveredSprite.cursor != null) {
			NativeAPI.setCursorIcon(hoveredSprite.cursor);
		} else {
			NativeAPI.setCursorIcon(currentCursor);
		}
		hoveredSprite = null;
	}

	public override function destroy() {
		if (resolutionAware) {
			resolutionAware = false;

			for (camera in FlxG.cameras.list) {
				camera.width = FlxG.initialWidth;
				camera.height = FlxG.initialHeight;
			}
			FlxG.scaleMode = Main.scaleMode;
		}

		super.destroy();
		__mousePos.put();

		DrawUtil.destroyDrawers();
		WindowUtils.resetAffixes();
		SaveWarning.reset();

		FlxG.stage.window.onKeyDown.remove(onKeyDown);
		FlxG.stage.window.onKeyUp.remove(onKeyUp);
		FlxG.stage.window.onTextInput.remove(onTextInput);
		FlxG.stage.window.onTextEdit.remove(onTextEdit);
	}

	public function closeCurrentContextMenu() {
		playEditorSound(Flags.DEFAULT_EDITOR_WINDOWCLOSE_SOUND);
		if(curContextMenu != null) {
			curContextMenu.close();
			curContextMenu = null;
		}
	}

	public function openContextMenu(options:Array<UIContextMenuOption>, ?callback:UIContextMenuCallback, ?x:Float, ?y:Float, ?w:Int) {
		playEditorSound(Flags.DEFAULT_EDITOR_WINDOWAPPEAR_SOUND);
		var state = FlxG.state;
		while(state.subState != null && !(state._requestSubStateReset && state._requestedSubState == null))
			state = state.subState;

		state.persistentDraw = true;
		state.persistentUpdate = true;

		state.openSubState(curContextMenu = new UIContextMenu(options, callback, x.getDefault(__mousePos.x), y.getDefault(__mousePos.y), w));
		return curContextMenu;
	}

	public function displayNotification(notification:UIBaseNotification) {
		notification.cameras = uiCameras;
		notification.onRemove = (notif) -> {
			notification.onRemove = null;
			remove(notif, true);
		};
		add(notification);
		notification.update(0);
		notification.appearAnimation();
		// TODO: future tooltips
		//notification.x = __mousePos.x;
		//notification.y = __mousePos.y;
		//notification.alpha = 0;
		//notification.appearAnimation();
		//FlxTween.tween(notification, {x: __mousePos.x, y: __mousePos.y, alpha: 1}, .3, {ease: FlxEase.circInOut});
	}

	public static var resolutionAware:Bool = false;
	public static var uiScaleMode:UIScaleMode = new UIScaleMode();

	public static function setResolutionAware() {
		resolutionAware = true;
		FlxG.scaleMode = uiScaleMode;
	}

	public static function playEditorSound(path:String) {
		if (!Options.editorSFX) return;
		FlxG.sound.play(Paths.sound(path));
	}
}