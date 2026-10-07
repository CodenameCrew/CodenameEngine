import funkin.backend.utils.DiscordUtil;
import funkin.backend.utils.TranslationUtil;

function onGameOver() {
	DiscordUtil.changePresence(TranslationUtil.translate('rpc.gameOver'), TranslationUtil.translate('rpc.song', [PlayState.SONG.meta.displayName, PlayState.difficulty]));
}

function onDiscordPresenceUpdate(e) {
	var data = e.presence;

	if(data.button1Label == null)
		data.button1Label = TranslationUtil.translate('rpc.discordButton');
	if(data.button1Url == null)
		data.button1Url = "https://discord.gg/codename-crew";
}

function onPlayStateUpdate() {
	DiscordUtil.changeSongPresence(
		PlayState.instance.detailsText,
		TranslationUtil.translate(PlayState.instance.paused ? 'rpc.song-paused' : 'rpc.song', [PlayState.SONG.meta.displayName, PlayState.difficulty]),
		PlayState.instance.inst,
		PlayState.instance.getIconRPC()
	);
}

function onMenuLoaded(name:String) {
	// Name is either "Main Menu", "Freeplay", "Title Screen", "Options Menu", "Credits Menu", "Beta Warning", "Update Available Screen", "Update Screen"
	DiscordUtil.changePresenceSince(TranslationUtil.translate('rpc.menus'), null);
}

function onEditorTreeLoaded(name:String) {
	DiscordUtil.changePresenceSince(TranslationUtil.translate('rpc.' + switch(name) {
		case "Character Editor": 'choosingCharacter';
		case "Chart Editor": 'choosingChart';
		case "Stage Editor": 'choosingStage';
	}), null);
}

function onEditorLoaded(name:String, editingThing:String) {
	DiscordUtil.changePresenceSince(TranslationUtil.translate('rpc.' + switch(name) {
		case "Character Editor": 'editingCharacter';
		case "Chart Editor": 'editingChart';
		case "Stage Editor": 'editingStage';
	}), editingThing);
}