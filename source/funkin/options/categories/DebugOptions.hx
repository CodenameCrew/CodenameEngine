package funkin.options.categories;

class DebugOptions extends TreeMenuScreen {
	public function new() {
		super('DebugOptions.title', 'DebugOptions.desc', 'DebugOptions.');

		#if windows
		add(new TextOption(getNameID("showConsole"), getDescID("showConsole"), () -> funkin.backend.utils.NativeAPI.allocConsole()));
		#end
		add(new Checkbox(getNameID("editorsResizable"), getDescID("editorsResizable"), "editorsResizable"));
		add(new Checkbox(getNameID("bypassEditorsResize"), getDescID("bypassEditorsResize"), "bypassEditorsResize"));
		add(new Checkbox(getNameID("editorSFX"), getDescID("editorSFX"), "editorSFX"));
		add(new Checkbox(getNameID("editorCharterPrettyPrint"), getDescID("editorCharterPrettyPrint"), "editorCharterPrettyPrint"));
		add(new Checkbox(getNameID("editorCharacterPrettyPrint"), getDescID("editorCharacterPrettyPrint"), "editorCharacterPrettyPrint"));
		add(new Checkbox(getNameID("editorStagePrettyPrint"), getDescID("editorStagePrettyPrint"), "editorStagePrettyPrint"));
		add(new Checkbox(getNameID("intensiveBlur"), getDescID("intensiveBlur"), "intensiveBlur"));
		add(new Checkbox(getNameID("charterAutoSaves"), getDescID("charterAutoSaves"), "charterAutoSaves"));
		add(new NumOption(getNameID("charterAutoSaveTime"), getDescID("charterAutoSaveTime"), 60, 60*10, 1, "charterAutoSaveTime"));
		add(new NumOption(getNameID("charterAutoSaveWarningTime"), getDescID("charterAutoSaveWarningTime"), 0, 15, 1, "charterAutoSaveWarningTime"));
		add(new Checkbox(getNameID("charterAutoSavesSeparateFolder"), getDescID("charterAutoSavesSeparateFolder"), "charterAutoSavesSeparateFolder"));
		add(new Checkbox(getNameID("songOffsetAffectEditors"), getDescID("songOffsetAffectEditors"), "songOffsetAffectEditors"));
	}
}