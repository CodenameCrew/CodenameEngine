package funkin.editors;

import haxe.io.Path;
import lime.ui.FileDialog;

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

		var fileDialog = new FileDialog();
		fileDialog.onCancel.add(function() close());
		fileDialog.onSelect.add(function(str) {
			CoolUtil.safeSaveFile(str, data);
			close();
		});
		fileDialog.browse(SAVE, options.saveExt.getDefault(Path.extension(options.defaultSaveFile)), options.defaultSaveFile);
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
