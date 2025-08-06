package funkin.editors.charter;

import flixel.util.FlxColor;
import funkin.backend.chart.Chart;
import funkin.backend.chart.ChartData;
import funkin.editors.charter.SongCreationScreen.SongCreationData;
import funkin.editors.EditorTreeMenu;
import funkin.menus.FreeplayState.FreeplaySonglist;
import funkin.options.type.*;
import haxe.Json;

using StringTools;

class CharterSelection extends EditorTreeMenu {
	override function create() {
		super.create();
		DiscordUtil.call("onEditorTreeLoaded", ["Chart Editor"]);
		addMenu(new CharterSelectionScreen());
		bgType = 'charter';
	}
}

class CharterSelectionScreen extends EditorTreeMenuScreen {
	public var freeplayList:FreeplaySonglist;
	public var songList:Array<String> = [];
	public var curSong:ChartMetaData;

	inline public function makeChartOption(d:String, name:String):TextOption {
		return new TextOption(d, getID('acceptDifficulty'), () -> FlxG.switchState(new Charter(name, d)));
	}

	public function makeSongOption(s:ChartMetaData):IconOption {
		songList.push(s.name.toLowerCase());

		var opt = new IconOption(s.name, getID('acceptSong'), s.icon, () -> {
			curSong = s;

			var screen = new EditorTreeMenuScreen(s.name, getID('selectDifficulty'), [
				for (d in s.difficulties) if (d != '') makeChartOption(d, s.name)
			]);

			#if sys
			screen.insert(0, new NewOption(getID('newDifficulty'), getID('newDifficultyDesc'), () -> {
				parent.openSubState(new ChartCreationScreen(saveChart));
			}));
			screen.curSelected = 1;
			#end

			parent.addMenu(screen);
		});
		opt.suffix = ' >';
		opt.editorFlashColor = s.color.getDefault(FlxColor.WHITE);

		return opt;
	}

	public function new() {
		super('editor.chart.name', 'charterSelection.desc', 'charterSelection.', 'newSong', 'newSongDesc', () -> {
			parent.openSubState(new SongCreationScreen(saveSong));
		});
		freeplayList = FreeplaySonglist.get(false);

		for (i => s in freeplayList.songs) add(makeSongOption(s));
	}

	#if sys
	public function saveSong(creation:SongCreationData, ?callback:String -> SongCreationData -> Void) {
		var songAlreadyExists:Bool = songList.contains(creation.meta.name.toLowerCase());
		if (songAlreadyExists) {
			parent.openSubState(new UIWarningSubstate(TU.translate("chartCreation.warnings.song-exists-title"), TU.translate("chartCreation.warnings.song-exists-body"), [
				{label: TU.translate("editor.ok"), color: 0xFFFF0000, onClick: (t) -> {}},
			]));
			return;
		}

		var songFolder:String = '${Paths.getAssetsRoot()}/songs/${creation.meta.name}';

		#if sys
		// Make Directories
		CoolUtil.addMissingFolders(songFolder);
		sys.FileSystem.createDirectory('$songFolder/song');
		sys.FileSystem.createDirectory('$songFolder/charts');

		// Save Files
		CoolUtil.safeSaveFile('$songFolder/meta.json', Chart.makeMetaSaveable(creation.meta));
		if (creation.instBytes != null) sys.io.File.saveBytes('$songFolder/song/Inst.${Flags.SOUND_EXT}', creation.instBytes);
		if (creation.voicesBytes != null) sys.io.File.saveBytes('$songFolder/song/Voices.${Flags.SOUND_EXT}', creation.voicesBytes);

		if (creation.playerVocals != null) sys.io.File.saveBytes('$songFolder/song/Voices-Player.${Flags.SOUND_EXT}', creation.playerVocals);
		if (creation.oppVocals != null) sys.io.File.saveBytes('$songFolder/song/Voices-Opponent.${Flags.SOUND_EXT}', creation.oppVocals);
		#end

		if (callback != null) callback(songFolder, creation);

		// Add to List
		freeplayList.songs.insert(0, creation.meta);
		insert(1, makeSongOption(creation.meta));
	}

	public function saveChart(name:String, data:ChartData) {
		var difficultyAlreadyExists:Bool = curSong.difficulties.contains(name);
		if (difficultyAlreadyExists) {
			parent.openSubState(new UIWarningSubstate(TU.translate("chartCreation.warnings.chart-exists-title"), TU.translate("chartCreation.warnings.chart-exists-body"), [
				{label: TU.translate("editor.ok"), color: 0xFFFF0000, onClick: (t) -> {}},
			]));
			return;
		}

		var songFolder:String = '${Paths.getAssetsRoot()}/songs/${curSong.name}';

		// Save Files
		CoolUtil.safeSaveFile('$songFolder/charts/${name}.json', Json.stringify(data, Flags.JSON_PRETTY_PRINT));

		// Add to List
		curSong.difficulties.push(name);
		parent.tree.last().insert(parent.tree.last().length - 1, makeChartOption(name, curSong.name));

		// Add to Meta
		var meta = Json.parse(sys.io.File.getContent('$songFolder/meta.json'));
		if (meta.difficulties != null && !meta.difficulties.contains(name)) {
			meta.difficulties.push(name);
			CoolUtil.safeSaveFile('$songFolder/meta.json', Chart.makeMetaSaveable(meta));
		}
	}
	#end
}