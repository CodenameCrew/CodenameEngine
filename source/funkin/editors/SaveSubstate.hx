package funkin.editors;

import haxe.io.Path;
import lime.ui.FileDialog;
#if lime_funkin
import lime.ui.FileDialogFilter;
#end

class SaveSubstate extends MusicBeatSubstate {
	public var saveOptions:Map<String, Bool>;
	public var options:SaveSubstateData;

	public var data:String;

	public var cam:FlxCamera;

	public function new(data:String, ?options:SaveSubstateData, ?saveOptions:Map<String, Bool>) {
		super();
		this.data = data;

		if (saveOptions == null)
			saveOptions = [];
		this.saveOptions = saveOptions;

		if (options != null)
			this.options = options;
	}

	public override function create() {
		super.create();

		#if lime_funkin
		FileDialog.saveFile(FlxG.stage.window, "Save File", (fileName:String, activeFilter:FileDialogFilter) -> {
			CoolUtil.safeSaveFile(fileName, data);
			close();
		}, [new FileDialogFilter("Specified File Extension", options.saveExt.getDefault(Path.extension(options.defaultSaveFile)))],
			options.defaultSaveFile);
		#else
		var fileDialog = new FileDialog();
		fileDialog.onCancel.add(function() close());
		fileDialog.onSelect.add(function(str) {
			CoolUtil.safeSaveFile(str, data);
			close();
		});
		fileDialog.browse(SAVE, options.saveExt.getDefault(Path.extension(options.defaultSaveFile)), options.defaultSaveFile);
		#end
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		parent.persistentUpdate = false;
	}
}

typedef SaveSubstateData = {
	var ?defaultSaveFile:String;
	var ?saveExt:String;
}