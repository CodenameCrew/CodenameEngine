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

	public var childContextMenu:UIContextMenu = null;
	public var parentContextMenu:UIContextMenu = null;
	private var childContextMenuOptionIndex:Int = -1;
	@:allow(funkin.editors.ui.UIContextMenu)
	private var lastHoveredOptionIndex:Int = -1;

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

		for(o in contextMenuOptions) {
			o.postCreate();
		}
	}

	public function select(option:UIContextMenuOption) {
		var index = options.indexOf(option);
		if (option.onSelect != null)
			option.onSelect(option);
		if (callback != null)
			callback(this, index, option);
		if (option.closeOnSelect == null ? true : option.closeOnSelect)
			closeWithParents();
	}

	public override function update(elapsed:Float) {
		if (__oobDeletion && FlxG.mouse.justPressed && !bg.hoveredByChild && !hoveringAnyChildren())
			closeWithParents();

		__oobDeletion = true;

		super.update(elapsed);

		if (FlxG.mouse.wheel != 0.0)
			scroll = FlxMath.bound(scroll + (FlxG.mouse.wheel * -20.0), !flipped ? 0.0 : -Math.max(bg.bHeight - FlxG.height*0.5, 0.0), flipped ? 0.0 : Math.max(bg.bHeight - FlxG.height*0.5, 0.0));

		contextCam.scroll.y = CoolUtil.fpsLerp(contextCam.scroll.y, scroll, 0.5);
		contextCam.alpha = CoolUtil.fpsLerp(contextCam.alpha, 1, 0.25);

		if (parentContextMenu != null) {
			if (hoveringAnyParents() && parentContextMenu.lastHoveredOptionIndex != parentContextMenu.childContextMenuOptionIndex) {
				closeWithChildren();
				parentContextMenu.childContextMenuOptionIndex = -1;
			}
		}

	}

	public override function destroy() {
		super.destroy();
		FlxG.cameras.remove(contextCam);
		if (UIState.state.curContextMenu == this)
			UIState.state.curContextMenu = null;
	}

	public function openChildContextMenu(optionSpr:UIContextMenuOptionSpr) {
		var index = contextMenuOptions.indexOf(optionSpr);
		if (index != childContextMenuOptionIndex) {
			childContextMenuOptionIndex = index;
			var child = new UIContextMenu(optionSpr.option.childs, null, optionSpr.x + optionSpr.bWidth, optionSpr.y);
			persistentDraw = true;
			persistentUpdate = true;
			child.parentContextMenu = this;
			childContextMenu = child;
			openSubState(child);
		}
	}
	public function closeWithParents() {
		close();
		if (parentContextMenu != null) {
			parentContextMenu.closeWithParents();
		}
	}
	public function closeWithChildren() {
		if (childContextMenu != null) {
			childContextMenu.closeWithChildren();
		}
		close();
	}
	public function hoveringAnyParents() {
		if (parentContextMenu != null) {
			return parentContextMenu.bg.hoveredByChild || parentContextMenu.hoveringAnyParents();
		}
		return false;
	}
	public function hoveringAnyChildren() {
		if (childContextMenu != null) {
			return childContextMenu.bg.hoveredByChild || childContextMenu.hoveringAnyChildren();
		}
		return false;
	}
}

typedef UIContextMenuSliderOptionData = {
	var min:Float;
	var max:Float;
	var value:Float;
	var ?width:Float;
	var ?onChange:UIContextMenuOption->Void;
	var ?showValues:Bool;
	var ?sameLine:Bool;
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
	var ?slider:UIContextMenuSliderOptionData;
}

enum abstract UIContextMenuOptionType(Int) from Int {
	var DEFAULT = 0;
	var SUBMENU = 1;
	var SLIDER = 2;
}

class UIContextMenuOptionSpr extends UISliceSprite {
	public var label:UIText;
	public var labelKeybind:UIText;
	public var icon:FlxSprite;
	public var option:UIContextMenuOption;
	public var optionType:UIContextMenuOptionType = DEFAULT;
	
	public var slider:UISlider = null;

	var parent:UIContextMenu;

	private var _lastIcon:Int = 0;

