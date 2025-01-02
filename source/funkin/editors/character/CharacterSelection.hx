package funkin.editors.character;

import funkin.options.type.OptionType;
import funkin.options.type.NewOption;
import flixel.util.FlxColor;
import funkin.game.Character;
import funkin.backend.chart.Chart;
import funkin.options.type.TextOption;
import funkin.options.type.IconOption;
import funkin.options.OptionsScreen;

class CharacterSelection extends EditorTreeMenu
{
	public override function create()
	{
		bgType = "charter";
		super.create();

		var modsList:Array<String> = Character.getList(true);

		final button:String = controls.touchC ? 'A' : 'ACCEPT';

		var list:Array<OptionType> = [
			for (char in (modsList.length == 0 ? Character.getList(false) : modsList))
				new IconOption(char, "Press " + button + " to edit this character.", Character.getIconFromCharName(char),
			 	function() {
					#if TOUCH_CONTROLS
					if (funkin.backend.system.Controls.instance.touchC)
					{
						openSubState(new UIWarningSubstate("CharacterEditor: Touch Not Supported!", "Please connect a keyboard and mouse to access this editor.", [
							{label: "Ok", color: 0xFFFF0000, onClick: function(t) {}}
						]));
					} else
					#end
					FlxG.switchState(new CharacterEditor(char));
				})
		];

		list.insert(0, new NewOption("New Character", "New Character", function() {
			openSubState(new UIWarningSubstate("New Character: Feature Not Implemented!", "This feature isn't implemented yet. Please wait for more cne updates to have this functional.\n\n\n- Codename Devs", [
				{label: "Ok", color: 0xFFFF0000, onClick: function(t) {}}
			]));
		}));

		main = new OptionsScreen("Character Editor", "Select a character to edit", list, 'UP_DOWN', 'A_B');

		DiscordUtil.call("onEditorTreeLoaded", ["Character Editor"]);
	}

	override function createPost() {
		super.createPost();

		main.changeSelection(1);
	}
}