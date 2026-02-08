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

	inline public function makeChartOption(d:String, v:String, name:String):TextOption {
		return new TextOption(d, getID('acceptDifficulty'), () -> FlxG.switchState(new Charter(name, d, v)));
	}

	inline public function makeVariationOption(s:ChartMetaData):TextOption {
		return new TextOption(s.variant, getID('acceptVariation'), " >", () -> openSongOption(s, false));
	}

	public function openSongOption(s:ChartMetaData, first = true) {
		curSong = s;

		var isVariant = s.variant != null && s.variant != '';
		var screen = new EditorTreeMenuScreen((first || !isVariant) ? (s.name + (isVariant ? ' (${s.variant})' : '')) : s.variant, getID('selectDifficulty'));

		for (d in s.difficulties) if (d != '') screen.add(makeChartOption(d, isVariant ? s.variant : null, s.name));
		if (s.difficulties.length > 0 && s.variants.length > 0) screen.add(new Separator()); // Create a separator only when there are both difficulty and variant options available.
		for (v in s.variants) if (s.metas.get(v) != null) screen.add(makeVariationOption(s.metas.get(v)));

		#if sys
		screen.insert(0, new NewOption(getID('newDifficulty'), getID('newDifficultyDesc'), () -> {
			parent.openSubState(new ChartCreationScreen(saveChart));
		}));

		if (!first) screen.curSelected = (s.difficulties.length + s.variants.length) > 0 ? 1 : 0;
		else {
			cast(screen.members[0], NewOption).itemHeight = 120;
			screen.insert(1, new NewOption(getID('newVariation'), getID('newVariationDesc'), () -> {
				parent.openSubState(new VariationCreationScreen(s, saveSong));
			}));
			screen.curSelected = (s.difficulties.length + s.variants.length) > 0 ? 2 : 1;
		}
		#end

		parent.addMenu(screen);
	}

	public function makeSongOption(s:ChartMetaData):IconOption {
		songList.push(s.name.toLowerCase());

		var opt = new IconOption(s.name, getID('acceptSong'), s.icon, () -> openSongOption(s, true));
		opt.suffix = " >";
		opt.editorFlashColor = s.color.getDefault(FlxColor.WHITE);

		return opt;
	}

	public function new() {
		super('editor.chart.name', 'charterSelection.desc', 'charterSelection.', 'newSong', 'newSongDesc', #if sys () -> {
			parent.openSubState(new SongCreationScreen(saveSong));
		} #end);
		freeplayList = FreeplaySonglist.get(false);

		for (i => s in freeplayList.songs) add(makeSongOption(s));
	}

	#if sys
	public function saveSong(creation:SongCreationData, ?callback:String -> Void) {
		var variant = creation.meta.variant != null && creation.meta.variant != "" ? creation.meta.variant : null;
		if (variant != null && curSong != null ? curSong.metas.exists(variant) : songList.contains(creation.meta.name.toLowerCase())) {
			parent.openSubState(new UIWarningSubstate(TU.translate("chartCreation.warnings.song-exists-title"), TU.translate("chartCreation.warnings.song-exists-body"), [
				{label: TU.translate("editor.ok"), color: 0xFFFF0000, onClick: (t) -> {}},
			]));
			return;
		}

		var songFolder:String = '${Paths.getAssetsRoot()}/songs/${variant != null && curSong != null ? curSong.name : creation.meta.name}';

		#if sys
		// Make Directories
		CoolUtil.addMissingFolders(songFolder);
		sys.FileSystem.createDirectory('$songFolder/song');
		sys.FileSystem.createDirectory('$songFolder/charts');

		// Save Files
		var instSuffix = creation.meta.instSuffix != null ? creation.meta.instSuffix : '', vocalsSuffix = creation.meta.vocalsSuffix != null ? creation.meta.vocalsSuffix : '';
		CoolUtil.safeSaveFile('$songFolder/meta${variant != null ? "-" + variant : ""}.json', Json.stringify(Chart.filterMetaForSaving(creation.meta), null, Flags.JSON_PRETTY_PRINT));
		if (creation.instBytes != null) sys.io.File.saveBytes('$songFolder/song/Inst$instSuffix.${Flags.SOUND_EXT}', creation.instBytes);
		if (creation.voicesBytes != null) sys.io.File.saveBytes('$songFolder/song/Voices$vocalsSuffix.${Flags.SOUND_EXT}', creation.voicesBytes);

		if (creation.playerVocals != null) sys.io.File.saveBytes('$songFolder/song/Voices-Player$vocalsSuffix.${Flags.SOUND_EXT}', creation.playerVocals);
		if (creation.oppVocals != null) sys.io.File.saveBytes('$songFolder/song/Voices-Opponent$vocalsSuffix.${Flags.SOUND_EXT}', creation.oppVocals);
		#end

		if (callback != null) callback(songFolder);

		// Add to List
		if (variant != null && curSong != null) {
			if (curSong.variants == null) curSong.variants = [];
			if (!curSong.variants.contains(variant)) curSong.variants.push(variant);

			curSong.metas.set(variant, creation.meta);

			parent.tree.last().add(makeVariationOption(creation.meta));

			var metaPath = '$songFolder/meta${curSong.variant != null && curSong.variant == "" ? "-" + curSong.variant : ""}.json';
			CoolUtil.safeSaveFile(metaPath, Chart.makeMetaSaveable(curSong));
		}
		else {
			freeplayList.songs.insert(0, creation.meta);
			insert(1, makeSongOption(creation.meta));
		}
	}

	public function saveChart(name:String, data:ChartData) {
		if (curSong.difficulties.contains(name)) {
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

		var screen = parent.tree.last();
		var idx = 0;
		while (!(screen.members[idx] is Separator)) idx++;
		screen.insert(idx, makeChartOption(name, curSong.variant != null && curSong.variant != "" ? curSong.variant : null, curSong.name));

		// Add to Meta
		var metaPath = '$songFolder/meta${curSong.variant != null && curSong.variant == "" ? "-" + curSong.variant : ""}.json';
		CoolUtil.safeSaveFile(metaPath, Chart.makeMetaSaveable(curSong));
	}
	#end
}