package funkin.options.categories;

class LanguageRadio extends RadioButton {
	public var langID:String;

	public function new(screen:TreeMenuScreen, name:String, langID:String) {
		this.langID = langID;
		super(screen, name, "LanguageOptions.language-desc", null, langID, null, "languageSelector");

		checked = langID == TU.curLanguage;
	}

	override function set_rawDesc(v:String) {
		rawDesc = v;
		var config = TU.getConfig(langID);
		this.desc = TU.exists(rawDesc) ? TU.translate(
			rawDesc, [config["credits"], config["version"]]
		) : rawDesc;
		return v;
	}

	override function select() {
		var prev = checked;
		super.select();
		if (prev == checked) return;

		TranslationUtil.setLanguage(value);
		if (screen.parent == null) screen.reloadStrings();
		else screen.parent.reloadStrings();
	}
}

class LanguageOptions extends TreeMenuScreen {
	public override function new() {
		super('optionsTree.language-name', 'optionsTree.language-desc', 'LanguageOptions.');

		for (lang in TranslationUtil.foundLanguages) {
			var split = lang.split("/");
			var langId = split.first(), langName = split.last();
			add(new LanguageRadio(this, langName, langId));
		}
	}
}