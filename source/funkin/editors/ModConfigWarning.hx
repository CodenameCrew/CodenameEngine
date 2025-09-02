package funkin.editors;

import funkin.backend.assets.ModsFolderLibrary;
import flixel.FlxState;

class ModConfigWarning extends UIState {
	public static var hadPopup:Bool = false;

	var library:ModsFolderLibrary = null;
	var goToState:Class<FlxState>;

	public static inline var defaultModConfigText = 
'[Common] # This section applies the \'MOD_\' prefix to the flags so you don\'t have to.
NAME="YOUR MOD NAME HERE"
DESCRIPTION="YOUR MOD DESCRIPTION HERE"
AUTHOR="YOU/YOUR TEAM HERE"
VERSION="YOUR MOD\'S VERSION HERE"

# DO NOT EDIT!! this is used to check for version compatibility!
API_VERSION=1

DOWNLOAD_LINK="YOUR MOD PAGE LINK HERE"

# Not supported yet
;MOD_ICON64="path/to/icon64"
;MOD_ICON32="path/to/icon32"
;MOD_ICON16="path/to/icon16"
# The path starts in "Your Mod/Images/", do not add an image extension, it already defaults to png.
ICON="path/to/icon"

[Flags] # This section doesn\'t apply any prefix.
DISABLE_WARNING_SCREEN=true
# Set this to false if you want to bring back the warning state (prior to 1.0.0)
# NOTE: Beta warning state has been renamed from BetaWarningState.hx to WarningState.hx
DISABLE_LANGUAGES=true
# Some people might not translate their mods, but if you do then you may set this to false

[Discord] # This section applies the \'MOD_DISCORD_\' prefix to the flags so you don\'t have to.
CLIENT_ID=""
LOGO_KEY=""
LOGO_TEXT=""

[StateRedirects] # This section is used for state redirecting, see examples below.
;StoryMenuState="funkin.menus.FreeplayState"
;FreeplayState="scriptedFreeplayState"

[StateRedirects.force] # Use this if you want to override redirects set by subsequent addons/mods
';

	public function new(library:ModsFolderLibrary, ?goToState:Class<FlxState>) {
		super();
		this.library = library;
		this.goToState = goToState != null ? goToState : funkin.menus.TitleState;
	}

	override function createPost() {
		super.createPost();
		hadPopup = true;

		var substate = new UIWarningSubstate(TU.translate("modConfigWarning.warningTitle"), TU.translate("modConfigWarning.warningDesc"), [
			{
				label: TU.translate("editor.notNow"),
				color: 0x969533,
				onClick: function (_) {
					MusicBeatState.skipTransOut = MusicBeatState.skipTransIn = false;
					FlxG.switchState(cast Type.createInstance(goToState, []));
				}
			},
			{
				label: TU.translate("editor.yes"),
				onClick: function(_) {
					var path = '${library.folderPath}/data/config/modpack.ini';
					CoolUtil.safeSaveFile(path, defaultModConfigText);
					openSubState(new UIWarningSubstate(TU.translate("modConfigWarning.createdTitle"), TU.translate("modConfigWarning.createdDesc", [path]), [
						{
							label: TU.translate("editor.ok"),
							onClick: function (_) {
								MusicBeatState.skipTransOut = MusicBeatState.skipTransIn = false;
								FlxG.switchState(cast Type.createInstance(goToState, []));
							}
						},
					], false));
				}
			}
		], false);
		openSubState(substate);
	}
}
