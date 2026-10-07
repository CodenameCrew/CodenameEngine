package funkin.mobile;

import flixel.graphics.FlxGraphic;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import funkin.backend.FunkinText;
import funkin.backend.utils.ControlsUtil;
import funkin.game.StrumLine;
import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.input.actions.FlxActionInput.FlxInputDevice;
import openfl.display.BitmapData;
import openfl.display.CapsStyle;
import openfl.display.GradientType;
import openfl.display.Graphics;
import openfl.display.JointStyle;
import openfl.display.LineScaleMode;
import openfl.display.Shape;
import openfl.geom.Matrix;

class TouchControls extends FlxBasic {
	public static var instance:TouchControls;
	public static var mouseCaptured:Bool = false;
	public static var capturedTouchIDs:Array<Int> = [];
	public static var tappedTouchIDs:Array<Int> = [];
	public static var controllerActive:Bool = false;

	static var NOTE_IDS:Array<String> = ["left", "down", "up", "right"];
	static var NOTE_COLORS:Array<Int> = [0xC24B99, 0x00FFFF, 0x12FA05, 0xF9393F];
	static var ARROW_SHAPE:Array<Float> = [0, -1, 0.9, -0.05, 0.36, -0.05, 0.36, 0.9, -0.36, 0.9, -0.36, -0.05, -0.9, -0.05];
	static inline var EDGE_GRAB:Float = 28;
	static inline var MODS_PULL_MAX:Float = 150;
	static inline var MODS_PULL_OPEN:Float = 80;
	static inline var TAP_SLOP:Float = 30;
	static inline var TAP_TIME:Float = 0.6;
	static inline var DRAG_STEP:Float = 80;
	static inline var FLING_SPEED:Float = 1400;
	static inline var ACTION_PAD:Float = 24;
	static var hapticBroken:Bool = false;
	static var nativeVibrate:Int->Void;
	static var customButtons:Array<CustomTouchButton> = [];
	static var customRevision:Int = 0;

	public static function init() {
		if (instance != null) return;
		instance = new TouchControls();
		FlxG.plugins.add(instance);
		FlxG.signals.postUpdate.add(instance.applyKeys);
		FlxG.signals.preStateSwitch.add(clearCustomButtons);
	}

	// x/y under 1 is a fraction of the screen, otherwise pixels. cleared next state
	public static function addCustomButton(id:String, key:Dynamic, x:Float, y:Float, ?label:String, ?size:Float) {
		if (id == null || id == "") return;
		var k = parseKey(key);
		var sz = size == null || size <= 0 ? 1.0 : size;
		var text = label == null ? "" : label;
		for (button in customButtons) if (button.id == id) {
			if (button.key == k && button.x == x && button.y == y && button.label == text && button.size == sz) return;
			button.key = k;
			button.x = x;
			button.y = y;
			button.label = text;
			button.size = sz;
			customRevision++;
			return;
		}
		customButtons.push({id: id, key: k, x: x, y: y, label: text, size: sz});
		customRevision++;
	}

	public static function removeCustomButton(id:String) {
		var removed = false;
		var i = customButtons.length;
		while (i-- > 0) if (customButtons[i].id == id) {
			customButtons.splice(i, 1);
			removed = true;
		}
		if (removed) customRevision++;
	}

	public static function clearCustomButtons() {
		if (customButtons.length == 0) return;
		customButtons.resize(0);
		customRevision++;
	}

	static function parseKey(key:Dynamic):FlxKey {
		if (key is Int) return key;
		if (key is String) return FlxKey.fromString(key);
		return FlxKey.NONE;
	}

	public static function isCaptured(id:Int):Bool
		return capturedTouchIDs.contains(id);

	public static function isTap(id:Int):Bool
		return tappedTouchIDs.contains(id);

	var hudCam:FlxCamera;
	var widgets:Array<TouchWidget> = [];
	var graphicCache:Map<String, FlxGraphic> = [];
	var __cache:String = "";
	var mode:TouchLayout = NONE;
	var __layout:String = "";

	var screenLeft:Float = 0;
	var screenTop:Float = 0;
	var screenWidth:Float = 1280;
	var screenHeight:Float = 720;
	var pixelScale:Float = 1;

	var pointerActions:Map<Int, TouchWidget> = [];
	var tracks:Map<Int, PointerTrack> = [];
	var owned:Map<Int, Bool> = [];
	var seen:Map<Int, Bool> = [];
	var stepQueue:Array<FlxKey> = [];
	var stepGap:Int = 0;
	var lastState:flixel.FlxState;

	var draggingId:Null<Int> = null;
	var dragOriginX:Float = 0;
	var dragOriginY:Float = 0;
	var dragPadX:Float = 0;
	var dragPadY:Float = 0;

	var modsTab:TouchWidget;
	var modsPullId:Null<Int> = null;
	var modsPullStartX:Float = 0;
	var modsPullStartTime:Float = 0;
	var modsPullOnTab:Bool = false;
	var modsPullOffset:Float = 0;

	var heldKeys:Array<FlxKey> = [];
	var activeKeys:Array<FlxKey> = [];
	var lastExitBack:Float = -10;
	var time:Float = 0;
	var lastBuzz:Float = -1;
	var skipTouch:Bool = false;
	var arrowFrames:flixel.graphics.frames.FlxFramesCollection;

	public function new() {
		super();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		time += elapsed;

		measureScreen();
		ensureCamera();
		pollController();

		var nextMode = controllerActive ? NONE : currentMode();
		var withTab = nextMode == MENU && inMainMenu();
		var layout = (nextMode:String) + ":" + withTab + ":" + (cutsceneUp() ? (dialogueUp() ? 2 : 1) : 0) + ":" + Options.touchMenuPad + ":" + Math.round(screenWidth) + ":" + Math.round(screenHeight) + ":" + Math.round(Options.touchScale * 100) + ":" + customRevision + ":" + (nextMode == BUTTONS ? songButtons() : 0);
		if (layout != __layout) {
			__layout = layout;
			rebuild(nextMode, withTab);
		}

		if (FlxG.state != lastState) {
			lastState = FlxG.state;
			stepQueue.resize(0);
		}

		capturedTouchIDs.resize(0);
		tappedTouchIDs.resize(0);
		mouseCaptured = false;
		activeKeys.resize(0);
		for (widget in widgets) widget.wants = false;

		if (!skipTouch) {
			pollPointers();
			pollMouseFallback();
		}
		pollAndroidBack();
		pollSteps();
		place(elapsed);
		commitHolds();
		for (key in MobileGamepad.keys)
			if (key != FlxKey.NONE && !activeKeys.contains(key))
				activeKeys.push(key);
		suppressMouse();
		paint(elapsed);
	}