	public function new(x:Float, y:Float, option:UIContextMenuOption, parent:UIContextMenu) {
		label = new UIText(20, 2, 0, option.label);
		this.option = option;
		this.parent = parent;
		this.color = option.color;

		var w:Int = label.frameWidth + 22;
		var h:Int = label.frameHeight;

		if (option.childs != null) optionType = SUBMENU;
		if (option.slider != null) optionType = SLIDER;

		switch(optionType) {

			case SUBMENU:
				labelKeybind = new UIText(label.x + label.frameWidth + 10, 2, 0, ">");
			case SLIDER:
				labelKeybind = new UIText(label.x + label.frameWidth + 10, 2, 0, "");
				//slider needs to be created after so that it can match the menu width (when not on the same line)
				if (option.slider.sameLine != null && option.slider.sameLine) {
					var sliderWidth = option.slider.width != null ? Std.int(option.slider.width) : 120;
					w += 120 + slider.barWidth;
				} else {
					h *= 2;	
				}
				
			default:
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

					w = Std.int(labelKeybind.x + labelKeybind.frameWidth + 10);
				}
		}

		super(x, y, w, h, 'editors/ui/menu-item');

		members.push(label);
		updateIcon();

		if (labelKeybind != null)
			members.push(labelKeybind);			
	}

	//Called after all options are created and the context menu width/height is final
	public function postCreate() {
		switch(optionType) {
			case SLIDER:

				var sliderWidth = bWidth-50;
				if (option.slider.sameLine != null && option.slider.sameLine) {
					option.slider.width != null ? Std.int(option.slider.width) : 120;
				}

				slider = new UISlider(0, 0, sliderWidth, option.slider.value, 
					[{start: option.slider.min, end: option.slider.max, size: option.slider.max-option.slider.min}], false);

				slider.onChange = function(v) {
					option.slider.value = v;
					if (option.slider.onChange != null) option.slider.onChange(option);
					updateIcon(); //check if icon has changed
					@:privateAccess
					labelKeybind.text = '${CoolUtil.quantize(slider.__barProgress * 100, 1)}%';
				};
				slider.value = option.slider.value;

				if (option.slider.showValues == null || !option.slider.showValues) {
					slider.startText.visible = false;
					slider.endText.visible = false;
					slider.valueStepper.visible = false;
					slider.valueStepper.selectable = false;
				}

				members.push(slider);
			case SUBMENU:

			default:

		}
	}

	public override function draw() {
		alpha = option.color == null ? (hovered ? 1 : 0) : 1;
		if (option.color != null) color = hovered ? option.color.getLightened(.4) : option.color;

		label.follow(this, 20, 2);
		if (icon != null)
			icon.follow(this, 0, 0);
		if (labelKeybind != null)
			labelKeybind.follow(this, bWidth - 10 - labelKeybind.frameWidth, 2);
		if (slider != null) {
			if (option.slider.sameLine != null && option.slider.sameLine) {
				slider.follow(this, bWidth - 18 - slider.barWidth - (slider.endText.visible ? slider.endText.width : 0), 5);
			} else {
				slider.follow(this, 20, 5 + label.frameHeight);
			}
		}
		super.draw();
	}

	public override function onHovered() {
		super.onHovered();

		parent.lastHoveredOptionIndex = parent.contextMenuOptions.indexOf(this);

		switch(optionType) {
			case SUBMENU:
				parent.openChildContextMenu(this);
			case SLIDER:
				
			default:
				if (FlxG.mouse.justReleased)
					parent.select(option);
		}
	}

	public function updateIcon() {
		var currentIcon = option.icon != null ? option.icon : 0;

		if (_lastIcon != currentIcon) {
			_lastIcon = currentIcon;
			if (icon == null) {
				icon = new FlxSprite(0, 0).loadGraphic(Paths.image('editors/ui/context-icons'), true, 20, 20);
				members.push(icon);
			}
			icon.visible = currentIcon > 0;

			if (currentIcon > 0) {
				icon.animation.add('icon', [currentIcon-1], 0, true);
				icon.animation.play('icon');
			}
		}
	}
}