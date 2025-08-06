package funkin.editors.ui;

import funkin.editors.ui.UIContextMenu.UIContextMenuOption;

class UITopMenu extends UISliceSprite {
	var options:Array<UIContextMenuOption>;
	public function new(options:Array<UIContextMenuOption>) {
		this.options = options;
		super(0, 0, FlxG.width, 25, 'editors/ui/topmenu');
		scrollFactor.set(0, 0);

		var x:Int = 0;
		for(o in options) {
			var b = new UITopMenuButton(x, 0, this, o.label, o.childs);
			x += b.bWidth;
			members.push(b);
		}
	}

	public var anyMenuOpened:Bool = false;

	public override function update(elapsed:Float) {
		anyMenuOpened = false;
		for(c in members) {
			var c:UITopMenuButton = cast c;
			if (c.curMenu.contextMenuOpened()) {
				anyMenuOpened = true;
				break;
			}
		}

		super.update(elapsed);

		bWidth = FlxG.width;
	}
}

class UITopMenuButton extends UISliceSprite {
	public var label:UIText;
	public var contextMenu:Array<UIContextMenuOption>;
	public var parent:UITopMenu;

	public var curMenu:UIContextMenu = null;

	public function new(x:Float, y:Float, parent:UITopMenu, label:String, contextMenu:Array<UIContextMenuOption>) {
		super(x, y, 0, 23, "editors/ui/menu-item");
		this.contextMenu = contextMenu;
		this.parent = parent;
		cursor = CLICK;

		this.label = new UIText(4, 0, 0, label);
		this.label.alignment = CENTER;
		bWidth = Std.int(this.label.fieldWidth = this.label.frameWidth + 8);
		members.push(this.label);
	}

	var justClosed:Int = 0;
	var autoAnim:Bool = true;

	public override function update(elapsed:Float) {
		label.follow(this, 0, Std.int((bHeight - label.height) / 2));
		super.update(elapsed);

		if(FlxG.mouse.released) {
			if(justClosed > 0)
				justClosed -= 1;
		}

		var opened = curMenu != null ? curMenu.contextMenuOpened() : false;

		if(opened && FlxG.mouse.justPressed) {
			__rect.set(x, y, bWidth, bHeight);
			if(UIState.state.isOverlapping(this, __rect)) {
				curMenu.close();
				justClosed = 2;
				opened = false;
			}
		}

		if (!autoAnim) return;
		alpha = (hovered || opened) ? 1 : 0;
		framesOffset = opened ? 9 : 0;
	}

	public override function onHovered() {
		super.onHovered();
		if (curMenu != null && curMenu.contextMenuOpened()) {
			UIState.state.curContextMenu.preventOutOfBoxClickDeletion();
		} else {
			if (/*(parent != null && !parent.anyMenuOpened) || */FlxG.mouse.justReleased && justClosed == 0) {
				openContextMenu();
			}
		}
	}

	public function openContextMenu() {
		//if(UIState.state.curContextMenu != null) {
		//	UIState.state.curContextMenu.close();
		//}
		var screenPos = getScreenPosition(null, __lastDrawCameras[0] == null ? FlxG.camera : __lastDrawCameras[0]);
		curMenu = UIState.state.openContextMenu(contextMenu, null, screenPos.x, screenPos.y + bHeight);
	}
}

class UITopButton extends UITopMenuButton {
	public var onClick:Void->Void;

	public function new(x:Float, y:Float, name:String)
		super(x, y, null, name, null);

	public override function update(elapsed:Float) {
		justClosed = 0; autoAnim = false;
		super.update(elapsed);
	}

	public override function openContextMenu()
		if (onClick != null) onClick();
}