	override function draw() {
		if (mode == NONE || hudCam == null) return;
		for (widget in widgets) {
			if (mode == BUTTONS && widget.kind == WidgetKind.PAD && !widget.custom) continue;
			widget.draw();
		}
	}

	public static function drawPadsUnder(line:StrumLine) {
		if (instance == null || instance.mode != BUTTONS || line == null || line.cpu) return;
		if (PlayState.coopMode) return;
		if (line != instance.playerStrumLine()) return;
		if (line.cameras == null || line.cameras.length == 0) return;

		var i = 0;
		for (widget in instance.widgets) {
			if (widget.kind != WidgetKind.PAD || widget.custom) continue;
			var strum = i < line.members.length ? line.members[i] : null;
			i++;
			if (strum == null) continue;

			var spr = widget.sprite;
			var px = spr.x;
			var py = spr.y;
			var sx = spr.scale.x;
			var sy = spr.scale.y;
			var ox = spr.scrollFactor.x;
			var oy = spr.scrollFactor.y;
			var oldCams = spr.cameras;
			var shrink = widget.drawScale != 0 ? sx / widget.drawScale : 1.0;

			spr.cameras = line.cameras;
			spr.scrollFactor.set(0, 0);
			spr.setGraphicSize(Std.int(strum.width * shrink));
			spr.updateHitbox();
			spr.setPosition(strum.x + (strum.width - spr.width) * 0.5, strum.y + (strum.height - spr.height) * 0.5);
			spr.draw();
			spr.setPosition(px, py);
			spr.scale.set(sx, sy);
			spr.updateHitbox();
			spr.scrollFactor.set(ox, oy);
			spr.cameras = oldCams;
		}
	}

	function measureScreen() {
		var scale = FlxG.scaleMode.scale;
		var sx = scale.x > 0 ? scale.x : 1;
		var sy = scale.y > 0 ? scale.y : 1;
		pixelScale = FlxMath.bound(sx, 0.5, 4);

		if (FlxG.game == null || FlxG.stage == null || FlxG.stage.stageWidth <= 0 || FlxG.stage.stageHeight <= 0) {
			screenLeft = 0;
			screenTop = 0;
			screenWidth = FlxG.width;
			screenHeight = FlxG.height;
			return;
		}

		screenLeft = -FlxG.game.x / sx;
		screenTop = -FlxG.game.y / sy;
		screenWidth = FlxG.stage.stageWidth / sx;
		screenHeight = FlxG.stage.stageHeight / sy;
	}

	function ensureCamera() {
		if (hudCam == null || FlxG.cameras.list.indexOf(hudCam) == -1) {
			hudCam = new FlxCamera();
			hudCam.bgColor = 0;
			FlxG.cameras.add(hudCam, false);
			for (widget in widgets) widget.setCamera(hudCam);
		}

		if (FlxG.cameras.list[FlxG.cameras.list.length - 1] != hudCam) {
			FlxG.cameras.remove(hudCam, false);
			FlxG.cameras.add(hudCam, false);
		}

		hudCam.setPosition(Math.floor(screenLeft), Math.floor(screenTop));
		hudCam.setSize(Math.ceil(screenWidth), Math.ceil(screenHeight));
		hudCam.scroll.set(hudCam.x, hudCam.y);
	}

	function currentMode():TouchLayout {
		if (!Options.touchControls) return NONE;
		var state = FlxG.state;
		if (state == null) return NONE;
		if (MobileGamepad.inSong()) {
			return switch (Options.touchSongLayout) {
				case "buttons" | "arrows" | "dpad": (Options.touchSongLayout : TouchLayout);
				default: HITBOX;
			}
		}
		if (state.subState == null && (Std.isOfType(state, funkin.menus.TitleState) || Std.isOfType(state, funkin.backend.system.MainState)))
			return NONE;
		return MENU;
	}

	function rebuild(nextMode:TouchLayout, withTab:Bool) {
		for (widget in widgets) widget.destroy();
		widgets.resize(0);
		pointerActions.clear();
		stepQueue.resize(0);
		draggingId = null;
		modsTab = null;
		modsPullId = null;
		modsPullOffset = 0;
		mode = nextMode;

		var sizeID = Math.round(pixelScale * 100) + ":" + Math.round(Options.touchScale * 100) + ":" + Math.round(screenWidth) + ":" + Math.round(screenHeight);
		if (sizeID != __cache) {
			clearCache();
			__cache = sizeID;
		}

		switch (mode) {
			case HITBOX:
				for (i in 0...4) addLane(i);
				addAction("pause");
			case BUTTONS:
				for (i in 0...songButtons()) addButton(i);
				addAction("pause");
			case ARROWS | DPAD:
				for (i in 0...4) addPad(i);
				addAction("pause");
			case MENU:
				if (Options.touchMenuPad) for (i in 0...4) addPad(i);
				addAction("back");
				if (!cutsceneUp() || dialogueUp()) addAction("ok"); // confirm was covering pause
				if (cutsceneUp()) addAction("pause");
				#if MOD_SUPPORT
				if (withTab) addModsTab();
				#end
				addCustomButtons();
			default:
		}

		place(0);
	}

	function addLane(index:Int) {
		var laneWidth = screenWidth / 4;
		var width = Math.ceil(laneWidth * pixelScale), height = Math.ceil(screenHeight * pixelScale);
		var widget = new TouchWidget(NOTE_IDS[index], WidgetKind.LANE, index, cachedGraphic('lane$index', () -> laneBitmap(width, height, NOTE_COLORS[index])), pixelScale, hudCam);
		widget.w = laneWidth;
		widget.h = screenHeight;
		widgets.push(widget);
	}

	function addPad(index:Int)
		addNoteWidget(index, padSize(), 'pad$index', (size) -> padBitmap(size, index));

