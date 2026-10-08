package funkin.options.categories;

import funkin.savedata.FunkinSave;

class MiscOptions extends TreeMenuScreen
{
	public function new()
	{
		super('optionsTree.miscellaneous-name', 'optionsTree.miscellaneous-desc', 'MiscOptions.');

		add(new Checkbox(getNameID('devMode'), getDescID('devMode'), 'devMode'));
		add(new Checkbox(getNameID('allowConfigWarning'), getDescID('allowConfigWarning'), 'allowConfigWarning'));

		add(new Separator());
		add(new TextOption(getNameID('resetSaveData'), getDescID('resetSaveData'), () ->
		{
			FunkinSave.save.erase();
			FunkinSave.highscores.clear();
			FunkinSave.flush();
		}));
	}
}
