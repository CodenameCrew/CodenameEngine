package funkin.editors.ui;

import lime.ui.KeyCode;
import lime.ui.KeyModifier;

class UIAutoCompleteTextBox extends UITextBox {
	public var suggestionText:UIText;

	public var suggestItems(default, set):Array<String> = [];
	var suggestIndex = 0;

	public function new(x:Float, y:Float, text:String = "", width:Int = 320, height:Int = 32, multiline:Bool = false, small:Bool = false) {
		super(x, y, text, width, height, multiline, small);

		suggestionText = new UIText(0, 0, width, "", small ? 12 : 15);
		suggestionText.color = 0xFF888888;
		suggestionText.visible = false;
		members.insert(members.indexOf(label), suggestionText);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		suggestionText.exists = selectable && focused;
		suggestionText.follow(label, 0, 0);
	}

	public override function onKeyDown(e:KeyCode, modifier:KeyModifier) {
		super.onKeyDown(e, modifier);
		switch(e) {
			//case RETURN:
			//	focused = false;
			case TAB:
				if(_suggestions.length > 0) {
					label.text = suggestionText.text;
					position = label.text.length;
					updateSuggestion(true);
				}
			case BACKSPACE:
				updateSuggestion(true);
			case UP:
				suggestIndex--;
				updateSuggestion(false);
			case DOWN:
				suggestIndex++;
				updateSuggestion(false);
			default:
				// nothing
		}
	}

	var _suggestions:Array<String> = [];

	public function updateSuggestion(refreshSuggestions:Bool = true) {
		if(refreshSuggestions) {
			var text = label.text;
			_suggestions = [];
			if(text.length > 0) {
				// for(i in suggestItems) if(i.startsWith(text)) _suggestions.pushOnce(i);
				for(i in suggestItems) if(!_suggestions.contains(i) && i.startsWith(text)) _suggestions.push(i);

				// Clean up suggestions
				if(suggestItems.contains(text)) {_suggestions = [];}
				if (_suggestions.length > 0) _suggestions.sort(function(a, b) return a.length - b.length);
			}
		}

		if(suggestionText.visible = (_suggestions.length != 0)) {
			if(suggestIndex >= _suggestions.length)
				suggestIndex = 0;
			suggestIndex = FlxMath.wrap(suggestIndex, 0, _suggestions.length - 1);

			suggestionText.text = _suggestions[suggestIndex];
		}
	}

	public override function onTextInput(text:String):Void {
		super.onTextInput(text);

		updateSuggestion();
	}

	public override function onTextEdit(text:String, start:Int, end:Int):Void {
		super.onTextEdit(text, start, end);

		updateSuggestion();
	}

	function set_suggestItems(v:Array<String>) {
		suggestItems = v;
		updateSuggestion();
		return v;
	}
}