	function addButton(index:Int) {
		addNoteWidget(index, buttonSize(), 'button' + (index % NOTE_COLORS.length), (size) -> buttonBitmap(size, index % NOTE_COLORS.length));
		widgets[widgets.length - 1].boundKey = songNoteKey(index);
	}

	function addCustomButtons() {
		for (i => button in customButtons) {
			var gameSize = Math.round(padSize() * button.size);
			var px = Math.ceil(gameSize * pixelScale);
			var widget = new TouchWidget(button.id, WidgetKind.PAD, i, null, pixelScale, hudCam);
			widget.sprite.loadGraphic(cachedGraphic('custom' + (i % NOTE_COLORS.length) + ':' + px, () -> buttonBitmap(px, i % NOTE_COLORS.length)));
			widget.drawScale = 1 / pixelScale;
			widget.sprite.scale.set(widget.drawScale, widget.drawScale);
			widget.sprite.updateHitbox();
			widget.w = widget.sprite.width;
			widget.h = widget.sprite.height;
			widget.boundKey = button.key;
			widget.anchorX = button.x;
			widget.anchorY = button.y;
			widget.custom = true;
			if (button.label.length > 0) {
				var text = new FunkinText(0, 0, 0, button.label, Math.round(FlxMath.bound(18 * Options.touchScale * button.size, 12, 36)));
				widget.setLabel(text, hudCam);
			}
			widgets.push(widget);
		}
	}

	function addNoteWidget(index:Int, gameSize:Float, cacheKey:String, fallback:Int->BitmapData) {
		var widget = new TouchWidget(noteId(index), WidgetKind.PAD, index, null, pixelScale, hudCam);
		if (!applyNoteArrow(widget, gameSize)) {
			var size = Math.ceil(gameSize * pixelScale);
			widget.sprite.loadGraphic(cachedGraphic(cacheKey, () -> fallback(size)));
			widget.drawScale = 1 / pixelScale;
			widget.sprite.scale.set(widget.drawScale, widget.drawScale);
			widget.sprite.updateHitbox();
			widget.w = widget.sprite.width;
			widget.h = widget.sprite.height;
		}
		widgets.push(widget);
	}

	function applyNoteArrow(widget:TouchWidget, size:Float):Bool {
		var frames = noteArrowFrames();
		if (frames == null) return false;
		var dir = NOTE_IDS[widget.index % NOTE_IDS.length];
		widget.sprite.frames = frames;
		widget.sprite.animation.addByPrefix('static', 'arrow${dir.toUpperCase()}', 24, false);
		widget.sprite.animation.addByPrefix('pressed', '$dir press', 24, false);
		var idle = widget.sprite.animation.getByName('static');
		if (idle == null || idle.numFrames <= 0) return false;
		widget.sprite.animation.play('static', true);
		widget.sprite.antialiasing = true;
		if (widget.sprite.graphic != null) {
			widget.sprite.graphic.persist = true;
			widget.sprite.graphic.destroyOnNoUse = false;
		}
		widget.sprite.setGraphicSize(Std.int(size));
		widget.sprite.updateHitbox();
		widget.drawScale = widget.sprite.scale.x;
		widget.w = widget.sprite.width;
		widget.h = widget.sprite.height;
		widget.noteArrow = true;
		return true;
	}

	function noteArrowFrames():flixel.graphics.frames.FlxFramesCollection {
		if (arrowFrames != null && arrowFrames.frames != null && arrowFrames.frames.length > 0) return arrowFrames;
		try arrowFrames = Paths.getFrames('game/notes/default')
		catch (e:Dynamic) {
			arrowFrames = null;
			Logs.warn('Could not load note arrows: $e');
		}
		return arrowFrames;
	}

	function addAction(id:String) {
		var size = Math.ceil(actionSize() * pixelScale);
		widgets.push(new TouchWidget(id, WidgetKind.ACTION, 0, cachedGraphic(id, () -> actionBitmap(size, id)), pixelScale, hudCam));
	}

	function addModsTab() {
		var width = Math.ceil(tabWidth() * pixelScale), height = Math.ceil(tabHeight() * pixelScale);
		var widget = new TouchWidget("mods", WidgetKind.TAB, 0, cachedGraphic("mods", () -> tabBitmap(width, height)), pixelScale, hudCam);
		var label = new FunkinText(0, 0, 0, "MODS", Math.round(FlxMath.bound(20 * Options.touchScale, 14, 40)));
		label.angle = -90;
		widget.setLabel(label, hudCam);
		widgets.push(widget);
		modsTab = widget;
	}

	function cachedGraphic(key:String, create:Void->BitmapData):FlxGraphic {
		var graphic = graphicCache.get(key);
		if (graphic != null && graphic.bitmap != null) return graphic;
		graphic = FlxGraphic.fromBitmapData(create(), false, null, false);
		graphic.persist = true;
		graphic.destroyOnNoUse = false;
		graphicCache.set(key, graphic);
		return graphic;
	}

	function clearCache() {
		for (graphic in graphicCache) {
			graphic.persist = false;
			graphic.destroy();
		}
		graphicCache.clear();
	}

	function place(elapsed:Float) {
		if (mode == NONE) return;

		if (modsPullId == null && modsPullOffset != 0) {
			modsPullOffset *= Math.max(0, 1 - elapsed * 14);
			if (modsPullOffset < 0.5) modsPullOffset = 0;
		}

		var inset = Options.touchSafeInset;
		var right = screenLeft + screenWidth;
		var notes = mode != MENU;
		placePad(inset);

		for (widget in widgets) {
			widget.key = widget.boundKey != FlxKey.NONE ? widget.boundKey : keyFor(widget.id, notes);
			switch (widget.kind) {
				case LANE:
					widget.w = screenWidth / 4;
					widget.h = screenHeight;
					widget.setPosition(screenLeft + widget.w * widget.index, screenTop);
				case ACTION:
					if (widget.id == "back") widget.setPosition(screenLeft + inset, screenTop + inset);
					else if (widget.id == "pause" && hasAction("ok"))
						widget.setPosition(right - inset - widget.w * 2 - 18, screenTop + inset);
					else widget.setPosition(right - inset - widget.w, screenTop + inset);
				case TAB:
					widget.setPosition(screenLeft + modsPullOffset, screenTop + (screenHeight - widget.h) * 0.5);
				case PAD:
					if (widget.custom)
						widget.setPosition(screenLeft + anchor(widget.anchorX, screenWidth) - widget.w * 0.5, screenTop + anchor(widget.anchorY, screenHeight) - widget.h * 0.5);
			}
		}
	}

