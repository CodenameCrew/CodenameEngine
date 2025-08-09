package funkin.editors.stage;

import funkin.editors.stage.StageCreationScreen.StageCreationData;
import funkin.editors.EditorTreeMenu;
import funkin.game.Stage;
import funkin.options.type.NewOption;
import funkin.options.type.OptionType;
import funkin.options.type.TextOption;

using StringTools;

class StageSelection extends EditorTreeMenu {
	override function create() {
		super.create();
		DiscordUtil.call("onEditorTreeLoaded", ["Stage Editor"]);
		addMenu(new StageSelectionScreen());
	}
}

class StageSelectionScreen extends EditorTreeMenuScreen {
	public var stages:Array<String> = [];

	public function makeStageOption(stage:String):TextOption {
		return new TextOption(stage, getID('acceptStage'), () -> {
			FlxG.switchState(new StageEditor(stage));
		});
	}

	public function new() {
		super('editor.stage.name', 'stageSelection.desc', 'stageSelection.', 'newStage', 'acceptNewStage', () -> {
			parent.openSubState(new StageCreationScreen(saveStage));
		});

		var modsList:Array<String> = Stage.getList(true, true);
		for (stage in (modsList.length == 0 ? Stage.getList(false, true) : modsList)) {
			stages.push(stage.toLowerCase());
			add(makeStageOption(stage));
		}
	}

	public function saveStage(creation:StageCreationData) {
		if (stages.contains(creation.name.toLowerCase())) {
			parent.openSubState(new UIWarningSubstate(TU.translate("stageCreationScreen.warnings.stage-exists-title"), TU.translate("stageCreationScreen.warnings.stage-exists-body"), [
				{label: TU.translate("editor.ok"), color: 0xFFFF0000, onClick: (t) -> {}},
			]));
			return;
		}

		#if sys
		// Save File
		CoolUtil.safeSaveFile('${Paths.getAssetsRoot()}/data/stages/${creation.name}.xml', '<!DOCTYPE codename-engine-stage>\n<stage folder="${creation.path}">\n</stage>');
		#end

		// Add to List
		stages.push(creation.name.toLowerCase());
		parent.tree.last().insert(parent.tree.last().length - 1, makeStageOption(creation.name));
	}
}