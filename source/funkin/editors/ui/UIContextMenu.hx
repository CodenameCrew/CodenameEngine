package funkin.editors.ui;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxColor;

class UIContextMenu extends MusicBeatSubstate {
	public var options:Array<UIContextMenuOption>;
	var x:Float;
	var y:Float;
	var w:Int = 100;
	var contextCam:FlxCamera;

	var bg:UISliceSprite;
	var callback:UIContextMenuCallback;

	public var contextMenuOptions:Array<UIContextMenuOptionSpr> = [];
	public var separators:Array<FlxSprite> = [];

	var scroll:Float = 0.0;
	var flipped:Bool = false;

	private var __oobDeletion:Bool = true;

	public inline function preventOutOfBoxClickDeletion() {
		__oobDeletion = false;
	}

	public function new(options:Array<UIContextMenuOption>, callback:UIContextMenuCallback, x:Float, y:Float, ?w:Int = 100) {
		super();
		this.options = options.getDefault([]);
		this.x = x;
		this.y = y;
		this.w = w;
		this.callback = callback;
	}

	public override function create() {
		super.create();
		camera = contextCam = new FlxCamera();
		contextCam.bgColor = 0;
		contextCam.alpha = 0;
		contextCam.scroll.set(0, 7.5);
		FlxG.cameras.add(contextCam, false);

		bg = new UISliceSprite(x, y, w, 100, 'editors/ui/context-bg');
		bg.cameras = [contextCam];
		add(bg);

		var lastY:Float = bg.y + 4;
		for(o in options) {
			if (o == null) {
				var spr = new FlxSprite(bg.x + 8, lastY + 2).makeGraphic(1, 1, -1);
				spr.alpha = 0.3;
				separators.push(spr);
				add(spr);
				lastY += 5;
				continue;
			}
			var spr = new UIContextMenuOptionSpr(bg.x + 4, lastY, o, this);
			spr.cameras = [contextCam];
			lastY = spr.y + spr.bHeight;
			contextMenuOptions.push(spr);
			add(spr);

			o.button = spr;
			if (o.onCreate != null) o.onCreate(spr);
		}

		var maxW = bg.bWidth - 8;
		for(o in contextMenuOptions)
			if (o.bWidth > maxW)
				maxW = o.bWidth;

		for(o in contextMenuOptions)
			o.bWidth = maxW;
		for(o in separators) {
			o.scale.set(maxW - 8, 1);
			o.updateHitbox();
		}
		bg.bWidth = maxW + 8;
		bg.bHeight = Std.int(lastY - bg.y + 4);

		if (bg.y + bg.bHeight > FlxG.height && bg.y > FlxG.height*0.5) {
			flipped = true;
			bg.y -= bg.bHeight;
			for(o in contextMenuOptions)
				o.y -= bg.bHeight;
			for(o in separators)
				o.y -= bg.bHeight;
		}

		if (bg.x + bg.bWidth > FlxG.width && bg.x > FlxG.width*0.5) {
			bg.x -= bg.bWidth;
			for(o in contextMenuOptions)
				o.x -= bg.bWidth;
			for(o in separators)
				o.x -= bg.bWidth;
		}
	}

	public function select(option:UIContextMenuOption) {
		var index = options.indexOf(option);
		if (option.onSelect != null)
			option.onSelect(option);
		if (callback != null)
			callback(this, index, option);
		if (option.closeOnSelect == null ? true : option.closeOnSelect)
			close();
	}

	public override function update(elapsed:Float) {
		if (__oobDeletion && FlxG.mouse.justPressed && !bg.hoveredByChild)
			close();

		__oobDeletion = true;

		super.update(elapsed);

		if (FlxG.mouse.wheel != 0.0)
			scroll = FlxMath.bound(scroll + (FlxG.mouse.wheel * -20.0), !flipped ? 0.0 : -Math.max(bg.bHeight - FlxG.height*0.5, 0.0), flipped ? 0.0 : Math.max(bg.bHeight - FlxG.height*0.5, 0.0));

		contextCam.scroll.y = CoolUtil.fpsLerp(contextCam.scroll.y, scroll, 0.5);
		contextCam.alpha = CoolUtil.fpsLerp(contextCam.alpha, 1, 0.25);
	}

	public override function destroy() {
		super.destroy();
		FlxG.cameras.remove(contextCam);
		if (UIState.state.curContextMenu == this)
			UIState.state.curContextMenu = null;
	}
}

typedef UIContextMenuCallback = UIContextMenu->Int->UIContextMenuOption->Void;
typedef UIContextMenuOption = {
	var label:String;
	var ?keybind:Array<FlxKey>;
	var ?keybinds:Array<Array<FlxKey>>;
	var ?keybindText:String;
	var ?closeOnSelect:Bool;
	var ?color:FlxColor;
	var ?icon:Int;
	var ?onSelect:UIContextMenuOption->Void;
	var ?button:UIContextMenuOptionSpr;
	var ?onCreate:UIContextMenuOptionSpr->Void;
	var ?childs:Array<UIContextMenuOption>;
}

class UIContextMenuOptionSpr extends UISliceSprite {
	public var label:UIText;
	public var labelKeybind:UIText;
	public var icon:FlxSprite;
	public var option:UIContextMenuOption;

	var parent:UIContextMenu;

	public function new(x:Float, y:Float, option:UIContextMenuOption, parent:UIContextMenu) {
		label = new UIText(20, 2, 0, option.label);
		label.updateHitbox();
		label.frameHeight += 4;
		this.option = option;
		this.parent = parent;
		this.color = option.color;

		if (option.icon != null && option.icon > 0) {
			icon = new FlxSprite(0, 0).loadGraphic(Paths.image('editors/ui/context-icons'), true, 20, 20);
			icon.animation.add('icon', [option.icon-1], 0, true);
			icon.animation.play('icon');
		}

		if (option.keybinds == null) {
			if (option.keybind != null) {
				option.keybinds = [option.keybind];
			}
		}

		if (option.keybinds != null || option.keybindText != null) {
			var text = if(option.keybindText == null) {
				var textKeys:Array<String> = [];
				for (o in option.keybinds[0]) {
					if (Std.int(o) > 0) {
						textKeys.push(o.toUIString());
					}
				}
				textKeys.join("+");
			} else {
				option.keybindText;
			}
			labelKeybind = new UIText(label.x + label.frameWidth + 10, 2, 0, text);
			labelKeybind.alpha = 0.75;
		}

		super(x, y, labelKeybind != null ? Std.int(labelKeybind.x + labelKeybind.frameWidth + 10) : (label.frameWidth + 22), label.frameHeight, 'editors/ui/menu-item');
		members.push(label);
		if (icon != null)
			members.push(icon);
		if (labelKeybind != null)
			members.push(labelKeybind);
	}

	public override function draw() {
		alpha = option.color == null ? (hovered ? 1 : 0) : 1;
		if (option.color != null) color = hovered ? option.color.getLightened(.4) : option.color;

		label.follow(this, 20, 2);
		if (icon != null)
			icon.follow(this, 0, 0);
		if (labelKeybind != null)
			labelKeybind.follow(this, bWidth - 10 - labelKeybind.frameWidth, 2);
		super.draw();
	}

	public override function onHovered() {
		super.onHovered();
		if (FlxG.mouse.justReleased)
			parent.select(option);
	}
}