	function placePad(inset:Float) {
		if (mode == BUTTONS) {
			placeOnStrums();
			return;
		}
		var size = padSize();
		var gap = Math.round(size * 0.12);
		var cross = mode != ARROWS;
		var rows = cross ? 3 : 2;
		var clusterW = size * 3 + gap * 2;
		var clusterH = size * rows + gap * (rows - 1);
		var x:Float, y:Float;
		if (mode == MENU) {
			x = screenLeft + inset;
			y = screenTop + screenHeight - inset - clusterH;
		}
		else {
			x = screenLeft + Options.touchPadX * screenWidth - clusterW * 0.5;
			y = screenTop + Options.touchPadY * screenHeight - clusterH * 0.5;
		}
		x = clamp(x, screenLeft + inset, screenLeft + screenWidth - inset - clusterW);
		y = clamp(y, screenTop + inset, screenTop + screenHeight - inset - clusterH);

		for (widget in widgets) {
			if (widget.kind != WidgetKind.PAD || widget.custom) continue;
			var col = widget.index == 0 ? 0 : (widget.index == 3 ? 2 : 1);
			var row = switch (widget.index) {
				case 2: 0;
				case 1: cross ? 2 : 1;
				default: 1;
			}
			widget.setPosition(x + col * (size + gap), y + row * (size + gap));
		}
	}

	function playerStrumLine():StrumLine {
		if (PlayState.instance == null) return null;
		for (line in PlayState.instance.strumLines.members) {
			if (line != null && !line.cpu) return line;
		}
		return PlayState.instance.playerStrums;
	}

	function placeOnStrums() {
		if (PlayState.instance == null) return;
		var line = playerStrumLine();
		var cam = PlayState.instance.camHUD;
		var i = 0;
		for (widget in widgets) {
			if (widget.kind != WidgetKind.PAD) continue;
			var strum = (line != null && i < line.members.length) ? line.members[i] : null;
			i++;
			if (strum == null || cam == null) continue;

			var pos = strum.getScreenPosition(FlxPoint.weak(), cam);
			widget.sprite.setGraphicSize(Std.int(strum.width * cam.zoom));
			widget.sprite.updateHitbox();
			widget.drawScale = widget.sprite.scale.x;
			widget.w = widget.sprite.width;
			widget.h = widget.sprite.height;
			widget.setPosition(cam.width * 0.5 + (pos.x - cam.width * 0.5) * cam.zoom, cam.height * 0.5 + (pos.y - cam.height * 0.5) * cam.zoom);
		}
	}

	function noteId(index:Int):String
		return index >= 0 && index < NOTE_IDS.length ? NOTE_IDS[index] : 'note$index';

	function songButtons():Int {
		var line = playerStrumLine();
		return line != null && line.members.length > 0 ? line.members.length : 4;
	}

	function songNoteKey(index:Int):FlxKey {
		var count = songButtons();
		if (count != 4 && PlayState.instance != null && PlayState.instance.controls != null) {
			var key = keyFromAction(ControlsUtil.getControl(PlayState.instance.controls, count + "k" + index));
			if (key != FlxKey.NONE) return key;
		}
		return index >= 0 && index < NOTE_IDS.length ? keyFor(NOTE_IDS[index], true) : FlxKey.NONE;
	}

	function keyFromAction(action:FlxActionDigital):FlxKey {
		if (action == null) return FlxKey.NONE;
		for (input in action.inputs) {
			if (input == null || input.device != FlxInputDevice.KEYBOARD) continue;
			var id:FlxKey = input.inputID;
			if (id != FlxKey.NONE) return id;
		}
		return FlxKey.NONE;
	}

	inline function anchor(value:Float, span:Float):Float
		return value > 1 ? value : value * span;

	function pauseKey():FlxKey { // enter is accept too, dont use that for pause
		var accept = MobileGamepad.firstKey(Options.P1_ACCEPT, FlxKey.ENTER);
		var fallback = FlxKey.NONE;
		var keys = Options.SOLO_PAUSE;
		if (keys != null) for (key in keys) {
			if (key == FlxKey.NONE) continue;
			if (fallback == FlxKey.NONE) fallback = key;
			if (key != accept) return key;
		}
		return fallback != FlxKey.NONE ? fallback : FlxKey.ESCAPE;
	}

	function cutsceneUp():Bool {
		var state = FlxG.state;
		if (state == null || !Std.isOfType(state, funkin.game.PlayState)) return false;
		var sub = state.subState;
		if (sub == null || !Std.isOfType(sub, funkin.game.cutscenes.Cutscene)) return false;
		var top = sub;
		while (top.subState != null) top = top.subState;
		return !Std.isOfType(top, funkin.menus.PauseSubState);
	}

	function dialogueUp():Bool {
		var state = FlxG.state;
		if (state == null) return false;
		var sub = state.subState;
		while (sub != null) {
			if (Std.isOfType(sub, funkin.game.cutscenes.DialogueCutscene)) return true;
			sub = sub.subState;
		}
		return false;
	}

	function hasAction(id:String):Bool {
		for (widget in widgets) if (widget.id == id && widget.kind == WidgetKind.ACTION) return true;
		return false;
	}

	function keyFor(id:String, notes:Bool):FlxKey {
		return switch (id) {
			case "left": MobileGamepad.firstKey(notes ? Options.P1_NOTE_LEFT : Options.P1_LEFT, FlxKey.A);
			case "down": MobileGamepad.firstKey(notes ? Options.P1_NOTE_DOWN : Options.P1_DOWN, FlxKey.S);
			case "up": MobileGamepad.firstKey(notes ? Options.P1_NOTE_UP : Options.P1_UP, FlxKey.W);
			case "right": MobileGamepad.firstKey(notes ? Options.P1_NOTE_RIGHT : Options.P1_RIGHT, FlxKey.D);
			case "pause": pauseKey();
			case "ok": MobileGamepad.firstKey(Options.P1_ACCEPT, FlxKey.ENTER);
			case "back": MobileGamepad.firstKey(Options.P1_BACK, FlxKey.BACKSPACE);
			case "mods": MobileGamepad.firstKey(Options.P1_SWITCHMOD, FlxKey.TAB);
			default: FlxKey.NONE;
		}
	}

