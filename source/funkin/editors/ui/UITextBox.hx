package funkin.editors.ui;

import flixel.math.FlxPoint;
import lime.ui.KeyModifier;
import lime.ui.KeyCode;
import openfl.desktop.Clipboard;
import openfl.geom.Rectangle;

class UITextBox extends UISliceSprite implements IUIFocusable {
	public var label:UIText;

	public var position:Int = 0;
	public var multiline:Bool = false;
	public var caretSpr:FlxSprite;

	public var onChange:String->Void;

	var __wasFocused:Bool = false;

	public function new(x:Float, y:Float, text:String = "", width:Int = 320, height:Int = 32, multiline:Bool = false) {
		super(x, y, width, height, 'editors/ui/inputbox');

		label = new UIText(0, 0, width, text);
		members.push(label);

		caretSpr = new FlxSprite(0, 0);
		caretSpr.makeGraphic(1, 1, -1);
		caretSpr.scale.set(1, label.size);
		caretSpr.updateHitbox();
		members.push(caretSpr);
		this.multiline = multiline;
		position = text.length;

		cursor = IBEAM;
	}

	var cacheRect:Rectangle = new Rectangle();

	public override function update(elapsed:Float) {
		if (selectable && hovered && FlxG.mouse.justReleased && __lastDrawCameras.length > 0) {
			// get caret pos
			var pos = FlxG.mouse.getScreenPosition(__lastDrawCameras[0], FlxPoint.get());
			pos.x -= label.x;
			pos.y -= label.y;

			if (pos.x < 0)
				position = 0;
			else {
				var index = label.textField.getCharIndexAtPoint(pos.x, pos.y);
				if (index > -1)
					position = index;
				else
					position = label.text.length;
			}

			pos.put();
		}

		super.update(elapsed);

		var selected = selectable && focused;
		if (autoAlpha) {
			if(selectable) {
				alpha = label.alpha = 1;
			} else {
				alpha = label.alpha = 0.4;
			}
		}

		var off = multiline ? 4 : ((bHeight - label.height) / 2);
		label.follow(this, label.autoSize ? (bWidth-label.textField.width)/2 : 4, off);
		framesOffset = (selected ? 18 : (hovered ? 9 : 0));
		@:privateAccess {
			if (selected) {
				__wasFocused = true;
				caretSpr.alpha = (FlxG.game.ticks % 666) >= 333 ? 1 : 0;

				var curPos = switch(position) {
					case 0:
						FlxPoint.get(0, 0);
					default:
						if (position >= label.text.length) {
							label.textField.__getCharBoundaries(label.text.length-1, cacheRect);
							FlxPoint.get(cacheRect.x + cacheRect.width, cacheRect.y);
						} else {
							label.textField.__getCharBoundaries(position, cacheRect);
							FlxPoint.get(cacheRect.x, cacheRect.y);
						}
				};
				caretSpr.follow(this, 4 + curPos.x, off + curPos.y);
				curPos.put();
			} else {
				if (__wasFocused) {
					__wasFocused = false;
					if (onChange != null)
						onChange(label.text);
				}
				caretSpr.alpha = 0;
			}
		}
	}

	public function onKeyDown(e:KeyCode, modifier:KeyModifier) {
		switch(e) {
			case RETURN:
				focused = false;
				if (onChange != null) onChange(label.text);
			case LEFT:
				changeSelection(-1);
			case RIGHT:
				changeSelection(1);
			case BACKSPACE:
				if (position > 0) {
					label.text = label.text.substr(0, position-1) + label.text.substr(position);
					changeSelection(-1);
				}
			case HOME:
				position = 0;
			case END:
				position = label.text.length;
			case V:
				// Hey lj here, fixed copying because before we checked if the modifier was left or right ctrl
				// but somehow it gave a int outside of the KeyModifier's range :sob:
				// apparently there is a boolean that just checks for you. yw :D

				// if we are not holding ctrl, ignore
				if (!modifier.ctrlKey) return;
				// we pasting
				var data:String = Clipboard.generalClipboard.getData(TEXT_FORMAT);
				if (data != null) onTextInput(data);
			case C:
				// if we are not holding ctrl, ignore
				if (!modifier.ctrlKey) return;

				// copying
				Clipboard.generalClipboard.setData(TEXT_FORMAT, label.text);
			default:
				// nothing
		}
	}

	public function changeSelection(change:Int) {
		position = FlxMath.wrap(position + change, 0, label.text.length);
	}
	public function onKeyUp(e:KeyCode, modifier:KeyModifier) {}

	public function onTextInput(text:String):Void {
		label.text = label.text.substr(0, position) + text + label.text.substr(position);
		position += text.length;
	}
	// untested, but this should be a fix for if the text wont type
	public function onTextEdit(text:String, start:Int, end:Int):Void {
		label.text = label.text.substr(0, position) + text + label.text.substr(position);
		position += text.length;
	}
}