package funkin.menus.gamejolt;

import funkin.backend.system.gamejolt.*;
import funkin.editors.ui.*;
import funkin.menus.gamejolt.*;
import funkin.menus.MainMenuState;

enum abstract DataWindowType(String) {
	var USER = 'User';
	var GLOBAL = 'Global';
}

class GameJoltDataWindow extends UISubstateWindow {
	var loadButton:UIButton;
	var saveButton:UIButton;
	var closeButton:UIButton;
	var resetButton:UIButton;

	var type:DataWindowType;

	var daX:Float;

	override public function new(type:DataWindowType)
	{
		super();
		// Prevent people from manipulating global data
		this.type = ((GameJoltSecurity.userId == GameJoltData.ownerUserId && GameJoltSecurity.userId != null) ? type : USER);
	}

	override public function create()
	{
		winTitle = '${type} Data Actions';

		winWidth = 756;

		super.create();

		daX = windowSpr.x + 20;

		// Resize window height automatically with height of unused messageSpr.
		add(messageSpr = new UIText(daX, windowSpr.y + 46, windowSpr.bWidth - ((daX - windowSpr.x) * 2), type == USER ? "User data includes base Codename Engine options (including base controls), current scores, and any other items defined by this mod's developers." : "Remember that gamejolt.xml file in data/global you used to set up the global items like leaderboards and trophy info? You can retrieve that here or overwrite the current globals here."));
		messageSpr.alignment = CENTER;
		windowSpr.resize(winWidth, Std.int(messageSpr.y + messageSpr.height + 68));

		// Load button for loading user/global data.
		add(loadButton = new UIButton(windowSpr.x + (windowSpr.bWidth / 2) - 265, windowSpr.y + windowSpr.bHeight - 48, "Load", () -> {
			if (type == USER)
				openSubState(new GameJoltConfirmationWindow('User Data Load', 'This will load, and overwrite, any user-specific data saved in this mod\'s data store to the local save.\nAre you sure you want to do this?', () -> {
					GameJoltData.loadUserData((bl) -> {
						if (bl)
							openSubState(new GameJoltInfoWindow('User Data Load Success', 'User data loaded successfully.', close));
						else
							openSubState(new GameJoltInfoWindow('User Data Load Error', 'Unable to load user data. Please check console for more information.', close));
					});
				}, false));
			else
				openSubState(new GameJoltConfirmationWindow('Global Data Load', 'This will load all global data saved in this mod\'s data store. It will then write it to this mod\'s data/config/gamejolt.xml\nAre you sure you want to do this?', () -> {
					GameJoltData.loadGlobalData((bl) -> {
						if (bl)
							openSubState(new GameJoltInfoWindow('Global Data Load Success', 'Global data loaded successfully into data/config/gamejolt.xml.', close));
						else
							openSubState(new GameJoltInfoWindow('Global Data Load Error', 'Unable to load global data. Please check console for more information.', close));
					});				
				}, false));
		}, 125));

		// Save button for writing user/global data.
		add(saveButton = new UIButton(windowSpr.x + (windowSpr.bWidth / 2) - 130, windowSpr.y + windowSpr.bHeight - 48, TU.translate("editor.save"), () -> {
			if (type == USER)
				openSubState(new GameJoltConfirmationWindow('User Data Save', 'This will save any user-specific data saved in this mod\'s data store. If a save exists for this user in the data store, it will overwrite that save.\nAre you sure you want to do this?', () -> {
					GameJoltData.setUserData((bl) -> {
						if (bl)
							openSubState(new GameJoltInfoWindow('User Data Save Success', 'User data saved successfully.', close));
						else
							openSubState(new GameJoltInfoWindow('User Data Save Error', 'Unable to save user data. Please check console for more information.', close));
					});
				}, false));
			else
				openSubState(new GameJoltConfirmationWindow('Global Data Save', 'This will transfer all global data in data/config/gamejolt.xml to this mod\'s data store. It will overwrite any previous values.\nAre you sure you want to do this?', () -> {
					GameJoltData.setGlobalData(false, (bl) -> {
						if (bl)
							openSubState(new GameJoltInfoWindow('Global Data Save Success', 'Global data saved successfully.', close));
						else
							openSubState(new GameJoltInfoWindow('Global Data Save Error', 'Unable to save global data. Please check console for more information.', close));
					});
				}, false));
		}, 125));

		// Reset button for removing user/global data.
		add(resetButton = new UIButton(windowSpr.x + (windowSpr.bWidth / 2) + 5, saveButton.y, "Remove " + (type == USER ? "User Data" : "GJ Integration"), () -> {
			if (type == USER)
				openSubState(new GameJoltConfirmationWindow('Remove User Data', '!! WARNING !!\nThis will remove ALL user data from this mod\'s data store. This is an irreversible action.\nARE YOU SURE YOU WANT TO DO THIS?', () -> {
					GameJoltData.wipeUserData((bl) -> {
						if (bl)
							openSubState(new GameJoltInfoWindow('User Data Wipe Success', 'User data wiped successfully.', close));
						else
							openSubState(new GameJoltInfoWindow('User Data Wipe Error', 'Error wiping user data.', close));
					});
				}, false));
			else
				openSubState(new GameJoltConfirmationWindow('Remove GameJolt Integration', '!! WARNING !!\nThis will remove ALL global data from your game\'s data store. You will not be able to use GameJolt integrations for this mod until you open the mod with a properly configured gamejolt.xml file in data/config.\nARE YOU SURE YOU WANT TO DO THIS?', () -> {
					GameJoltData.wipeGlobalData((bl) -> {
						if (bl)
							openSubState(new GameJoltInfoWindow('Global Data Wipe Success', 'Global data wiped successfully. This mod no longer has GameJolt integrations. Now redirecting to the Main Menu.', () -> {
								FlxG.state.closeSubState();
								FlxG.switchState(new MainMenuState());
							}));
						else
							openSubState(new GameJoltInfoWindow('Global Data Wipe Error', 'Error wiping global data.', close));
					});
				}, false));
		}, 125));
		resetButton.color = 0xFFFF0000;
		
		// The humble "close window" button.
		add(closeButton = new UIButton(windowSpr.x + (windowSpr.bWidth / 2) + 140, windowSpr.y + windowSpr.bHeight - 48, TU.translate("editor.close"), close, 125));
		closeButton.color = 0xFFFF0000;
	}
}