	function pollPointers() {
		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
			if (touch != null)
				handlePointer(touch.touchPointID, touch.gameX, touch.gameY, touch.justPressed, touch.pressed, touch.justReleased);
		#end

		#if (FLX_MOUSE && !mobile)
		handlePointer(-1, FlxG.mouse.gameX, FlxG.mouse.gameY, FlxG.mouse.justPressed, FlxG.mouse.pressed, FlxG.mouse.justReleased);
		#end
	}

	function handlePointer(id:Int, x:Float, y:Float, justPressed:Bool, pressed:Bool, justReleased:Bool) {
		if (justPressed && seen.exists(id)) finishPointer(id, x, y);

		var fresh = !seen.exists(id);
		if (fresh && !justPressed && !pressed && !justReleased) return;

		if (fresh) {
			seen.set(id, true);
			pointerDown(id, x, y);
		}
		if (pressed || (fresh && justReleased)) pointerHeld(id, x, y);
		if (owned.exists(id)) capture(id);
		if (justReleased) finishPointer(id, x, y);
	}

	function finishPointer(id:Int, x:Float, y:Float) {
		if (owned.exists(id)) capture(id);
		pointerUp(id, x, y);
		seen.remove(id);
		owned.remove(id);
	}

	function pointerDown(id:Int, x:Float, y:Float) {
		var action = hitKind(x, y, WidgetKind.ACTION, ACTION_PAD);
		if (action != null) {
			pointerActions.set(id, action);
			fireAction(action);
			owned.set(id, true);
			return;
		}

		if (modsTab != null && modsPullId == null) {
			var onTab = modsTab.contains(x, y, 18);
			if (onTab || x <= screenLeft + EDGE_GRAB) {
				modsPullId = id;
				modsPullStartX = x;
				modsPullStartTime = time;
				modsPullOnTab = onTab;
				owned.set(id, true);
				return;
			}
		}

		var hit = hitNote(x, y);
		if (hit != null) {
			if (hit.kind == WidgetKind.PAD && Options.touchMovePad && mode != MENU && mode != BUTTONS) {
				draggingId = id;
				dragOriginX = x;
				dragOriginY = y;
				dragPadX = Options.touchPadX;
				dragPadY = Options.touchPadY;
			}
			owned.set(id, true);
			return;
		}

		tracks.set(id, new PointerTrack(x, y, time));
	}

	function pointerHeld(id:Int, x:Float, y:Float) {
		var action = pointerActions.get(id);
		if (action != null) {
			action.wants = action.contains(x, y, 40);
			return;
		}

		if (modsPullId == id) {
			modsPullOffset = FlxMath.bound(x - modsPullStartX, 0, MODS_PULL_MAX);
			if (modsTab != null) modsTab.wants = true;
			return;
		}

		if (draggingId == id) {
			if (screenWidth > 0) Options.touchPadX = FlxMath.bound(dragPadX + (x - dragOriginX) / screenWidth, 0.05, 0.95);
			if (screenHeight > 0) Options.touchPadY = FlxMath.bound(dragPadY + (y - dragOriginY) / screenHeight, 0.05, 0.95);
			return;
		}

		var track = tracks.get(id);
		if (track != null) {
			dragTrack(id, track, x, y);
			return;
		}

		if (mode == BUTTONS) {
			pressBetween(x);
			return;
		}

		var hit = hitNote(x, y);
		if (hit != null) hit.wants = true;
	}

	function pointerUp(id:Int, x:Float, y:Float) {
		if (modsPullId == id) {
			var pulled = x - modsPullStartX;
			var tapped = modsPullOnTab && Math.abs(pulled) < 16 && time - modsPullStartTime < 0.45;
			if (pulled >= MODS_PULL_OPEN || tapped) {
				activeKeys.push(keyFor("mods", false));
				buzz();
			}
			modsPullId = null;
		}

		if (draggingId == id) {
			draggingId = null;
			Options.save();
		}

		pointerActions.remove(id);

		var track = tracks.get(id);
		if (track != null) {
			tracks.remove(id);
			finishTrack(id, track, x, y);
		}
	}

	function dragTrack(id:Int, track:PointerTrack, x:Float, y:Float) {
		var dt = time - track.lastTime;
		if (dt > 0) track.velocity = track.velocity * 0.5 + (y - track.lastY) / dt * 0.5;
		track.lastY = y;
		track.lastTime = time;

		if (mode != MENU || !Options.touchGestures) return;

		var dx = x - track.startX, dy = y - track.startY;
		if (track.axis == 0 && Math.max(Math.abs(dx), Math.abs(dy)) >= TAP_SLOP)
			track.axis = Math.abs(dy) >= Math.abs(dx) ? 1 : 2;
		if (track.axis != 1) return;

		owned.set(id, true);
		while (y - track.anchorY <= -DRAG_STEP) { // drag up moves the list down
			queueStep(keyFor("down", false));
			track.anchorY -= DRAG_STEP;
			track.steps++;
		}
		while (y - track.anchorY >= DRAG_STEP) {
			queueStep(keyFor("up", false));
			track.anchorY += DRAG_STEP;
			track.steps++;
		}
	}

	function finishTrack(id:Int, track:PointerTrack, x:Float, y:Float) {
		var dx = x - track.startX, dy = y - track.startY;
		var duration = time - track.startTime;

		if (track.axis == 0 && Math.abs(dx) < TAP_SLOP && Math.abs(dy) < TAP_SLOP) {
			if (duration < TAP_TIME) tappedTouchIDs.push(id);
			return;
		}

		if (mode != MENU || !Options.touchGestures) return;

		if (track.axis == 1 || (track.axis == 0 && Math.abs(dy) >= Math.abs(dx))) {
			var speed = Math.abs(track.velocity);
			var extra = speed > FLING_SPEED ? Std.int(Math.min(8, (speed - FLING_SPEED) / 600 + 1)) : 0;
			if (track.steps == 0 && extra == 0 && Math.abs(dy) >= 50) extra = 1;
			var upward = extra > 0 && speed > FLING_SPEED ? track.velocity < 0 : dy < 0;
			for (_ in 0...extra) queueStep(upward ? keyFor("down", false) : keyFor("up", false));
		}
		else if (Math.abs(dx) >= 110 && duration < 0.45)
			queueStep(dx < 0 ? keyFor("right", false) : keyFor("left", false));
	}

