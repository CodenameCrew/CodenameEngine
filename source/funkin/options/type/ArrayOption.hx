package funkin.options.type;

class ArrayOption extends TextOption {
	public var changedCallback:String->Void;

	public var options:Array<Dynamic>;
	public var displayOptions:Array<String>;
	public var currentSelection:Int;

	public var parent:Dynamic;
	public var optionName:String;

	var __selectionText:Alphabet;

	override function set_text(v:String) {
		super.set_text(v);
		__selectionText.x = __text.x + __text.width + 12;
		return v;
	}

	public function new(text:String, desc:String, options:Array<Dynamic>, displayOptions:Array<String>, ?optionName:String, ?changedCallback:Dynamic->Void = null, ?parent:Dynamic) {
		this.changedCallback = changedCallback;
		this.displayOptions = displayOptions;
		this.options = options;
		this.optionName = optionName;
		this.parent = parent = parent != null ? parent : Options;

		var fieldValue = Reflect.field(parent, optionName);
		if (fieldValue != null) currentSelection = CoolUtil.maxInt(0, options.indexOf(fieldValue));
	
		__selectionText = new Alphabet(0, 20, formatTextOption(), 'bold');
		super(text, desc);
		add(__selectionText);
	}

	override function reloadStrings() {
		__selectionText.text = formatTextOption();
		super.reloadStrings();
	}

	function formatTextOption() {
		var s = ": ";

		if (currentSelection > 0) s += "< ";
		else s += "  ";

		s += TU.exists(displayOptions[currentSelection]) ? TU.translate(displayOptions[currentSelection]) : displayOptions[currentSelection];

		if (currentSelection < options.length - 1) s += " >";

		return s;
	}

	override function changeSelection(change:Int) {
		if (locked || currentSelection == (currentSelection = CoolUtil.boundInt(currentSelection + change, 0, options.length - 1))) return;
		__selectionText.text = formatTextOption();
		CoolUtil.playMenuSFX(SCROLL);

		if (optionName != null) Reflect.setField(parent, optionName, options[currentSelection]);
		if (changedCallback != null) changedCallback(options[currentSelection]);
	}

	override function select() {}
}