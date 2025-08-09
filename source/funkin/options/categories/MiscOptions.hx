package funkin.options.categories;

import funkin.savedata.FunkinSave;

class MiscOptions extends TreeMenuScreen {
	public function new() {
		super('optionsTree.miscellaneous-name', 'optionsTree.miscellaneous-desc', 'MiscOptions.');

		add(new Checkbox(getNameID('devMode'), getDescID('devMode'), 'devMode'));
		add(new Checkbox(getNameID('allowConfigWarning'), getDescID('allowConfigWarning'), 'allowConfigWarning'));
		#if UPDATE_CHECKING
		add(new Checkbox(getNameID('betaUpdates'), getDescID('betaUpdates'), 'betaUpdates'));
		add(new TextOption(getNameID('checkForUpdates'), getDescID('checkForUpdates'), () -> {
			var report = funkin.backend.system.updating.UpdateUtil.checkForUpdates(true);
			if (report.newUpdate) FlxG.switchState(new funkin.backend.system.updating.UpdateAvailableScreen(report));
			else {
				CoolUtil.playMenuSFX(CANCEL);
				//updateDescText(translate('checkForUpdates-noUpdateFound'));
			}
		}));
		#end

		add(new Separator());
		add(new TextOption(getNameID('resetSaveData'), getDescID('resetSaveData'), () -> {
			FunkinSave.save.erase();
			FunkinSave.highscores.clear();
			FunkinSave.flush();
		}));
	}
}