	function queueStep(key:FlxKey) {
		if (key != FlxKey.NONE && stepQueue.length < 16) stepQueue.push(key);
	}

	function pollSteps() {
		if (stepGap > 0) {
			stepGap--;
			return;
		}
		if (stepQueue.length == 0) return;
		activeKeys.push(stepQueue.shift());
		buzz();
		stepGap = 1;
	}

	function fireAction(action:TouchWidget) {
		if (time - action.lastFire < 0.15) return;
		action.lastFire = time;
		action.fire = true;
	}

	function pollMouseFallback() {
		#if (FLX_MOUSE && mobile)
		if (!FlxG.mouse.justPressed) return;
		var action = hitKind(FlxG.mouse.gameX, FlxG.mouse.gameY, WidgetKind.ACTION, ACTION_PAD);
		if (action == null) return;
		fireAction(action);
		action.wants = true;
		mouseCaptured = true;
		#end
	}

	function pollController() {
		var wasActive = MobileGamepad.active;
		MobileGamepad.poll();
		controllerActive = MobileGamepad.active;
		skipTouch = wasActive && !controllerActive;
	}

	function pollAndroidBack() {
		#if android
		if (!FlxG.android.justPressed.BACK) return;
		#if FLX_GAMEPAD
		if (controllerActive && (FlxG.gamepads.anyJustPressed(flixel.input.gamepad.FlxGamepadInputID.B) || FlxG.gamepads.anyJustPressed(flixel.input.gamepad.FlxGamepadInputID.BACK)))
			return;
		#end
		var state = FlxG.state;
		if (state != null && state.subState == null && Std.isOfType(state, funkin.menus.TitleState)) {
			if (time - lastExitBack < 2) Sys.exit(0);
			lastExitBack = time;
		}
		else if (MobileGamepad.inSong())
			activeKeys.push(keyFor("pause", true));
		else
			activeKeys.push(keyFor("back", false));
		buzz();
		#end
	}

	function commitHolds() {
		for (widget in widgets) {
			var wasHeld = widget.held;
			widget.held = widget.wants;
			switch (widget.kind) {
				case LANE:
					if (widget.held) activeKeys.push(widget.key);
					if (widget.held && !wasHeld) buzz();
				case PAD:
					if (widget.held) activeKeys.push(widget.key);
					if (widget.held && !wasHeld) buzz();
				case ACTION:
					if (widget.fire) {
						widget.fire = false;
						activeKeys.push(widget.key);
						buzz();
					}
				case TAB:
			}
		}
	}

	function applyKeys() {
		var i = heldKeys.length;
		while (i-- > 0) {
			var key = heldKeys[i];
			if (activeKeys.contains(key)) continue;
			var input = keyInput(key);
			if (input != null) input.release();
			heldKeys.splice(i, 1);
		}

		for (key in activeKeys) {
			if (key == FlxKey.NONE) continue;
			var input = keyInput(key);
			if (input == null) continue;
			if (!heldKeys.contains(key)) {
				heldKeys.push(key);
				input.press();
			}
			else if (!input.pressed)
				input.press();
		}
	}

	function suppressMouse() {
		#if (FLX_MOUSE && mobile)
		if (capturedTouchIDs.length == 0 && !mouseCaptured) return;
		@:privateAccess {
			var button = FlxG.mouse._leftButton;
			if (button != null && button.current != FlxInputState.RELEASED) {
				button.current = FlxInputState.RELEASED;
				button.last = FlxInputState.RELEASED;
			}
		}
		#end
	}

	function paint(elapsed:Float) {
		for (widget in widgets) {
			widget.glow = widget.held ? 1 : Math.max(0, widget.glow - elapsed * 7);
			widget.sprite.update(elapsed);
			var idle = widget.kind == WidgetKind.LANE ? Options.touchHitboxAlpha : (mode == BUTTONS ? 1 : Options.touchButtonAlpha);
			var pressed = Math.min(1, idle + (widget.kind == WidgetKind.LANE ? 0.45 : 0.35));
			widget.sprite.alpha = idle + (pressed - idle) * widget.glow;
			if (widget.noteArrow) {
				var anim = widget.held ? "pressed" : "static";
				if (widget.sprite.animation.name != anim) widget.sprite.animation.play(anim, true);
				widget.sprite.scale.set(widget.drawScale * (widget.held ? 0.9 : 1), widget.drawScale * (widget.held ? 0.9 : 1));
			}
			else if (widget.kind == WidgetKind.PAD || widget.kind == WidgetKind.ACTION)
				widget.sprite.scale.set(widget.drawScale * (1 - 0.08 * widget.glow), widget.drawScale * (1 - 0.08 * widget.glow));
			if (widget.label != null) widget.label.alpha = Math.max(widget.sprite.alpha, 0.85);
		}
	}

	function capture(id:Int) {
		if (id == -1) mouseCaptured = true;
		else if (!capturedTouchIDs.contains(id)) capturedTouchIDs.push(id);
	}

	function hitKind(x:Float, y:Float, kind:WidgetKind, pad:Float):TouchWidget {
		for (widget in widgets)
			if (widget.kind == kind && widget.contains(x, y, pad))
				return widget;
		return null;
	}

	function pressBetween(x:Float) { // both notes only in the middle of the gap
		var notes:Array<TouchWidget> = [];
		for (widget in widgets) {
			if (widget.kind != WidgetKind.PAD || widget.custom) continue;
			notes.push(widget);
		}
		if (notes.length == 0) return;

		notes.sort(function(a, b) return a.x < b.x ? -1 : (a.x > b.x ? 1 : 0));

		var closest = notes[0];
		var closestDist = Math.abs(x - (closest.x + closest.w * 0.5));
		for (widget in notes) {
			var dist = Math.abs(x - (widget.x + widget.w * 0.5));
			if (dist < closestDist) {
				closestDist = dist;
				closest = widget;
			}
		}
		closest.wants = true;

		for (i in 0...notes.length - 1) {
			var a = notes[i];
			var b = notes[i + 1];
			var gapL = a.x + a.w;
			var gapR = b.x;
			if (gapR <= gapL) continue;
			var mid = (gapL + gapR) * 0.5;
			var band = Math.min(36, (gapR - gapL) * 0.45);
			if (x >= mid - band * 0.5 && x <= mid + band * 0.5) {
				a.wants = true;
				b.wants = true;
			}
		}
	}

	function hitNote(x:Float, y:Float):TouchWidget {
		var best:TouchWidget = null;
		var bestDist = Math.POSITIVE_INFINITY;
		var pad = padSize() * 0.06;
		for (widget in widgets) {
			if (widget.kind != WidgetKind.LANE && widget.kind != WidgetKind.PAD) continue;

			var dist:Float;
			if (mode == BUTTONS)
				dist = Math.abs(x - (widget.x + widget.w * 0.5));
			else {
				if (!widget.contains(x, y, widget.kind == WidgetKind.PAD ? pad : 0)) continue;
				var dx = x - (widget.x + widget.w * 0.5);
				var dy = y - (widget.y + widget.h * 0.5);
				dist = dx * dx + dy * dy;
			}
			if (dist < bestDist) {
				bestDist = dist;
				best = widget;
			}
		}
		return best;
	}

	public static function vibrate() {
		if (instance != null) instance.buzz();
	}

	function buzz() {
		#if android
		if (!Options.touchHaptics || hapticBroken || time - lastBuzz < 0.08) return;
		lastBuzz = time;
		try {
			if (nativeVibrate == null)
				nativeVibrate = lime.system.JNI.createStaticMethod("com/yoshman29/codenameengine/MobileActivity", "vibrate", "(I)V");
			nativeVibrate(50);
		} catch (e:Dynamic) {
			hapticBroken = true;
			Logs.warn('Haptics unavailable: $e');
		}
		#end
	}

	inline function padSize():Float
		return Math.round(FlxMath.bound(104 * Options.touchScale, 60, 200));

	inline function buttonSize():Float {
		var lane = screenWidth / 4;
		return Math.round(FlxMath.bound(Math.min(lane * 0.78, 150 * Options.touchScale), 72, Math.max(72, lane - 12)));
	}

	inline function actionSize():Float
		return Math.round(FlxMath.bound(78 * Options.touchScale, 50, 150));

	inline function tabWidth():Float
		return Math.round(FlxMath.bound(44 * Options.touchScale, 30, 84));

	inline function tabHeight():Float
		return Math.round(FlxMath.bound(176 * Options.touchScale, 110, 330));

	function keyInput(key:FlxKey):flixel.input.FlxInput<FlxKey>
		return @:privateAccess FlxG.keys.getKey(key);

	function inMainMenu():Bool {
		var state = FlxG.state;
		return state != null && state.subState == null && Std.isOfType(state, funkin.menus.MainMenuState);
	}

	inline function clamp(value:Float, min:Float, max:Float):Float {
		if (max < min) return min;
		return FlxMath.bound(value, min, max);
	}

	static function render(shape:Shape, width:Int, height:Int):BitmapData {
		var bitmap = new BitmapData(width, height, true, 0);
		bitmap.draw(shape, null, null, null, null, true);
		return bitmap;
	}

	static function laneBitmap(width:Int, height:Int, color:Int):BitmapData {
		var shape = new Shape();
		var g = shape.graphics;
		var box = new Matrix();
		box.createGradientBox(width, height, Math.PI * 0.5, 0, 0);
		g.beginGradientFill(GradientType.LINEAR, [color, color], [0, 0.5], [110, 255], box);
		g.drawRect(0, 0, width, height);
		g.endFill();
		var border = Math.max(2, Math.round(width * 0.012));
		g.lineStyle(border, color, 0.9, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.MITER);
		g.drawRect(border * 0.5, border * 0.5, width - border, height - border);
		return render(shape, width, height);
	}

	static function circleBase(g:Graphics, size:Int) {
		var radius = size * 0.5;
		var line = Math.max(2, size * 0.045);
		g.lineStyle(line, 0xFFFFFF, 0.95);
		g.beginFill(0x000000, 0.45);
		g.drawCircle(radius, radius, radius - line);
		g.endFill();
		g.lineStyle();
	}

	static function padBitmap(size:Int, index:Int):BitmapData {
		var shape = new Shape();
		var g = shape.graphics;
		circleBase(g, size);
		drawArrow(g, size * 0.5, size * 0.5, size * 0.3, index, NOTE_COLORS[index], 0xFFFFFF, Math.max(2, size * 0.035));
		return render(shape, size, size);
	}

	static function buttonBitmap(size:Int, index:Int):BitmapData {
		var shape = new Shape();
		var g = shape.graphics;
		var radius = size * 0.5;
		var color = NOTE_COLORS[index];
		var line = Math.max(3, size * 0.055);
		g.beginFill(0x000000, 0.55);
		g.drawCircle(radius + size * 0.03, radius + size * 0.05, radius - line);
		g.endFill();
		g.lineStyle(line, 0xFFFFFF, 0.95);
		g.beginFill(color, 0.82);
		g.drawCircle(radius, radius, radius - line);
		g.endFill();
		g.lineStyle();
		g.beginFill(0xFFFFFF, 0.18);
		g.drawCircle(radius, radius - size * 0.1, radius * 0.42);
		g.endFill();
		drawArrow(g, radius, radius, size * 0.28, index, 0xFFFFFF, color, Math.max(2, size * 0.03));
		return render(shape, size, size);
	}

	static function actionBitmap(size:Int, id:String):BitmapData {
		var shape = new Shape();
		var g = shape.graphics;
		circleBase(g, size);
		var c = size * 0.5;
		var stroke = Math.max(3, size * 0.085);
		switch (id) {
			case "pause":
				var barW = size * 0.11, barH = size * 0.38, gap = size * 0.1;
				g.beginFill(0xFFFFFF, 1);
				g.drawRoundRect(c - gap * 0.5 - barW, c - barH * 0.5, barW, barH, barW * 0.7, barW * 0.7);
				g.drawRoundRect(c + gap * 0.5, c - barH * 0.5, barW, barH, barW * 0.7, barW * 0.7);
				g.endFill();
			case "ok":
				var s = size * 0.2;
				g.lineStyle(stroke, 0xFFFFFF, 1, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
				g.moveTo(c - s, c + s * 0.05);
				g.lineTo(c - s * 0.3, c + s * 0.75);
				g.lineTo(c + s * 1.05, c - s * 0.7);
			default:
				var s = size * 0.19;
				g.lineStyle(stroke, 0xFFFFFF, 1, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
				g.moveTo(c + s * 0.4, c - s);
				g.lineTo(c - s * 0.6, c);
				g.lineTo(c + s * 0.4, c + s);
		}
		return render(shape, size, size);
	}

	static function tabBitmap(width:Int, height:Int):BitmapData {
		var shape = new Shape();
		var g = shape.graphics;
		var line = Math.max(2, width * 0.06);
		var radius = width * 0.9;
		g.lineStyle(line, 0xFFFFFF, 0.9);
		g.beginFill(0x000000, 0.55);
		g.drawRoundRect(-radius, line * 0.5, width + radius - line * 0.5, height - line, radius, radius);
		g.endFill();
		var cx = width * 0.5, cy = height - width * 0.62, s = width * 0.16;
		g.lineStyle(Math.max(2, width * 0.09), 0xFFFFFF, 1, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
		g.moveTo(cx - s * 0.6, cy - s);
		g.lineTo(cx + s * 0.4, cy);
		g.lineTo(cx - s * 0.6, cy + s);
		return render(shape, width, height);
	}

	static function drawArrow(g:Graphics, cx:Float, cy:Float, scale:Float, direction:Int, fill:Int, outline:Int, outlineWidth:Float) {
		var angle = switch (direction) {
			case 0: -Math.PI * 0.5;
			case 1: Math.PI;
			case 3: Math.PI * 0.5;
			default: 0.0;
		}
		var cos = Math.cos(angle), sin = Math.sin(angle);
		g.lineStyle(outlineWidth, outline, 1, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
		g.beginFill(fill, 1);
		var i = 0;
		while (i < ARROW_SHAPE.length) {
			var px = ARROW_SHAPE[i] * scale, py = ARROW_SHAPE[i + 1] * scale;
			var rx = cx + px * cos - py * sin, ry = cy + px * sin + py * cos;
			if (i == 0) g.moveTo(rx, ry);
			else g.lineTo(rx, ry);
			i += 2;
		}
		g.lineTo(cx + ARROW_SHAPE[0] * scale * cos - ARROW_SHAPE[1] * scale * sin, cy + ARROW_SHAPE[0] * scale * sin + ARROW_SHAPE[1] * scale * cos);
		g.endFill();
		g.lineStyle();
	}
}

private class PointerTrack {
	public var startX:Float;
	public var startY:Float;
	public var startTime:Float;
	public var anchorY:Float;
	public var lastY:Float;
	public var lastTime:Float;
	public var velocity:Float = 0;
	public var axis:Int = 0;
	public var steps:Int = 0;

	public function new(x:Float, y:Float, time:Float) {
		startX = x;
		startY = y;
		startTime = time;
		anchorY = y;
		lastY = y;
		lastTime = time;
	}
}

private enum abstract TouchLayout(String) from String to String {
	var NONE = "none";
	var HITBOX = "hitbox";
	var BUTTONS = "buttons";
	var ARROWS = "arrows";
	var DPAD = "dpad";
	var MENU = "menu";
}

private enum abstract WidgetKind(Int) {
	var LANE = 0;
	var PAD = 1;
	var ACTION = 2;
	var TAB = 3;
}

private class TouchWidget {
	public var id:String;
	public var kind:WidgetKind;
	public var index:Int;
	public var sprite:FlxSprite;
	public var label:FunkinText;
	public var key:FlxKey = FlxKey.NONE;
	public var x:Float = 0;
	public var y:Float = 0;
	public var w:Float = 0;
	public var h:Float = 0;
	public var drawScale:Float = 1;
	public var held:Bool = false;
	public var wants:Bool = false;
	public var fire:Bool = false;
	public var lastFire:Float = -1;
	public var glow:Float = 0;
	public var noteArrow:Bool = false;
	public var boundKey:FlxKey = FlxKey.NONE;
	public var anchorX:Float = 0;
	public var anchorY:Float = 0;
	public var custom:Bool = false;

	public function new(id:String, kind:WidgetKind, index:Int, graphic:FlxGraphic, pixelScale:Float, camera:FlxCamera) {
		this.id = id;
		this.kind = kind;
		this.index = index;
		drawScale = 1 / pixelScale;
		sprite = new FlxSprite();
		sprite.antialiasing = true;
		sprite.moves = false;
		if (graphic != null) {
			sprite.loadGraphic(graphic);
			sprite.scale.set(drawScale, drawScale);
			sprite.updateHitbox();
			w = sprite.width;
			h = sprite.height;
		}
		setCamera(camera);
	}

	public function setLabel(text:FunkinText, camera:FlxCamera) {
		label = text;
		label.scrollFactor.set(1, 1);
		label.moves = false;
		setCamera(camera);
	}

	public function setCamera(camera:FlxCamera) {
		if (camera == null) return;
		sprite.cameras = [camera];
		if (label != null) label.cameras = [camera];
	}

	public function setPosition(px:Float, py:Float) {
		x = px;
		y = py;
		sprite.setPosition(px, py);
		if (label != null) label.setPosition(px + (w - label.width) * 0.5, py + h * 0.42 - label.height * 0.5);
	}

	public inline function contains(px:Float, py:Float, pad:Float):Bool
		return px >= x - pad && py >= y - pad && px < x + w + pad && py < y + h + pad;

	public function draw() {
		sprite.draw();
		if (label != null) label.draw();
	}

	public function destroy() {
		sprite.destroy();
		if (label != null) label.destroy();
	}
}

typedef CustomTouchButton = {
	var id:String;
	var key:FlxKey;
	var x:Float;
	var y:Float;
	var label:String;
	var size:Float;
}
