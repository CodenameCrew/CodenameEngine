package funkin.editors.charter;
// ! FUCK YOU CHUF (your biggest fan -lunar) <3

// import flixel.FlxLayer;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.util.FlxSort;
import funkin.backend.chart.*;
import funkin.backend.chart.ChartData;
import funkin.backend.system.Conductor;
import funkin.backend.system.framerate.Framerate;
import funkin.editors.charter.CharterBackdropGroup.EventBackdrop;
import funkin.editors.charter.CharterBackdropGroup.CharterGridSeperatorBase;
import funkin.editors.charter.CharterEvent;
import funkin.editors.charter.CharterStrumline;
import funkin.editors.extra.CameraHoverDummy;
import funkin.editors.ui.UIContextMenu.UIContextMenuOption;
import funkin.editors.ui.UIContextMenu.UIContextMenuOptionSpr;
import funkin.editors.ui.UIState;
import funkin.editors.ui.UITopMenu.UITopMenuButton;
import haxe.Json;
#if sys
import sys.FileSystem;
#end
import flixel.util.FlxColor;

class Charter extends UIState {
	public static var __song:String;
	static var __diff:String;
	static var __variant:String;
	static var __reload:Bool;

	var chart(get, never):ChartData;
	private function get_chart()
		return PlayState.SONG;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("charter." + id, args);

	public static var instance(get, never):Charter;

	private static inline function get_instance()
		return FlxG.state is Charter ? cast FlxG.state : null;

	public var charterBG:FunkinSprite;
	public var charterBookmarksGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	public var uiGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	public var topMenu:Array<UIContextMenuOption>;
	@:noCompletion private var playbackIndex:Int = 7;
	@:noCompletion private var snapIndex:Int = 6;
	@:noCompletion private var noteIndex:Int = 5;
	@:noCompletion private var songIndex:Int = 4;

	public var scrollBar:UIScrollBar;
	public var songPosInfo:UIText;

	public var shouldScroll:Bool = true;

	public var quantButtons:Array<CharterQuantButton> = [];
	public var playBackSlider:UISlider;

	public var topMenuSpr:UITopMenu;
	public var gridBackdrops:CharterBackdropGroup;
	public var leftEventsBackdrop:EventBackdrop;
	public var localAddEventSpr:CharterEventAdd;
	public var rightEventsBackdrop:EventBackdrop;
	public var globalAddEventSpr:CharterEventAdd;

	public var gridBackdropDummy:CameraHoverDummy;
	public var noteHoverer:CharterNoteHoverer;
	public var noteDeleteAnims:CharterDeleteAnim;

	public var strumlineInfoBG:FlxSprite;
	public var strumlineAddButton:CharterStrumlineButton;
	public var strumlineLockButton:CharterStrumlineButton;

	public var hitsound:FlxSound;
	public var metronome:FlxSound;

	public var vocals:FlxSound;

	public var quant:Int = 16;
	public var quants:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 192]; // different quants

	public var noteType:Int = 0;
	public var noteTypes:Array<String> = [];
	public var noteTypeText:UIText;

	public var strumLines:CharterStrumLineGroup = new CharterStrumLineGroup();
	public var notesGroup:CharterNoteGroup = new CharterNoteGroup();

	public var leftEventRowText:UIText;
	public var rightEventRowText:UIText;
	public var leftEventsGroup:CharterEventGroup = new CharterEventGroup();
	public var rightEventsGroup:CharterEventGroup = new CharterEventGroup();

	public var charterCamera:FlxCamera;
	public var uiCamera:FlxCamera;
	public var selectionBox:UISliceSprite;
	public var autoSaveNotif:CharterAutoSaveUI;
	public static var autoSaveTimer:Float = 0;

	public static var selection:Selection;

	public static var playtestInfo:PlaytestInfo;
	public static var undos:UndoList<CharterChange>;

	public static var clipboard:Array<CharterCopyboardObject> = [];
	public static var waveformHandler:CharterWaveformHandler;

	private var SONGPOSINFO_STEP = TU.getRaw("songPosInfo.step");
	private var SONGPOSINFO_BEAT = TU.getRaw("songPosInfo.beat");
	private var SONGPOSINFO_MEASURE = TU.getRaw("songPosInfo.measure");
	private var SONGPOSINFO_BPM = TU.getRaw("songPosInfo.bpm");
	private var SONGPOSINFO_TIMESIGNATURE = TU.getRaw("songPosInfo.timeSignature");

	public function new(song:String, diff:String, variant:String, reload:Bool = true) {
		super();
		if (song != null) {
			__song = song;
			__diff = diff;
			__variant = variant;
			__reload = reload;
		}
	}

	public override function create() {
		super.create();

		WindowUtils.suffix = " (" + TU.translate("editor.chart.name") + ")";
		SaveWarning.selectionClass = CharterSelection;
		SaveWarning.saveFunc = () -> saveEverything();

		topMenu = [
			{
				label: translate("topBar.file"),
				childs: [
					/*{
						label: translate("file.new")
					},
					null,*/
					{
						label: translate("file.save"),
						keybind: [CONTROL, S],
						onSelect: _file_save_all,
					},
					{
						label: translate("file.saveAs"),
						keybind: [CONTROL, SHIFT, S],
						onSelect: _file_saveas,
					},
					null,
					{
						label: translate("file.saveGlobalEvents"),
						keybind: [CONTROL, B, S],
						onSelect: _file_events_save,
					},
					{
						label: translate("file.saveGlobalEventsAs"),
						onSelect: _file_events_saveas,
					},
					{
						label: translate("file.saveNoLocalEvents"),
						keybind: [CONTROL, ALT, S],
						onSelect: _file_save_no_events,
					},
					{
						label: translate("file.saveNoLocalEventsAs"),
						onSelect: _file_saveas_no_events,
					},
					null,
					{
						label: translate("file.saveMeta"),
						keybind: [CONTROL, M, S],
						onSelect: _file_meta_save,
					},
					{
						label: translate("file.saveMetaAs"),
						onSelect: _file_meta_saveas,
					},
					null,
					{
						label: translate("file.exportFnfLegacy"),
						onSelect: _file_saveas_fnflegacy,
					},
					{
						label: translate("file.exportPsych"),
						onSelect: _file_saveas_psych,
					},
					null,
					{
						label: translate("file.exit"),
						onSelect: _file_exit
					}
				]
			},
			{
				label: translate("topBar.edit"),
				childs: [
					{
						label: translate("edit.undo"),
						keybind: [CONTROL, Z],
						onSelect: _edit_undo
					},
					{
						label: translate("edit.redo"),
						keybinds: [[CONTROL, Y], [CONTROL, SHIFT, Z]],
						onSelect: _edit_redo
					},
					null,
					{
						label: translate("edit.copy"),
						keybind: [CONTROL, C],
						onSelect: cast _edit_copy
					},
					{
						label: translate("edit.paste"),
						keybind: [CONTROL, V],
						onSelect: _edit_paste
					},
					null,
					{
						label: translate("edit.cut"),
						keybind: [CONTROL, X],
						onSelect: _edit_cut
					},
					{
						label: translate("edit.delete"),
						keybind: [DELETE],
						onSelect: _edit_delete
					}
				]
			},
			{
				label: translate("topBar.chart"),
				childs: [
					{
						label: translate("chart.playtest"),
						keybind: [ENTER],
						onSelect: _chart_playtest
					},
					{
						label: translate("chart.playtestHere"),
						keybind: [SHIFT, ENTER],
						onSelect: _chart_playtest_here
					},
					null,
					{
						label: translate("chart.playtestOpponent"),
						keybind: [CONTROL, ENTER],
						onSelect: _chart_playtest_opponent
					},
					{
						label: translate("chart.playtestOpponentHere"),
						keybind: [CONTROL, SHIFT, ENTER],
						onSelect: _chart_playtest_opponent_here
					},
					null,
					{
						label: translate("chart.enableScripts"),
						onSelect: _chart_enablescripts,
						icon: Options.charterEnablePlaytestScripts ? 1 : 0
					},
					null,
					{
						label: translate("chart.editChartData"),
						color: 0xFF959829, icon: 4,
						onCreate: function (button:UIContextMenuOptionSpr) {button.label.offset.x = button.icon.offset.x = -2;},
						onSelect: chart_edit_data
					},
					{
						label: translate("chart.editMetadata"),
						color: 0xFF959829, icon: 4,
						onCreate: function (button:UIContextMenuOptionSpr) {button.label.offset.x = button.icon.offset.x = -2;},
						onSelect: chart_edit_metadata
					}
				]
			},
			{
				label: translate("topBar.view"),
				childs: [
					{
						label: translate("view.zoomIn"),
						keybind: [CONTROL, NUMPADPLUS],
						onSelect: _view_zoomin
					},
					{
						label: translate("view.zoomOut"),
						keybind: [CONTROL, NUMPADMINUS],
						onSelect: _view_zoomout
					},
					{
						label: translate("view.resetZoom"),
						keybind: [CONTROL, NUMPADZERO],
						onSelect: _view_zoomreset
					},
					null,
					{
						label: translate("view.showSectionsSeparator"),
						onSelect: _view_showeventSecSeparator,
						icon: Options.charterShowSections ? 1 : 0
					},
					{
						label: translate("view.showBeatsSeparator"),
						onSelect: _view_showeventBeatSeparator,
						icon: Options.charterShowBeats ? 1 : 0
					},
					null,
					{
						label: translate("view.rainbowWaveforms"),
						onSelect: _view_switchWaveformRainbow,
						icon: Options.charterRainbowWaveforms ? 1 : 0
					},
					{
						label: translate("view.lowDetailWaveforms"),
						onSelect: _view_switchWaveformDetail,
						icon: Options.charterLowDetailWaveforms ? 1 : 0
					},
					null,
					{
						label: translate("view.scrollLeft"),
						keybind: [SHIFT, LEFT],
						onSelect: _view_scrollleft
					},
					{
						label: translate("view.scrollRight"),
						keybind: [SHIFT, RIGHT],
						onSelect: _view_scrollright
					},
					{
						label: translate("view.scrollReset"),
						keybind: [SHIFT, DOWN],
						onSelect: _view_scrollreset
					}
				]
			},
			{
				label: translate("topBar.song"),
				childs: buildSongUI()
			},
			{
				label: translate("topBar.note") + " >",
				childs: buildNoteTypesUI()
			},
			{
				label: translate("topBar.snap") + " >",
				childs: buildSnapsUI()
			},
			{
				label: translate("topBar.playback") + " >",
				childs: [
					{
						label: translate("playback.play"),
						keybind: [SPACE],
						onSelect: _playback_play
					},
					null,
					{
						label: translate("playback.speedRaise", ["25"]),
						keybind: [PERIOD],
						onSelect: _playback_speed_raise
					},
					{
						label: translate("playback.speedReset"),
						onSelect: _playback_speed_reset
					},
					{
						label: translate("playback.speedLower", ["25"]),
						keybind: [COMMA],
						onSelect: _playback_speed_lower
					},
					null,
					{
						label: translate("playback.sectionBack"),
						keybind: [A],
						onSelect: _playback_back
					},
					{
						label: translate("playback.sectionForward"),
						keybind: [D],
						onSelect: _playback_forward
					},
					{
						label: translate("playback.sectionStart"),
						keybind: [SHIFT, S],
						onSelect: _playback_section_start
					},
					null,
					{
						label: translate("playback.backStep"),
						keybind: [W],
						onSelect: _playback_back_step
					},
					{
						label: translate("playback.forwardStep"),
						keybind: [S],
						onSelect: _playback_forward_step
					},
					null,
					{
						label: translate("playback.metronome"),
						onSelect: _playback_metronome,
						icon: Options.charterMetronomeEnabled ? 1 : 0
					},
					/*{
						label: translate("playback.visualMetronome")
					},*/
				]
			}
		];

		hitsound = FlxG.sound.load(Paths.sound(Flags.DEFAULT_CHARTER_HITSOUND_SOUND));
		metronome = FlxG.sound.load(Paths.sound(Flags.DEFAULT_CHARTER_METRONOME_SOUND));

		charterCamera = FlxG.camera;
		uiCamera = new FlxCamera();
		uiCamera.bgColor = 0;
		FlxG.cameras.add(uiCamera);

		for (camera in FlxG.cameras.list) camera.antialiasing = false;

		charterBG = new FunkinSprite(0, 0, Paths.image('menus/menuDesat'));
		charterBG.color = 0xFF181818;
		charterBG.cameras = [charterCamera];
		charterBG.screenCenter();
		charterBG.scrollFactor.set();
		add(charterBG);

		gridBackdrops = new CharterBackdropGroup(strumLines);
		gridBackdrops.notesGroup = this.notesGroup;

		leftEventRowText = new UIText(0, -40, 0, translate("info.localEvents"), 12);
		leftEventRowText.alignment = "center"; leftEventRowText.alpha = 0.75;

		leftEventsBackdrop = new EventBackdrop(false);
		leftEventsBackdrop.x = -leftEventsBackdrop.width;

		leftEventRowText.cameras = leftEventsBackdrop.cameras = leftEventsGroup.cameras = [charterCamera];
		leftEventsGroup.eventsBackdrop = leftEventsBackdrop;
		leftEventsGroup.eventsRowText = leftEventRowText;

		rightEventRowText = new UIText(0, -40, 0, translate("info.globalEvents"), 12);
		rightEventRowText.alignment = "center"; rightEventRowText.alpha = 0.75;

		rightEventsBackdrop = new EventBackdrop(true);
		rightEventsBackdrop.x = 0;

		rightEventRowText.cameras = rightEventsBackdrop.cameras = rightEventsGroup.cameras = [charterCamera];
		rightEventsGroup.eventsBackdrop = rightEventsBackdrop;
		rightEventsGroup.eventsRowText = rightEventRowText;

		// thank you neo for pointing out im stupid -lunar
		// this is future lunar i completely forgot what neo pointed out but hes awesome go follow him on twitter 

		add(gridBackdropDummy = new CameraHoverDummy(gridBackdrops, FlxPoint.weak(1, 0)));
		selectionBox = new UISliceSprite(0, 0, 2, 2, 'editors/ui/selection');
		selectionBox.visible = false;
		selectionBox.scrollFactor.set(1, 1);
		selectionBox.incorporeal = true;

		noteHoverer = new CharterNoteHoverer();
		noteDeleteAnims = new CharterDeleteAnim();

		charterBookmarksGroup.cameras = selectionBox.cameras = notesGroup.cameras = gridBackdrops.cameras =
		noteHoverer.cameras = noteDeleteAnims.cameras = [charterCamera];

		topMenuSpr = new UITopMenu(topMenu);
		topMenuSpr.cameras = uiGroup.cameras = [uiCamera];

		noteTypeText = new UIText(0, 0, 0, "(0) " + translate("noteTypes.default"));
		noteTypeText.cameras = [uiCamera];

		scrollBar = new UIScrollBar(FlxG.width - 20, topMenuSpr.bHeight, 1000, 0, 100);
		scrollBar.cameras = [uiCamera];
		scrollBar.onChange = function(v) {
			if (!FlxG.sound.music.playing)
				Conductor.songPosition = Conductor.getTimeForStep(v) + Conductor.songOffset;
		};
		uiGroup.add(scrollBar);

		songPosInfo = new UIText(FlxG.width - 30 - 400, scrollBar.y + 10, 400, "00:00 / 00:00\nBeat: 0\nStep: 0\nMeasure: 0\nBPM: 0\nTime Signature: 4/4");
		songPosInfo.alignment = RIGHT;
		uiGroup.add(songPosInfo);

		playBackSlider = new UISlider(FlxG.width - 160 - 26 - 20, (23/2) - (12/2), 160, 1, [{start: 0.25, end: 1, size: 0.5}, {start: 1, end: 2, size: 0.5}], true);
		playBackSlider.onChange = function (v) {
			FlxG.sound.music.pitch = vocals.pitch = v;
			for (strumLine in strumLines.members) strumLine.vocals.pitch = v;
		};
		uiGroup.add(playBackSlider);

		quants.reverse();
		for (quant in quants) {
			var button:CharterQuantButton = new CharterQuantButton(0, 0, quant);
			button.onClick = () -> {setquant(button.quant);};
			quantButtons.push(cast uiGroup.add(button));
		}
		quants.reverse();

		strumlineInfoBG = new UISprite();
		strumlineInfoBG.loadGraphic(Paths.image('editors/charter/strumline-info-bg'));
		strumlineInfoBG.y = 23;
		strumlineInfoBG.scrollFactor.set();

		autoSaveNotif = new CharterAutoSaveUI(20, strumlineInfoBG.y + strumlineInfoBG.height + 20);
		uiGroup.add(autoSaveNotif);

		strumlineAddButton = new CharterStrumlineButton("editors/new", translate("createNew"));
		strumlineAddButton.onClick = createStrumWithUI;
		strumlineAddButton.animationOnClick = false;
		strumlineAddButton.textColorLerp = 0.5;

		strumlineLockButton = new CharterStrumlineButton("editors/charter/lock-strumline", translate("lock-unlock"));
		strumlineLockButton.onClick = function () {
			FlxG.sound.play(Paths.sound(!strumLines.draggable ? Flags.DEFAULT_CHARTER_STRUMUNLOCK_SOUND : Flags.DEFAULT_CHARTER_STRUMLOCK_SOUND));
			if (strumLines != null) {
				strumLines.draggable = !strumLines.draggable;
				strumlineLockButton.textTweenColor.color = strumLines.draggable ? 0xFF5C95CA : 0xFFE16565;
			}
		};

		strumlineAddButton.cameras = strumlineLockButton.cameras = [charterCamera];
		strumlineInfoBG.cameras = [charterCamera];
		strumLines.cameras = [charterCamera];

		localAddEventSpr = new CharterEventAdd(false);
		localAddEventSpr.x -= localAddEventSpr.bWidth;
		localAddEventSpr.cameras = [charterCamera];
		localAddEventSpr.alpha = 0;

		globalAddEventSpr = new CharterEventAdd(true);
		globalAddEventSpr.x = 0;
		globalAddEventSpr.cameras = [charterCamera];
		globalAddEventSpr.alpha = 0;

		// adds grid and notes so that they're ALWAYS behind the UI
		add(gridBackdrops);
		add(leftEventsBackdrop);
		add(rightEventsBackdrop);
		add(localAddEventSpr);
		add(globalAddEventSpr);
		add(leftEventsGroup);
		add(rightEventsGroup);
		add(leftEventRowText);
		add(localAddEventSpr.sideText);
		add(rightEventRowText);
		add(globalAddEventSpr.sideText);

		add(noteHoverer);
		add(noteDeleteAnims);
		add(notesGroup);
		add(selectionBox);
		add(charterBookmarksGroup);
		add(strumlineInfoBG);
		add(strumlineLockButton);
		add(strumlineAddButton);
		add(strumLines);
		// add the top menu last OUT of the ui group so that it stays on top
		add(topMenuSpr);
		add(noteTypeText);
		// add the ui group
		add(uiGroup);

		loadSong();

		if (Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 0.4;
			Framerate.memoryCounter.alpha = 0.4;
			Framerate.codenameBuildField.alpha = 0.4;
		}

		if (Options.editorsResizable)
			UIState.setResolutionAware();

		updateBookmarks(); //recalling it to fix resolutions

		// ! IF YOU EVER WANNA VIEW IN THE FUTURE, JUST USE A FLXSPRITE :D -lunar
		/*var dataDisplay:FlxSprite = new FlxSprite().loadGraphic(waveformHandler.waveDatas.get("Voices.ogg"));
		dataDisplay.scrollFactor.set(1, 0);
		dataDisplay.scale.set(2, 2);
		dataDisplay.updateHitbox();
		dataDisplay.screenCenter(Y);
		dataDisplay.cameras = [charterCamera]; dataDisplay.x = -dataDisplay.width; add(dataDisplay);*/

		DiscordUtil.call("onEditorLoaded", ["Chart Editor", __song + " (" + __diff + ")" + (__variant != null && __variant != "" ? " (" + __variant + ")" : "")]);
	}

	override function destroy() {
		__updatePlaytestInfo();

		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 1;
			Framerate.memoryCounter.alpha = 1;
			Framerate.codenameBuildField.alpha = 1;
		}
		super.destroy();
	}

	public function loadSong() {
		if (__reload) {
			EventsData.reloadEvents();
			PlayState.loadSong(__song, __diff, __variant, false, false);
			__resetStatics();
		}

		Conductor.setupSong(PlayState.SONG);
		noteTypes = PlayState.SONG.noteTypes;

		FlxG.sound.setMusic(FlxG.sound.load(Paths.inst(__song, __diff, PlayState.SONG.meta.instSuffix)));
		if (Assets.exists(Paths.voices(__song, __diff, PlayState.SONG.meta.vocalsSuffix)))
			vocals = FlxG.sound.load(Paths.voices(__song, __diff, PlayState.SONG.meta.vocalsSuffix));
		else
			vocals = new FlxSound();

		vocals.muted = !PlayState.SONG.meta.needsVoices;
		vocals.group = FlxG.sound.defaultMusicGroup;

		gridBackdrops.createGrids(PlayState.SONG.strumLines.length);

		var noteCount:Int = 0;
		for (strL in PlayState.SONG.strumLines) {
			createStrumline(strumLines.members.length, strL, false, false);
			noteCount += strL.notes.length;
		}

		// create notes
		notesGroup.autoSort = false;
		notesGroup.preallocate(noteCount);

		var notesCreated:Int = 0;
		for (i => strL in PlayState.SONG.strumLines)
			for (note in strL.notes) {
				var n = new CharterNote();
				var t = Conductor.getStepForTime(note.time);
				n.updatePos(t, note.id, Conductor.getStepForTime(note.time + note.sLen) - t, note.type, strumLines.members[i]);
				notesGroup.members[notesCreated++] = n;
			}
		notesGroup.sortNotes();
		notesGroup.autoSort = true;

		// create events
		rightEventsGroup.autoSort = leftEventsGroup.autoSort = false;
		var lastLeftEvents:CharterEvent = null, lastRightEvents:CharterEvent = null;
		var lastLeftTime = Math.NaN, lastRightTime = Math.NaN;
		for (e in PlayState.SONG.events) if (e != null) {
			if (e.global) {
				if (lastRightEvents != null && lastRightTime == e.time) lastRightEvents.events.push(e);
				else rightEventsGroup.add(lastRightEvents = new CharterEvent(Conductor.getStepForTime(lastRightTime = e.time), [e], e.global));
			}
			else {
				if (lastLeftEvents != null && lastLeftTime == e.time) lastLeftEvents.events.push(e);
				else leftEventsGroup.add(lastLeftEvents = new CharterEvent(Conductor.getStepForTime(lastLeftTime = e.time), [e], e.global));
			}
		}

		for (grp in [leftEventsGroup, rightEventsGroup]) {
			grp.sortEvents();
			grp.autoSort = true;
			for (e in grp.members) e.refreshEventIcons();
		}

		buildNoteTypesUI();
		updateBookmarks();
		refreshBPMSensitive();

		// Just for now until i add event stacking -lunar
		try {__relinkUndos();}
		catch (e) {Logs.trace('Failed to relink undos: ${Std.string(e)}', ERROR);}

		__applyPlaytestInfo();
	}

	public var __endStep:Float = 0;
	public function refreshBPMSensitive() {
		// refreshes everything dependant on BPM, and BPM changes
		var length = FlxG.sound.music.getDefault(vocals).length;
		scrollBar.length = __endStep = Conductor.getStepForTime(length);

		gridBackdrops.bottomLimitY = __endStep * 40;
		leftEventsBackdrop.bottomSeparator.y = rightEventsBackdrop.bottomSeparator.y = gridBackdrops.bottomLimitY-2;

		CharterGridSeperatorBase.lastConductorSprY = Math.NEGATIVE_INFINITY;

		updateWaveforms();
	}

	public function getWavesToGenerate():Array<{name:String, sound:FlxSound}> {
		var wavesToGenerate:Array<{name:String, sound:FlxSound}> = [];

		if (FlxG.sound.music.loaded)
			wavesToGenerate.push({name: 'Inst${PlayState.SONG.meta.instSuffix}.ogg', sound: FlxG.sound.music});

		if (vocals.loaded)
			wavesToGenerate.push({name: 'Voices${PlayState.SONG.meta.vocalsSuffix}.ogg', sound: vocals});

		for (strumLine in strumLines)
			if (strumLine.vocals != null && strumLine.strumLine.vocalsSuffix != null && strumLine.strumLine.vocalsSuffix != "" && strumLine.vocals.loaded)
				wavesToGenerate.push({
					name: 'Voices${strumLine.strumLine.vocalsSuffix}.ogg',
					sound: strumLine.vocals
				});

		return wavesToGenerate;
	}

	public function updateWaveforms() {
		var wavesToGenerate:Array<{name:String, sound:FlxSound}> = getWavesToGenerate();

		var oldWaveformList:Array<String> = waveformHandler.waveformList;
		var newWaveformList:Array<String> = [for (data in wavesToGenerate) data.name];

		if (waveformHandler == null ? true : waveformHandler.ampsNeeded != __endStep*40) {
			waveformHandler.clearWaveforms();
			waveformHandler.ampsNeeded = __endStep * 40;

			for (data in wavesToGenerate) {
				waveformHandler.generateShader(data.name, data.sound);
				waveformHandler.waveformList.push(data.name);
			}
		} else if (waveformHandler != null && waveformHandler.waveformList.length != newWaveformList.length) {
			for (name in oldWaveformList)
				if (!newWaveformList.contains(name))
					waveformHandler.clearWaveform(name);

			for (data in wavesToGenerate)
				if (!oldWaveformList.contains(data.name))
					waveformHandler.generateShader(data.name, data.sound);

			waveformHandler.waveformList = newWaveformList;
		}

		for (strumLine in strumLines) {
			if (strumLine.selectedWaveform == -1) continue;

			var oldName:String = oldWaveformList[strumLine.selectedWaveform];
			strumLine.selectedWaveform = waveformHandler.waveformList.indexOf(oldName);
		}
	}

	public override function beatHit(curBeat:Int) {
		super.beatHit(curBeat);
		if (FlxG.sound.music.playing) {
			if (Options.charterMetronomeEnabled)
				metronome.replay();
		}
	}

	/**
	 * NOTE AND CHARTER GRID LOGIC HERE
	 */
	#if REGION
	public var gridActionType:CharterGridActionType = NONE;
	public var dragStartPos:FlxPoint = new FlxPoint();
	public var mousePos:FlxPoint = new FlxPoint();
	public var selectionDragging:Bool = false;
	public var isSelecting:Bool = false;

	public function updateSelectionLogic() {
		function select(s:ICharterSelectable) {
			if (FlxG.keys.pressed.CONTROL) selection.push(s);
			else if (FlxG.keys.pressed.SHIFT) selection.remove(s);
			else selection = [s];
		}

		for (group in [notesGroup, leftEventsGroup, rightEventsGroup]) {
			var group:FlxTypedGroup<Dynamic> = cast group;
			group.forEach(function(s) {
				s.selected = false;
				if (gridActionType == NONE) {
					if (s is CharterNote) {
						var n:CharterNote = cast s;
						if ((n.hovered || n.sustainDraggable) && FlxG.mouse.justReleased) select(cast s);
					} else if (FlxG.mouse.justReleased && s.hovered) select(cast s);
				}
			});
		}
		selection = __fixSelection(selection);
		for(s in selection) s.selected = true;
	}

	var __autoSaveLocation:String = null;
	public function updateAutoSaving(elapsed:Float) {
		if (!Options.charterAutoSaves) return;
		autoSaveTimer -= elapsed;

		if (autoSaveTimer < Options.charterAutoSaveWarningTime && !autoSaveNotif.cancelled && !autoSaveNotif.showedAnimation) {
			if (Options.charterAutoSavesSeparateFolder)
				__autoSaveLocation = __diff.toLowerCase() + DateTools.format(Date.now(), "%m-%d_%H-%M");
			var filename = !Options.charterAutoSavesSeparateFolder ? '${__diff.toLowerCase()}.json' : '${__autoSaveLocation}.json';
			autoSaveNotif.startAutoSave(autoSaveTimer, translate("popup.savedChartAt", [filename]));
		}
		if (autoSaveTimer <= 0) {
			autoSaveTimer = Options.charterAutoSaveTime;
			if (!autoSaveNotif.cancelled) {
				buildChart();

				if (Options.charterAutoSavesSeparateFolder)
					Chart.save(PlayState.SONG, __diff.toLowerCase(), __autoSaveLocation, {saveMetaInChart: true, saveLocalEvents: true, seperateGlobalEvents: true, folder: 'autosaves', prettyPrint: Options.editorCharterPrettyPrint});
				else
					Chart.save(PlayState.SONG, __diff.toLowerCase(), __variant, {saveMetaInChart: true, saveLocalEvents: true, seperateGlobalEvents: true, prettyPrint: Options.editorCharterPrettyPrint});

				FlxG.sound.play(Paths.sound('editors/save'));
				undos.save();
			}
			autoSaveNotif.cancelled = false;
		}
	}

	var deletedNotes:Selection = new Selection();
	public function updateNoteLogic(elapsed:Float) {
		updateSelectionLogic();

		/**
		 * NOTE DRAG HANDLING
		 */
		FlxG.mouse.getWorldPosition(charterCamera, mousePos);
		if (!gridBackdropDummy.hoveredByChild && !FlxG.mouse.pressed)
			gridActionType = NONE;
		selectionBox.visible = false;
		switch(gridActionType) {
			case BOX_SELECTION:
				if (gridBackdropDummy.hoveredByChild) {
					selectionBox.visible = true;
					if (isSelecting) {
						selectionBox.x = Math.min(mousePos.x, dragStartPos.x);
						selectionBox.y = Math.min(mousePos.y, dragStartPos.y);
						selectionBox.bWidth = Std.int(Math.abs(mousePos.x - dragStartPos.x));
						selectionBox.bHeight = Std.int(Math.abs(mousePos.y - dragStartPos.y));
						if (FlxG.mouse.justReleased) isSelecting = false;
					} else {
						if (FlxG.keys.pressed.SHIFT) {
							for (group in [notesGroup, leftEventsGroup, rightEventsGroup]) {
								var group:FlxTypedGroup<Dynamic> = cast group;
								for(n in group)
									if (n.handleSelection(selectionBox) && selection.contains(n))
										selection.remove(n);
							}
						} else if (FlxG.keys.pressed.CONTROL) {
							for (group in [notesGroup, leftEventsGroup, rightEventsGroup]) {
								var group:FlxTypedGroup<Dynamic> = cast group;
								for(n in group)
									if (n.handleSelection(selectionBox) && !selection.contains(n))
										selection.push(n);
							}
						} else {
							selection = [];
							for (group in [notesGroup, leftEventsGroup, rightEventsGroup]) {
								var group:FlxTypedGroup<Dynamic> = cast group;
								for(n in group)
									if (n.handleSelection(selectionBox))
										selection.push(n);
							}
						}

						selection = __fixSelection(selection);
						gridActionType = NONE;
					}
				}
			case INVALID_DRAG:
				// do nothing, locked
				if (!FlxG.mouse.pressed)
					gridActionType = NONE;
			case NOTE_DRAG:
				selectionDragging = FlxG.mouse.pressed;
				if (selectionDragging) {
					gridBackdrops.draggingObj = null;
					selection.loop(function (n:CharterNote) {
						n.snappedToGrid = false;
						n.setPosition(n.fullID * 40 + (mousePos.x - dragStartPos.x), n.step * 40 + (mousePos.y - dragStartPos.y));
						n.y = CoolUtil.bound(n.y, 0, (__endStep*40) - n.height);
						n.x = CoolUtil.bound(n.x, 0, (strumLines.totalKeyCount-1) * 40);
						n.cursor = HAND;
					}, function (e:CharterEvent) {
						e.snappedToGrid = false;
						e.setPosition(e.eventsBackdrop.x + (e.global ? 0 : e.eventsBackdrop.width - e.bWidth) + (mousePos.x - dragStartPos.x), e.step * 40 + (mousePos.y - dragStartPos.y) - 17);
						e.y = CoolUtil.bound(e.y, -17, (__endStep*40)-17);
						e.cursor = HAND;

						e.displayGlobal = e.x + (e.bWidth/2) > ((strumLines.totalKeyCount*40)/2);
					});
					currentCursor = HAND;
				} else {
					dragStartPos.set(Std.int(dragStartPos.x / 40) * 40, dragStartPos.y);
					var verticalChange:Float = (mousePos.y - dragStartPos.y) / 40;
					var horizontalChange:Int = CoolUtil.floorInt((mousePos.x - dragStartPos.x) / 40);
					var undoDrags:Array<SelectionDragChange> = [];

					for (s in selection) {
						if (s.draggable) {
							var changePoint:FlxPoint = FlxPoint.get(verticalChange, horizontalChange);
							if (!FlxG.keys.pressed.SHIFT)
								changePoint.x -= ((s.step + verticalChange) - quantStepRounded(s.step+verticalChange, verticalChange > 0 ? 0.35 : 0.65));

							var boundedChange:FlxPoint = changePoint.clone();

							// Some maths, so cool bro -lunar (i don't know why i quote my self here)
							if (s.step + changePoint.x < 0) boundedChange.x += Math.abs(s.step + changePoint.x);
							if (s.step + changePoint.x > __endStep-1) boundedChange.x -= (s.step + changePoint.x) - (__endStep-1);

							if (s is CharterNote) {
								var note:CharterNote = cast s;
								if (note.fullID + changePoint.y < 0) boundedChange.y += Math.abs(note.fullID + changePoint.y);
								if (note.fullID + changePoint.y > strumLines.totalKeyCount-1) boundedChange.y -= (note.fullID + changePoint.y) - (strumLines.totalKeyCount-1);
							}

							s.handleDrag(boundedChange);
							undoDrags.push({selectable:s, change: boundedChange});
							changePoint.put();
						}

						s.snappedToGrid = true;
						if (s is UISprite) {
							var s:UISprite = cast s;
							s.cursor = CLICK;
						}
					}
					checkSelectionForBPMUpdates();
					if (!(verticalChange == 0 && horizontalChange == 0)) {
						notesGroup.sortNotes();

						undos.addToUndo(CChangeBundle([
							CSelectionDrag(undoDrags),
							updateEventsGroups(selection)
						]));
					}

					gridActionType = NONE;
					currentCursor = ARROW;
				}
			case NONE:
				if (FlxG.mouse.justPressed) 
					FlxG.mouse.getWorldPosition(charterCamera, dragStartPos);
				else if (FlxG.mouse.justPressedRight) {
					closeCurrentContextMenu();
					gridActionType = DELETE_SELECTION;
				}

				if (gridBackdropDummy.hovered) {
					// AUTO DETECT
					if (FlxG.mouse.justPressed) isSelecting = true;
					if (isSelecting && (Math.abs(mousePos.x - dragStartPos.x) > 20 || Math.abs(mousePos.y - dragStartPos.y) > 20)) {
						gridActionType = BOX_SELECTION;
					}

					var id = Math.floor(mousePos.x / 40);
					var mouseOnGrid = id >= 0 && id < strumLines.totalKeyCount && mousePos.y >= 0;

					if (FlxG.mouse.justReleased) {
						for (n in selection) n.selected = false;
						selection = [];

						if (mouseOnGrid && mousePos.y > 0 && mousePos.y < (__endStep)*40) {
							var note = new CharterNote();
							var targetStrumline = strumLines.getStrumlineFromID(id);
							note.updatePos(
								CoolUtil.bound(FlxG.keys.pressed.SHIFT ? ((mousePos.y-20) / 40) : quantStep(mousePos.y/40), 0, __endStep-1),
								(id-targetStrumline.startingID) % targetStrumline.keyCount, 0, noteType, targetStrumline
							);
							notesGroup.add(note);
							selection = [note];
							undos.addToUndo(CCreateSelection([note]));
							FlxG.sound.play(Paths.sound(Flags.DEFAULT_CHARTER_NOTEPLACE_SOUND));
						}
						isSelecting = false;
					}
				} else if (gridBackdropDummy.hoveredByChild) {
					if (FlxG.mouse.pressed) {
						var noteHovered:Bool = false;
						for(n in selection) if (n.hovered) {noteHovered = true; break;}

						var noteSusDrag:Bool = false;
						for(s in selection) {
							if (!(s is CharterNote)) continue;
							var n:CharterNote = cast s;
							if (n.sustainDraggable) {noteSusDrag = true; break;}
						}

						if ((Math.abs(mousePos.x - dragStartPos.x) > (noteSusDrag ? 1 : 5) || Math.abs(mousePos.y - dragStartPos.y) > (noteSusDrag ? 1 : 5))) {
							if (noteHovered) gridActionType = noteHovered ? NOTE_DRAG : INVALID_DRAG;
							if (noteSusDrag) gridActionType = SUSTAIN_DRAG;
						}
					}
				}
			case SUSTAIN_DRAG:
				selectionDragging = FlxG.mouse.pressed;
				if (selectionDragging) {
					currentCursor = CLICK;
					selection.loop(function (n:CharterNote) {
						var change:Float = Math.max((mousePos.y-(FlxG.keys.pressed.SHIFT ? dragStartPos.y : quantStep(dragStartPos.y))) / 40, -n.susLength);
						n.tempSusLength = change;

						if (!FlxG.keys.pressed.SHIFT)
							n.tempSusLength -= (n.susLength + change) - quantStepRounded(n.susLength + change, change > 0 ? 0.35 : 0.65);
						@:privateAccess n.__susInstaLerp = FlxG.keys.pressed.SHIFT;
					});
				} else {
					var undoChanges:Array<NoteSustainChange> = [];
					selection.loop(function (n:CharterNote) {
						var oldSusLen:Float = n.susLength;

						n.susLength += n.tempSusLength;
						n.tempSusLength = 0;

						@:privateAccess n.__susInstaLerp = false;
						n.updatePos(n.step, n.id, n.susLength, n.type);
						undoChanges.push({before: oldSusLen, after: n.susLength, note: n});
					});
					undos.addToUndo(CEditSustains(undoChanges));

					gridActionType = NONE;
					currentCursor = ARROW;
				}
			case DELETE_SELECTION:
				notesGroup.forEach(function(n) {
					if (n.hovered || n.sustainDraggable) {
						deletedNotes.push(n);
						deleteSingleSelection(n, false);

						if (selection.contains(n)) selection.remove(n);
						noteDeleteAnims.deleteNotes.push({
							note: n, time: noteDeleteAnims.deleteTime
						});
					}
				});

				if (FlxG.mouse.justReleasedRight) {
					if (deletedNotes.length > 0) {
						undos.addToUndo(CDeleteSelection(deletedNotes.copy()));
					}
					else if (noteDeleteAnims.garbageIcon.alpha <= .5) {
						var mousePos = FlxG.mouse.getScreenPosition(uiCamera);
						closeCurrentContextMenu();
						openContextMenu(topMenu[1].childs, null, mousePos.x, mousePos.y);
					}
					gridActionType = NONE; deletedNotes = [];
				}
		}
		localAddEventSpr.selectable = !selectionBox.visible;
		globalAddEventSpr.selectable = !selectionBox.visible;

		var inBoundsY:Bool = (mousePos.y > 0 && mousePos.y < (__endStep)*40);

		// Event Spr
		for (addEventSpr in [localAddEventSpr, globalAddEventSpr]) {
			addEventSpr.incorporeal = true;
			if ((!addEventSpr.global ? mousePos.x < 0 : mousePos.x > strumLines.totalKeyCount * 40) && gridActionType == NONE && inBoundsY) {
				var event = getHoveredEvent(mousePos.y, !addEventSpr.global ? leftEventsGroup : rightEventsGroup);
				var hoveredWidth:Float = event != null ? 27 + 40 + event.bWidth : addEventSpr.bWidth;

				if ((!addEventSpr.global ? mousePos.x > -hoveredWidth : mousePos.x < strumLines.totalKeyCount * 40 + hoveredWidth)) {
					addEventSpr.incorporeal = false;

					if (event != null) addEventSpr.updateEdit(event);
					else addEventSpr.updatePos(FlxG.keys.pressed.SHIFT ? ((mousePos.y) / 40) : quantStepRounded(mousePos.y/40));
				}
			}
			addEventSpr.sprAlpha = lerp(addEventSpr.sprAlpha, !addEventSpr.incorporeal ? 0.75 : 0, 0.25);
		}
		noteHoverer.showHoverer = Charter.instance.gridBackdropDummy.hovered;
	}

	public function quantStep(step:Float):Float {
		var stepMulti:Float = 1/(quant/16);
		return Math.floor(step/stepMulti) * stepMulti;
	}

	public function quantStepRounded(step:Float, ?roundRatio:Float = 0.5):Float {
		var stepMulti:Float = 1/(quant/16);
		return ratioRound(step/stepMulti, roundRatio) * stepMulti;
	}

	public function ratioRound(val:Float, ratio:Float):Int
		return Math.floor(val) + ((Math.abs(val % 1) > ratio ? 1 : 0) * (val > 0 ? 1 : -1));

	public function getHoveredEvent(y:Float, group:CharterEventGroup) {
		var eventHovered:CharterEvent = null;
		group.forEach(function(e) {
			if (eventHovered != null)
				return;

			if (e.hovered || (y >= e.y && y < (e.y + e.bHeight)))
				eventHovered = e;
		});
		return eventHovered;
	}

	public function deleteSingleSelection(selected:ICharterSelectable, addToUndo:Bool = true):Null<ICharterSelectable> {
		if (selected == null) return selected;

		if (selected is CharterNote) {
			FlxG.sound.play(Paths.sound(Flags.DEFAULT_CHARTER_NOTEDELETE_SOUND));
			var note:CharterNote = cast selected;
			note.strumLineID = strumLines.members.indexOf(note.strumLine);
			note.strumLine = null; // For static undos :D
			notesGroup.remove(note);
			note.kill();
		} else if (selected is CharterEvent) {
			var event:CharterEvent = cast selected;
			(event.global ? rightEventsGroup : leftEventsGroup).remove(event);
			event.kill();
		}

		if (addToUndo)
			undos.addToUndo(CDeleteSelection([selected]));

		return null;
	}

	public function createSelection(selection:Selection, addToUndo:Bool = true) {
		if (selection.length <= 0) return [];

		notesGroup.autoSort = false;
		selection.loop(function (n:CharterNote) {
			n.strumLine = strumLines.members[n.strumLineID];
			n.revive();
			notesGroup.add(n);
		}, function (e:CharterEvent) {
			e.revive();
			(e.global ? rightEventsGroup : leftEventsGroup).add(e);
			e.refreshEventIcons();
		}, false);
		notesGroup.sortNotes();
		notesGroup.autoSort = true;

		checkSelectionForBPMUpdates();

		if (addToUndo)
			undos.addToUndo(CCreateSelection(selection));
		return [];
	}

	public function deleteSelection(selection:Selection, addToUndo:Bool = true) {
		if (selection.length <= 0) return [];

		notesGroup.autoSort = false;
		for (group in [notesGroup, leftEventsGroup, rightEventsGroup]) {
			var group:FlxTypedGroup<Dynamic> = cast group;
			var member:Int = 0;
			while(member < group.members.length) {
				var s = group.members[member];
				if (selection.contains(s))
					deleteSingleSelection(s, false);
				else member++;
			}
		}
		notesGroup.sortNotes();
		notesGroup.autoSort = true;

		checkSelectionForBPMUpdates();

		if (addToUndo)
			undos.addToUndo(CDeleteSelection(selection));
		return [];
	}

	public function updateEventsGroups(selection:Selection):CharterChange {
		if (selection.length <= 0) return CEditEventGroups([]);
		var eventsChanged:Array<CharterEvent> = [];

		selection.loop(function (n:CharterNote) {}, function (e:CharterEvent) {
			if (e.displayGlobal != e.global) {
				(e.global ? rightEventsGroup : leftEventsGroup).remove(e);
				(e.displayGlobal ? rightEventsGroup : leftEventsGroup).add(e);

				e.global = e.displayGlobal;
				eventsChanged.push(e);
			}
		}, true);

		leftEventsGroup.sortEvents(); rightEventsGroup.sortEvents();
		for (e in eventsChanged) e.update(0); // remove little stutter

		return CEditEventGroups(eventsChanged);
	}

	// STRUMLINE DELETION/CREATION
	public function createStrumline(strumLineID:Int, strL:ChartStrumLine, addToUndo:Bool = true, ?__createNotes:Bool = true) {
		var cStr = new CharterStrumline(strL);
		strumLines.insert(strumLineID, cStr);
		strumLines.refreshStrumlineIDs();
		strumLines.snapStrums();

		if (__createNotes) {
			var toBeCreated:Selection = [];
			for(note in strL.notes) {
				var n = new CharterNote();
				var t = Conductor.getStepForTime(note.time);
				n.updatePos(t, note.id, Conductor.getStepForTime(note.time + note.sLen) - t, note.type, cStr);
				notesGroup.add(n);
			}
			createSelection(toBeCreated, false);
		}

		updateBookmarks();

		if (addToUndo)
			undos.addToUndo(CCreateStrumLine(strumLineID, strL));
	}

	public function deleteStrumline(strumLineID:Int, addToUndo:Bool = true) {
		var undoNotes:Array<ChartNote> = [];
		removeStrumlineFromSelection(strumLineID);

		var i = 0;
		var toBeDeleted:Selection = [];
		for (note in notesGroup.members)
			if (note.strumLineID == strumLineID) {
				undoNotes.push(buildNote(note));
				toBeDeleted.push(note);
			}
		deleteSelection(toBeDeleted, false);

		var strL = strumLines.members[strumLineID].strumLine;
		strumLines.members[strumLineID].destroy();
		strumLines.members[strumLineID] = strumLines.members[strumLines.members.length - 1];
		strumLines.members.pop();
		@:privateAccess strumLines.length--;
		strumLines.refreshStrumlineIDs();
		strumLines.snapStrums();

		updateBookmarks();

		if (addToUndo) {
			var newStrL = Reflect.copy(strL);
			newStrL.notes = undoNotes;

			undos.addToUndo(CDeleteStrumLine(strumLineID, newStrL));
		}
	}

	public function getStrumlineID(strL:ChartStrumLine):Int {
		for (index=>strumLine in strumLines.members) {
			if (strumLine.strumLine == strL)
				return index;
		}
		return -1;
	}

	public function createStrumWithUI() {
		FlxG.state.openSubState(new CharterStrumlineScreen(strumLines.members.length, null, (_) -> {
			if (_ != null) {
				createStrumline(strumLines.members.length, _);

				strumlineAddButton.textTweenColor.color = 0xFF00FF00;
				strumlineAddButton.pressAnimation(true);
			}
		}));
	}

	public inline function deleteStrumlineFromData(strL:ChartStrumLine)
		deleteStrumline(getStrumlineID(strL));

	public inline function editStrumline(strL:ChartStrumLine) {
		var strID = getStrumlineID(strL);
		var oldData:ChartStrumLine = Reflect.copy(strL);

		FlxG.state.openSubState(new CharterStrumlineScreen(strID, strL, (_) -> {
			strumLines.members[strID].strumLine = _;
			strumLines.members[strID].updateInfo();
			strumLines.refreshStrumlineIDs();

			undos.addToUndo(CEditStrumLine(strID, oldData, _));

			if (oldData.vocalsSuffix != _.vocalsSuffix) updateWaveforms();
		}));
	}

	public inline function removeStrumlineFromSelection(strumLineID:Int) {
		var i = 0;
		while(i < selection.length) {
			if (selection[i] is CharterNote) {
				var note:CharterNote = cast selection[i];
				if (note.strumLineID == strumLineID)
					selection.remove(note);
				else i++;
			} else i++;
		}
	}
	#end

	var __crochet:Float;
	var __firstFrame:Bool = true;
	var __timer:Float = 0;
	public override function update(elapsed:Float) {
		if (Options.charterRainbowWaveforms) {
			__timer += elapsed/8;
			for (shader in waveformHandler.waveShaders)
				shader.data.time.value = [__timer];
		}

		updateNoteLogic(elapsed);
		updateAutoSaving(elapsed);

		for (bs in __bookmarkObjects)
		{
			var bars:Array<FlxSprite> = bs[0];
			var text:UIText = bs[1];
			if (bars == null || bars.length == 0) continue;
			for (i => spr in bars) {
				if (spr == null || strumLines.members[i] == null) continue;
				spr.x = strumLines.members[i].x;
			}
			if (text != null)
				text.x = strumLines.members[0].x + 4;
		}

		if (FlxG.sound.music.playing || __firstFrame) {
			gridBackdrops.conductorSprY = curStepFloat * 40;
		} else {
			gridBackdrops.conductorSprY = lerp(gridBackdrops.conductorSprY, curStepFloat * 40, __firstFrame ? 1 : 1/3);
		}
		charterCamera.scroll.set(
			lerp(charterCamera.scroll.x, (((40*strumLines.totalKeyCount) - FlxG.width) / 2) + sideScroll, __firstFrame ? 1 : 1/3),
			gridBackdrops.conductorSprY - (FlxG.height * 0.5)
		);

		if (topMenuSpr.members[playbackIndex] != null) {
			var playBackButton:UITopMenuButton = cast topMenuSpr.members[playbackIndex];
			playBackButton.x = playBackSlider.x-playBackSlider.startText.width-10-playBackSlider.valueStepper.bWidth-playBackButton.bWidth-10;
			playBackButton.label.offset.x = -1;

			if (topMenuSpr.members[snapIndex] != null) {
				var snapButton:UITopMenuButton = cast topMenuSpr.members[snapIndex];
				var lastButtonX = playBackButton.x-10;

				for (button in quantButtons) {
					button.visible = ((button.quant == quant) ||
						(button.quant == quants[FlxMath.wrap(quants.indexOf(quant)-1, 0, quants.length-1)]) ||
						(button.quant == quants[FlxMath.wrap(quants.indexOf(quant)+1, 0, quants.length-1)]));
					button.selectable = button.visible;
					if (!button.visible) continue;

					button.x = lastButtonX -= button.bWidth;
					button.framesOffset = button.quant == quant ? 9 : 0;
					button.alpha = button.quant == quant ? 1 : (button.hovered ? 0.4 : 0);
				}
				snapButton.x = (lastButtonX -= snapButton.bWidth)-10;
			}
		}

		if (topMenuSpr.members[noteIndex] != null) {
			var noteTopButton:UITopMenuButton = cast topMenuSpr.members[noteIndex];
			noteTypeText.x = noteTopButton.x + noteTopButton.bWidth + 6;
			noteTypeText.y = Std.int((noteTopButton.bHeight - noteTypeText.height) / 2);
		}
		noteTypeText.text = '($noteType) ' + (noteTypes[noteType-1] == null ? translate("noteTypes.default") : noteTypes[noteType-1]);

		super.update(elapsed);

		scrollBar.size = (FlxG.height / 40 / charterCamera.zoom);
		scrollBar.start = Conductor.curStepFloat - (scrollBar.size / 2);

		if (gridBackdrops.strumlinesAmount != strumLines.members.length)
			updateDisplaySprites();

		// TODO: canTypeText in case an ui input element is focused
		if (true) {
			__crochet = ((60 / Conductor.bpm) * 1000);

			if(FlxG.keys.justPressed.ANY && !strumLines.isDragging && this.currentFocus == null && (this.subState == null || !(this.subState is CharterEventScreenNew)))
				UIUtil.processShortcuts(topMenu);

			if (!topMenuSpr.anyMenuOpened) {
				if (FlxG.mouse.wheel != 0 && shouldScroll) {
					if (FlxG.keys.pressed.CONTROL) {
						zoom += 0.25 * FlxG.mouse.wheel;
						__camZoom = Math.pow(2, zoom);
					} else if (FlxG.keys.pressed.SHIFT) {
						sideScroll -= 40 * FlxG.mouse.wheel;
					} else {
						if (!FlxG.sound.music.playing) {
							Conductor.songPosition -= (__crochet * FlxG.mouse.wheel) - Conductor.songOffset;
						}
					}
				}
			}
		}

		var songLength = FlxG.sound.music.getDefault(vocals).length;
		Conductor.songPosition = CoolUtil.bound(Conductor.songPosition + Conductor.songOffset, 0, songLength);

		if (Conductor.songPosition >= songLength - Conductor.songOffset) {
			FlxG.sound.music.pause();
			vocals.pause();
			for (strumLine in strumLines.members) strumLine.vocals.pause();
		}

		var curChange = Conductor.curChange;
		songPosInfo.text = [
			// no need to translate the time text since it has no text only numbers
			'${CoolUtil.timeToStr(Conductor.songPosition)} / ${CoolUtil.timeToStr(songLength)}',
			SONGPOSINFO_STEP.format([curStep]),
			SONGPOSINFO_BEAT.format([curBeat]),
			SONGPOSINFO_MEASURE.format([curMeasure]),
			SONGPOSINFO_BPM.format([(curChange != null && curChange.continuous && curChange.endSongTime > songPos) ? FlxMath.roundDecimal(Conductor.bpm, 3) : Conductor.bpm]),
			SONGPOSINFO_TIMESIGNATURE.format([Conductor.beatsPerMeasure, Conductor.denominator])
		].join("\n");

		if (charterCamera.zoom != (charterCamera.zoom = lerp(charterCamera.zoom, __camZoom, __firstFrame ? 1 : 0.125)))
			updateDisplaySprites();

		if (strumLines != null)
			strumlineLockButton.button.animation.play(strumLines.draggable ? "1" : "0", true);

		WindowUtils.prefix = undos.unsaved ? Flags.UNDO_PREFIX : "";
		SaveWarning.showWarning = undos.unsaved;

		__firstFrame = false;
	}

	public static var startTime:Float = 0;
	public static var startHere:Bool = false;

	function updateDisplaySprites() {
		gridBackdrops.strumlinesAmount = strumLines.members.length;

		var scaleX:Float = (FlxG.width/charterBG.width);
		var scaleY:Float = (FlxG.height/charterBG.height);

		var bgScale:Float = scaleX > scaleY ? scaleX : scaleY;

		charterBG.scale.set(
			(1 / charterCamera.zoom) * bgScale,
			(1 / charterCamera.zoom) * bgScale
		);

		strumlineInfoBG.scale.set(FlxG.width / charterCamera.zoom, 1);
		strumlineInfoBG.updateHitbox();
		strumlineInfoBG.screenCenter(X);
		strumlineInfoBG.y = -(((FlxG.height - (2 * topMenuSpr.bHeight)) / charterCamera.zoom) - FlxG.height) / 2;

		for(id=>str in strumLines.members)
			if (str != null) str.y = strumlineInfoBG.y;

		//strumlineAddButton.x = 0;
		strumlineAddButton.y = strumlineInfoBG.y;
		strumlineLockButton.y = strumlineInfoBG.y;

		strumlineLockButton.text.visible = strumlineLockButton.button.selectable = strumlineLockButton.button.visible = strumLines.members.length > 0;
	}

	public override function onResize(width:Int, height:Int) {
		super.onResize(width, height);
		if (!UIState.resolutionAware) return;

		if ((width < FlxG.initialWidth || height < FlxG.initialHeight) && !Options.bypassEditorsResize) {
			width = FlxG.initialWidth; height = FlxG.initialHeight;
		}

		scrollBar.x = width - 20;
		scrollBar.scale.y = Std.int(height - scrollBar.y);
		scrollBar.updateHitbox();

		songPosInfo.x = width - 30 - 400;
		playBackSlider.x = width - 160 - 26 - 20;

		updateDisplaySprites();
		updateBookmarks();
		charterBG.screenCenter();
	}

	var zoom(default, set):Float = 0;
	var __camZoom(default, set):Float = 1;
	function set_zoom(val:Float) {
		return zoom = CoolUtil.bound(val, -3.5, 1.75); // makes zooming not lag behind when continuing scrolling
	}
	function set___camZoom(val:Float) {
		return __camZoom = CoolUtil.bound(val, 0.1, 3);
	}

	var sideScroll(default, set):Float = 0;
	function set_sideScroll(val:Float) {
		return sideScroll = FlxMath.bound(val, -(40*strumLines.totalKeyCount) / 2, (40*strumLines.totalKeyCount) / 2);
	}

	// SAVE FUNCS
	#if REGION
	public static function saveEverything(shouldBuild:Bool = true) {
		if (shouldBuild && instance != null) instance.buildChart();
		saveChart(false);
		saveEvents(false);
		saveMeta(false);
	}

	public static function saveChart(shouldBuild:Bool = true, withEvents:Bool = true) {
		#if sys
		if (shouldBuild && instance != null) instance.buildChart();
		Chart.save(PlayState.SONG, __diff.toLowerCase(), __variant, {saveMetaInChart: false, saveLocalEvents: withEvents, prettyPrint: Options.editorCharterPrettyPrint});
		if (undos != null) undos.save();
		#else
		saveChartAs(shouldBuild, withEvents);
		#end
	}

	public static function saveChartAs(shouldBuild:Bool = true, withEvents:Bool = true) {
		saveAs(Chart.filterChartForSaving(PlayState.SONG, false, withEvents, false), null, Options.editorCharterPrettyPrint ? Flags.JSON_PRETTY_PRINT : null, {
			defaultSaveFile: '${__diff.toLowerCase()}.json'
		}, null, shouldBuild);
		if (undos != null) undos.save();
	}

	public static function saveEvents(shouldBuild:Bool = true) {
		#if sys
		if (shouldBuild && instance != null) instance.buildChart();
		Chart.save(PlayState.SONG, __diff.toLowerCase(), __variant, {saveChart: false, seperateGlobalEvents: true, prettyPrint: Options.editorCharterPrettyPrint});
		if (undos != null) undos.save();
		#else
		saveEventsAs(shouldBuild);
		#end
	}

	public static function saveEventsAs(shouldBuild:Bool = true) {
		if (shouldBuild && instance != null) instance.buildChart();
		var data = {events: Chart.filterEventsForSaving(PlayState.SONG.events, false, true)};

		saveAs(data, null, Options.editorCharterPrettyPrint ? Flags.JSON_PRETTY_PRINT : null, {
			defaultSaveFile: 'events.json'
		}, null, false);
	}

	public static function saveMeta(shouldBuild:Bool = true) {
		#if sys
		if (shouldBuild && instance != null) instance.buildChart();
		Chart.save(PlayState.SONG, __diff.toLowerCase(), __variant, {saveChart: false, overrideExistingMeta: true, prettyPrint: true});
		#else
		saveMetaAs(shouldBuild);
		#end
	}

	public static function saveMetaAs(shouldBuild:Bool = true) {
		saveAs(PlayState.SONG.meta == null ? {} : Chart.filterChartForSaving(PlayState.SONG, true, false, false).meta, null, Flags.JSON_PRETTY_PRINT, { // always pretty print meta
			defaultSaveFile: 'meta.json'
		}, null, shouldBuild);
	}

	public static function saveLegacyChartAs(shouldBuild:Bool = true) {
		saveAs(FNFLegacyParser.encode(PlayState.SONG), null, Options.editorCharterPrettyPrint ? Flags.JSON_PRETTY_PRINT : null, {
			defaultSaveFile: '${__song.toLowerCase().replace(" ", "-")}${__diff.toLowerCase() == Flags.DEFAULT_DIFFICULTY ? "" : '-${__diff.toLowerCase()}'}.json',
		}, null, shouldBuild);
	}

	public static function savePsychChartAs(shouldBuild:Bool = true) {
		saveAs(PsychParser.encode(PlayState.SONG), null, Options.editorCharterPrettyPrint ? Flags.JSON_PRETTY_PRINT : null, {
			defaultSaveFile: '${__song.toLowerCase().replace(" ", "-")}${__diff.toLowerCase() == Flags.DEFAULT_DIFFICULTY ? "" : '-${__diff.toLowerCase()}'}.json',
		}, null, shouldBuild);
	}

	public static function saveAs(data:Dynamic, ?replacer:(key:Dynamic, value:Dynamic) -> Dynamic, ?space:String, ?options:SaveSubstate.SaveSubstateData, ?saveOptions:Map<String, Bool>, shouldBuild:Bool = true) {		if (shouldBuild && instance != null) instance.buildChart();
		var cur = FlxG.state;
		while(true) {
			if (instance != null || cur.subState == null) return cur.openSubState(new SaveSubstate(Json.stringify(data, replacer, space), options, saveOptions));
			else cur = cur.subState;
		}
	}

	#if sys
	public static function saveTo(path:String, separateEvents:Bool = false, shouldBuild:Bool = true) {
		if (shouldBuild && instance != null) instance.buildChart();
		Chart.save(PlayState.SONG, __diff.toLowerCase(), __variant, {saveMetaInChart: false, saveLocalEvents: !separateEvents, songFolder: path, prettyPrint: Options.editorCharterPrettyPrint});
	}
	#end
	#end

	// TOP MENU OPTIONS
	#if REGION
	function _file_exit(_) {
		if (undos.unsaved) SaveWarning.triggerWarning();
		else {undos = null; FlxG.switchState(new CharterSelection()); Charter.instance.__clearStatics();}
	}

	function _file_save_all(_) {saveEverything(); FlxG.sound.play(Paths.sound('editors/save'));}
	function _file_save(_) {saveChart(); FlxG.sound.play(Paths.sound('editors/save'));}
	function _file_saveas(_) {saveChartAs(); FlxG.sound.play(Paths.sound('editors/save'));}
	function _file_events_save(_) {saveEvents(); FlxG.sound.play(Paths.sound('editors/save'));}
	function _file_events_saveas(_) {saveEventsAs(); FlxG.sound.play(Paths.sound('editors/save'));}
	function _file_save_no_events(_) {saveChart(true, false); FlxG.sound.play(Paths.sound('editors/save'));}
	function _file_saveas_no_events(_) {saveChartAs(true, false); FlxG.sound.play(Paths.sound('editors/save'));}
	function _file_meta_save(_) {saveMeta(); FlxG.sound.play(Paths.sound('editors/save'));}
	function _file_meta_saveas(_) {saveMetaAs(); FlxG.sound.play(Paths.sound('editors/save'));}
	function _file_saveas_fnflegacy(_) {saveLegacyChartAs(); FlxG.sound.play(Paths.sound('editors/save'));}
	function _file_saveas_psych(_) {savePsychChartAs(); FlxG.sound.play(Paths.sound('editors/save'));}

	function _edit_copy(_, playSFX=true) {
		if (playSFX) FlxG.sound.play(Paths.sound(Flags.DEFAULT_EDITOR_COPY_SOUND));
		if(selection.length == 0) return;

		var minStep:Float = selection[0].step;
		for(s in selection)
			if (s.step < minStep) minStep = s.step;

		clipboard = [
			for (s in selection)
				if (s is CharterNote) {
				var note:CharterNote = cast s;
				CNote(note.step - minStep, note.id, note.strumLineID, note.susLength, note.type);
			} else if (s is CharterEvent) {
				var event:CharterEvent = cast s;
				CEvent(event.step - minStep, [for (event in event.events) Reflect.copy(event)], event.global);
			}
		];
	}
	function _edit_paste(_) {
		FlxG.sound.play(Paths.sound(Flags.DEFAULT_EDITOR_PASTE_SOUND));
		if (clipboard.length <= 0) return;

		var minStep = curStep;
		var sObjects:Array<ICharterSelectable> = [];
		for(c in clipboard) {
			switch(c) {
				case CNote(step, id, strumLineID, susLength, type):
					var note = new CharterNote();
					note.updatePos(minStep + step, id, susLength, type, strumLines.members[CoolUtil.boundInt(strumLineID, 0, strumLines.length-1)]);
					notesGroup.add(note);
					sObjects.push(note);
				case CEvent(step, events, global):
					var event = new CharterEvent(minStep + step, events, global);
					event.refreshEventIcons();
					(global ? rightEventsGroup : leftEventsGroup).add(event);
					sObjects.push(event);
			}
		}
		selection = sObjects;
		_edit_copy(_, false); // to fix stupid bugs

		checkSelectionForBPMUpdates();

		undos.addToUndo(CCreateSelection(sObjects.copy()));
	}

	function _edit_cut(_) {
		FlxG.sound.play(Paths.sound(Flags.DEFAULT_EDITOR_CUT_SOUND));
		if (selection == null || selection.length == 0) return;

		_edit_copy(_, false);
		deleteSelection(selection, false);
	}

	function _edit_delete(_) {
		FlxG.sound.play(Paths.sound(Flags.DEFAULT_EDITOR_DELETE_SOUND));
		if (selection == null || selection.length == 0) return;
		selection.loop((n:CharterNote) -> {
			noteDeleteAnims.deleteNotes.push({note: n, time: noteDeleteAnims.deleteTime});
		});
		selection = deleteSelection(selection, true);
	}

	function _undo(undo:CharterChange) {
		FlxG.sound.play(Paths.sound(Flags.DEFAULT_EDITOR_UNDO_SOUND));
		switch(undo) {
			case null: // do nothing
			case CDeleteStrumLine(strumLineID, strumLine):
				createStrumline(strumLineID, strumLine, false);
			case CCreateStrumLine(strumLineID, strumLine):
				deleteStrumline(strumLineID, false);
			case COrderStrumLine(strumLineID, oldID, newID):
				var strumLine:CharterStrumline = strumLines.members[strumLineID];
				strumLines.orderStrumline(strumLine, oldID);
				undos.redoList[0] = COrderStrumLine(strumLines.members.indexOf(strumLine), oldID, newID);
			case CEditStrumLine(strumLineID, oldStrumLine, newStrumLine):
				strumLines.members[strumLineID].strumLine = oldStrumLine;
				strumLines.members[strumLineID].updateInfo();
				strumLines.refreshStrumlineIDs();
			case CCreateSelection(selection):
				deleteSelection(selection, false);
			case CDeleteSelection(selection):
				createSelection(selection, false);
			case CSelectionDrag(selectionDrags):
				for (s in selectionDrags)
					if (s.selectable.draggable) s.selectable.handleDrag(s.change * -1);

				selection = [for (s in selectionDrags) s.selectable];
				checkSelectionForBPMUpdates();
			case CEditSustains(changes):
				for(n in changes)
					n.note.updatePos(n.note.step, n.note.id, n.before, n.note.type);
			case CEditEvent(event, oldEvents, newEvents):
				event.events = oldEvents.copy();
				event.refreshEventIcons();

				Charter.instance.updateBPMEvents();
			case CEditEventGroups(events):
				for (event in events) event.displayGlobal = !event.global;
				updateEventsGroups(cast events);

			case CEditChartData(oldData, newData):
				PlayState.SONG.stage = oldData.stage;
				PlayState.SONG.scrollSpeed = oldData.speed;
			case CEditNoteTypes(oldArray, newArray):
				noteTypes = oldArray;
				changeNoteType(null, false);
			case CEditBookmarks(oldArray, newArray):
				PlayState.SONG.bookmarks = oldArray;
				updateBookmarks();
			case CEditSpecNotesType(notes, oldTypes, newTypes):
				for(i=>note in notes) note.updatePos(note.step, note.id, note.susLength, oldTypes[i]);
			case CChangeBundle(changes):
				for (change in changes) _undo(change);
		}
	}

	function _edit_undo(_) {
		if (strumLines.isDragging || selectionDragging || (subState != null && !(subState is UIContextMenu))) return;

		selection = [];
		_undo(undos.undo());
	}

	function _redo(redo:CharterChange) {
		FlxG.sound.play(Paths.sound(Flags.DEFAULT_EDITOR_REDO_SOUND));
		switch(redo) {
			case null: // do nothing
			case CDeleteStrumLine(strumLineID, strumLine):
				deleteStrumline(strumLineID, false);
			case CCreateStrumLine(strumLineID, strumLine):
				createStrumline(strumLineID, strumLine, false);
			case COrderStrumLine(strumLineID, oldID, newID):
				var strumLine:CharterStrumline = strumLines.members[strumLineID];
				strumLines.orderStrumline(strumLine, newID);
				undos.undoList[0] = COrderStrumLine(strumLines.members.indexOf(strumLine), oldID, newID);
			case CEditStrumLine(strumLineID, oldStrumLine, newStrumLine):
				strumLines.members[strumLineID].strumLine = newStrumLine;
				strumLines.members[strumLineID].updateInfo();
				strumLines.refreshStrumlineIDs();
			case CCreateSelection(selection):
				createSelection(selection, false);
			case CDeleteSelection(selection):
				deleteSelection(selection, false);
			case CSelectionDrag(selectionDrags):
				for (s in selectionDrags)
					if (s.selectable.draggable) s.selectable.handleDrag(s.change);
				//this.selection = selection;
				checkSelectionForBPMUpdates();
			case CEditSustains(changes):
				for(n in changes)
					n.note.updatePos(n.note.step, n.note.id, n.after, n.note.type);
			case CEditEvent(event, oldEvents, newEvents):
				event.events = newEvents.copy();
				event.refreshEventIcons();

				Charter.instance.updateBPMEvents();
			case CEditEventGroups(events):
				for (event in events) event.displayGlobal = !event.global;
				updateEventsGroups(cast events);

			case CEditChartData(oldData, newData):
				PlayState.SONG.stage = newData.stage;
				PlayState.SONG.scrollSpeed = newData.speed;
			case CEditNoteTypes(oldArray, newArray):
				noteTypes = newArray;
				changeNoteType(null, false);
			case CEditBookmarks(oldArray, newArray):
				PlayState.SONG.bookmarks = newArray;
				updateBookmarks();
			case CEditSpecNotesType(notes, oldTypes, newTypes):
				for(i=>note in notes) note.updatePos(note.step, note.id, note.susLength, newTypes[i]);
			case CChangeBundle(changes):
				for (change in changes) _redo(change);
		}
	}

	function _edit_redo(_) {
		if (strumLines.isDragging || selectionDragging || (subState != null && !(subState is UIContextMenu))) return;

		selection = [];
		_redo(undos.redo());
	}

	inline function _chart_playtest(_)
		playtestChart(0, false);
	inline function _chart_playtest_here(_)
		playtestChart(Conductor.songPosition, false, true);
	inline function _chart_playtest_opponent(_)
		playtestChart(0, true);
	inline function _chart_playtest_opponent_here(_)
		playtestChart(Conductor.songPosition, true, true);
	function _chart_enablescripts(t) {
		t.icon = (Options.charterEnablePlaytestScripts = !Options.charterEnablePlaytestScripts) ? 1 : 0;
	}

	function chart_edit_data(_)
		FlxG.state.openSubState(new ChartDataScreen(PlayState.SONG));
	function chart_edit_metadata(_)
		FlxG.state.openSubState(new CharterMetaDataScreen(PlayState.SONG.meta));

	function _playback_play(_) {
		if (Conductor.songPosition >= FlxG.sound.music.getDefault(vocals).length - Conductor.songOffset) return;

		if (FlxG.sound.music.playing) {
			FlxG.sound.music.pause();
			vocals.pause();
			for (strumLine in strumLines.members) strumLine.vocals.pause();
		} else {
			FlxG.sound.music.play(true, Conductor.songPosition + Conductor.songOffset);
			vocals.play(true, FlxG.sound.music.getActualTime());
			for (strumLine in strumLines.members) {
				strumLine.vocals.play(true, FlxG.sound.music.getActualTime());
			}
		}
	}

	function _playback_speed_raise(_) playBackSlider.value += .25;
	function _playback_speed_reset(_) playBackSlider.value = 1;
	function _playback_speed_lower(_) playBackSlider.value -= .25;

	function _playback_metronome(t) {
		t.icon = (Options.charterMetronomeEnabled = !Options.charterMetronomeEnabled) ? 1 : 0;
	}
	function _song_muteinst(t) {
		FlxG.sound.music.volume = FlxG.sound.music.volume > 0 ? 0 : 1;
		t.icon = 1 - Std.int(Math.ceil(FlxG.sound.music.volume));
	}
	function _song_mutevoices(t) {
		vocals.volume = vocals.volume > 0 ? 0 : 1;
		for (strumLine in strumLines.members) strumLine.vocals.volume = strumLine.vocals.volume > 0 ? 0 : 1;
		t.icon = 1 - Std.int(Math.ceil(vocals.volume));
	}
	function _playback_back(_) {
		if (FlxG.sound.music.playing) return;
		Conductor.songPosition -= (Conductor.beatsPerMeasure * __crochet);
	}
	function _playback_forward(_) {
		if (FlxG.sound.music.playing) return;
		Conductor.songPosition += (Conductor.beatsPerMeasure * __crochet);
	}
	function _playback_section_start(_) {
		if(FlxG.sound.music.playing) return;
		Conductor.songPosition = (Conductor.beatsPerMeasure * (60000 / Conductor.bpm)) * curMeasure;
	}
	function _playback_back_step(_) {
		if (FlxG.sound.music.playing) return;
		Conductor.songPosition -= Conductor.stepCrochet;
	}
	function _playback_forward_step(_) {
		if (FlxG.sound.music.playing) return;
		Conductor.songPosition += Conductor.stepCrochet;
	}
	function _song_start(_) {
		if (FlxG.sound.music.playing) return;
		Conductor.songPosition = 0;
	}
	function _song_end(_) {
		if (FlxG.sound.music.playing) return;
		Conductor.songPosition = FlxG.sound.music.length;
	}

	function _opponent_camera_add(_) addEventAtCurrentStep("Camera Movement", [0], !FlxG.keys.pressed.ALT, !FlxG.keys.pressed.SHIFT);
	function _player_camera_add(_) addEventAtCurrentStep("Camera Movement", [1], !FlxG.keys.pressed.ALT, !FlxG.keys.pressed.SHIFT);

	function addEventAtCurrentStep(name:String, params:Array<Dynamic>, shouldGlobal:Bool = true, shouldQuant:Bool = false) {
		var step:Float = (shouldQuant ? quantStep(curStepFloat) : curStepFloat);
		var __event:CharterEvent = new CharterEvent(step, [{
			name: name,
			params: params,
			time: Conductor.getTimeForStep(step)
		}], shouldGlobal);

		__event.refreshEventIcons();
		(__event.global ? rightEventsGroup : leftEventsGroup).add(__event);
		undos.addToUndo(CEditEvent(__event, [], __event.events));
	}

	public function getBookmarkList():Array<ChartBookmark> {
		var bookmarks:Array<ChartBookmark> = [];
		try {
			if (PlayState.SONG.bookmarks != null)
				bookmarks = PlayState.SONG.bookmarks;
		} catch (e) {}
		
		return bookmarks;
	}

	function _bookmarks_add(_) {
		var addBookmarkAt = function(name:String, color:FlxColor, daStep:Float)
		{
			var currentBookmarks:Array<ChartBookmark> = getBookmarkList();
			var newBookmarks:Array<ChartBookmark> = getBookmarkList();
			newBookmarks.push({time: daStep, name: name, color: color.toWebString()});
				
			PlayState.SONG.bookmarks = newBookmarks;
			updateBookmarks();	
			undos.addToUndo(CEditBookmarks(currentBookmarks, newBookmarks));
		}

		if (FlxG.keys.pressed.SHIFT)
			addBookmarkAt(translate("bookmarks.newBookmarkName"), 0xFF911DD9, curStepFloat);
		else {
			FlxG.state.openSubState(new CharterBookmarkCreation(curStepFloat, (success, n, c, s) ->  {
				if (success)
					addBookmarkAt(n, c, s);
			}));
		}
	}

	function _bookmarks_edit_list(_)
		FlxG.state.openSubState(new CharterBookmarkList()); //idk why its FlxG.state but it looks so off lmfao

	public var __bookmarkObjects:Array<Dynamic> = [];
	public var __scrollbarBookmarks:Array<Dynamic> = [];
	public function updateBookmarks()
	{
		for (bs in __bookmarkObjects)
		{
			var bars:Array<FlxSprite> = bs[0];
			var text:UIText = bs[1];
			
			if (bars != null) {
				for (spr in bars) {
					if (spr == null) continue;
					charterBookmarksGroup.remove(spr);
					spr.kill();
				}
			}
			if (text != null) {
				charterBookmarksGroup.remove(text);
				text.kill();
			}
		}
		for (bar in __scrollbarBookmarks) {
			if (bar == null) continue;
			uiGroup.remove(bar);
			bar.kill();
		}
 		__bookmarkObjects.clear();
		__scrollbarBookmarks.clear();
		for (b in getBookmarkList())
		{
			var bookmarkcolor:FlxColor = b.color != null ? FlxColor.fromString(b.color) : 0xff9d00ff;
			var luminance = CoolUtil.getLuminance(bookmarkcolor);

			var sprites = [];
			for (str in strumLines.members)
			{
				var bookmarkspr = new FlxSprite(str.x, (b.time * 40)).makeSolid(str.keyCount * 40, 4, bookmarkcolor);
				bookmarkspr.updateHitbox();
				charterBookmarksGroup.add(bookmarkspr);
				sprites.push(bookmarkspr);
			}

			var bookmarkText = new UIText(strumLines.members[0].x + 4, 0, 400, b.name, 15, bookmarkcolor, true);
			bookmarkText.y = sprites[0].y - (bookmarkText.height + 2);
			charterBookmarksGroup.add(bookmarkText);

			if (luminance < 0.5)
				bookmarkText.borderColor = 0x88FFFFFF;

			__bookmarkObjects.push([sprites, bookmarkText]);

			var yPos = scrollBar.y + CoolUtil.bound(
				FlxMath.remapToRange(
					b.time,
					0,
					scrollBar.length + scrollBar.size,
					0,
					scrollBar.height
				),
				0,
				scrollBar.height
			);
			
			var bookmarkspr = new FlxSprite(scrollBar.x - 10, yPos).makeSolid(40, 4, bookmarkcolor);
			uiGroup.add(bookmarkspr);
			sprites.push(bookmarkspr);
			__scrollbarBookmarks.push(bookmarkspr);
		}

		buildSongUI();
	}

	function buildSongUI():Array<UIContextMenuOption> {
		var songTopButton:UITopMenuButton = topMenuSpr == null ? null : cast topMenuSpr.members[songIndex];
		var newChilds:Array<UIContextMenuOption> = [
			{
				label: translate("song.goStart"),
				keybind: [HOME],
				onSelect: _song_start
			},
			{
				label: translate("song.goEnd"),
				keybind: [END],
				onSelect: _song_end
			},
			null,
			{
				label: translate("song.addOpponentCamera"),
				keybinds: [[O], [O, SHIFT], [O, ALT]],
				onSelect: _opponent_camera_add
			},
			{
				label: translate("song.addPlayerCamera"),
				keybinds: [[P], [P, SHIFT], [P, ALT]],
				onSelect: _player_camera_add
			},
			null,
			{
				label: translate("bookmarks.addBookmarkHere"),
				onSelect: _bookmarks_add
			},
			{
				label: translate("bookmarks.editBookmarkList"),
				color: 0xFF959829, icon: 4,
				onCreate: function (button:UIContextMenuOptionSpr) {button.label.offset.x = button.icon.offset.x = -2; button.icon.offset.y = -1;},
				onSelect: _bookmarks_edit_list
			},
			null
		];

		var bookmarks:Array<ChartBookmark> = getBookmarkList();

		if (bookmarks.length > 0)
		{
			var goToBookmark = TU.getRaw("charter.bookmarks.goTo");
			for (b in bookmarks)
			{
				newChilds.push({
					label: goToBookmark.format([b.name]),
					onSelect: function(_) { Conductor.songPosition = Conductor.getTimeForStep(b.time); }
				});
			}
			newChilds.push(null);
		}

		
		newChilds.push({
			label: translate("song.muteInst"),
			onSelect: _song_muteinst
		});

		newChilds.push({
			label: translate("song.muteVoices"),
			onSelect: _song_mutevoices
		});

		if (songTopButton != null) songTopButton.contextMenu = newChilds;
		return newChilds;
	}

	function _view_zoomin(_) {
		zoom += 0.25;
		__camZoom = Math.pow(2, zoom);
	}
	function _view_zoomout(_) {
		zoom -= 0.25;
		__camZoom = Math.pow(2, zoom);
	}
	function _view_zoomreset(_) {
		zoom = 0;
		__camZoom = Math.pow(2, zoom);
	}
	function _view_showeventSecSeparator(t) {
		t.icon = (Options.charterShowSections = !Options.charterShowSections) ? 1 : 0;
	}
	function _view_showeventBeatSeparator(t) {
		t.icon = (Options.charterShowBeats = !Options.charterShowBeats) ? 1 : 0;
	}
	function _view_switchWaveformRainbow(t) {
		t.icon = (Options.charterRainbowWaveforms = !Options.charterRainbowWaveforms) ? 1 : 0;

		waveformHandler.clearWaveforms();
		updateWaveforms();
	}
	function _view_switchWaveformDetail(t) {
		t.icon = (Options.charterLowDetailWaveforms = !Options.charterLowDetailWaveforms) ? 1 : 0;
		for (shader in waveformHandler.waveShaders) shader.data.lowDetail.value = [Options.charterLowDetailWaveforms];
	}

	function _view_scrollleft(_) {
		sideScroll -= 40;
	}
	function _view_scrollright(_) {
		sideScroll += 40;
	}
	function _view_scrollreset(_) {
		sideScroll = 0;
	}

	inline function _snap_increasesnap(_) changequant(1);
	inline function _snap_decreasesnap(_) changequant(-1);
	inline function _snap_resetsnap(_) setquant(16);

	inline function changequant(change:Int) {FlxG.sound.play(Paths.sound(Flags.DEFAULT_CHARTER_SNAPPINGCHANGE_SOUND)); quant = quants[FlxMath.wrap(quants.indexOf(quant) + change, 0, quants.length-1)]; buildSnapsUI();};
	inline function setquant(newQuant:Int) {FlxG.sound.play(Paths.sound(Flags.DEFAULT_CHARTER_SNAPPINGCHANGE_SOUND)); quant = newQuant; buildSnapsUI();}

	function buildSnapsUI():Array<UIContextMenuOption> {
		var snapsTopButton:UITopMenuButton = topMenuSpr == null ? null : cast topMenuSpr.members[snapIndex];
		var newChilds:Array<UIContextMenuOption> = [
			{
				label: translate("snap.increaseSnap"),
				keybind: [X],
				onSelect: _snap_increasesnap
			},
			{
				label: translate("snap.resetSnap"),
				onSelect: _snap_resetsnap
			},
			{
				label: translate("snap.decreaseSnap"),
				keybind: [Z],
				onSelect: _snap_decreasesnap
			},
			null
		];

		var snapStr = TU.getRaw("charter.snap.snap");

		for (_quant in quants)
			newChilds.push({
				label: snapStr.format([_quant]),
				onSelect: (_) -> {setquant(_quant); buildSnapsUI();},
				icon: _quant == quant ? 1 : 0
			});

		if (snapsTopButton != null) snapsTopButton.contextMenu = newChilds;
		return newChilds;
	}

	inline function _note_addsustain(t) {
		FlxG.sound.play(Paths.sound(Flags.DEFAULT_CHARTER_SUSTAINADD_SOUND));
		changeNoteSustain(1);
	}

	inline function _note_subtractsustain(t) {
		FlxG.sound.play(Paths.sound(Flags.DEFAULT_CHARTER_SUSTAINDELETE_SOUND));
		changeNoteSustain(-1);
	}

	function _note_selectall(_) {
		selection = cast notesGroup.members.copy();
	}

	function _note_selectmeasure(_) {
		selection = [for (note in notesGroup.members)
			if (note.step > Conductor.curMeasure*Conductor.getMeasureLength() && note.step < (Conductor.curMeasure+1)*Conductor.getMeasureLength()) note
		];
	}
	#end

	function changeNoteSustain(change:Float) {
		if (selection.length <= 0 || change == 0 || gridActionType != NONE) return;

		var undoChanges:Array<NoteSustainChange> = [];
		for(s in selection)
			if (s is CharterNote) {
				var n:CharterNote = cast s;
				var old:Float = n.susLength;
				n.updatePos(n.step, n.id, Math.max(n.susLength + change, 0), n.type);
				undoChanges.push({before: old, after: n.susLength, note: n});
			}

		undos.addToUndo(CEditSustains(undoChanges));
	}

	inline public function changeNoteType(?newID:Int, checkSelection:Bool = true) {
		if(newID != null) noteType = newID;
		noteType = CoolUtil.boundInt(noteType, 0, noteTypes.length);
		buildNoteTypesUI();

		var changedNotes:{notes:Array<CharterNote>, oldTypes:Array<Int>, newTypes:Array<Int>} = {notes:[], oldTypes:[], newTypes:[]};
		for(note in notesGroup) if(note.type < 0 || note.type > noteTypes.length) {
			changedNotes.notes.push(note); changedNotes.oldTypes.push(note.type); changedNotes.newTypes.push(0);
			note.updatePos(note.step, note.id, note.susLength, 0);
		}

		if(checkSelection) for(s in selection)
			if (s is CharterNote) {
				var n:CharterNote = cast s;
				changedNotes.notes.push(n); changedNotes.oldTypes.push(n.type); changedNotes.newTypes.push(newID);
				n.updatePos(n.step, n.id, n.susLength, newID);
			}
		if(changedNotes.notes.length > 0) undos.addToUndo(CEditSpecNotesType(changedNotes.notes, changedNotes.oldTypes, changedNotes.newTypes));
	}

	function editNoteTypesList(_)
		FlxG.state.openSubState(new CharterNoteTypesList());

	function buildNoteTypesUI():Array<UIContextMenuOption> {
		var noteTopButton:UITopMenuButton = topMenuSpr == null ? null : cast topMenuSpr.members[noteIndex];
		var newChilds:Array<UIContextMenuOption> = [
			{
				label: translate("note.addSustainLength"),
				keybind: [E],
				onSelect: _note_addsustain
			},
			{
				label: translate("note.subtractSustainLength"),
				keybind: [Q],
				onSelect: _note_subtractsustain
			},
			null,
			{
				label: translate("note.selectAll"),
				keybind: [CONTROL, A],
				onSelect: _note_selectall
			},
			{
				label: translate("note.selectMeasure"),
				keybind: [CONTROL, SHIFT, A],
				onSelect: _note_selectmeasure
			},
			null,
			{
				label: "(0) " + translate("noteTypes.default"),
				keybind: [ZERO],
				onSelect: (_) -> {changeNoteType(0);},
				icon: this.noteType == 0 ? 1 : 0
			}
		];

		var noteKeys:Array<FlxKey> = [ZERO, ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE];
		for (i=>type in noteTypes) {
			var realNoteID:Int = i+1; // Default Note not stored
			var newChild:UIContextMenuOption = {
				// TODO: make this translatable?
				label: '(${realNoteID}) ${type}',
				onSelect: (_) -> {changeNoteType(realNoteID);},
				icon: this.noteType == realNoteID ? 1 : 0
			};
			if (realNoteID <= 9) newChild.keybind = [noteKeys[realNoteID]];
			newChilds.push(newChild);
		}
		newChilds.push({
			label: translate("note.editNoteTypesList"),
			color: 0xFF959829, icon: 4,
			onCreate: function (button:UIContextMenuOptionSpr) {button.label.offset.x = button.icon.offset.x = -2;},
			onSelect: editNoteTypesList
		});
		if (noteTopButton != null) noteTopButton.contextMenu = newChilds;
		return newChilds;
	}

	public function playtestChart(time:Float = 0, opponentMode = false, here = false) {
		buildChart();
		startHere = here;
		startTime = Conductor.songPosition;
		PlayState.opponentMode = opponentMode;
		PlayState.chartingMode = true;
		FlxG.switchState(new PlayState());
	}

	public inline function buildNote(note:CharterNote):ChartNote {
		var time = Conductor.getTimeForStep(note.step);
		return {
			type: note.type,
			time: time,
			sLen: Conductor.getTimeForStep(note.step + note.susLength) - time,
			id: note.id
		};
	}

	public function buildChart() {
		PlayState.SONG.strumLines = [];
		PlayState.SONG.noteTypes = this.noteTypes;
		PlayState.SONG.chartVersion = Chart.version;
		for(s in strumLines) {
			s.strumLine.notes = [];
			PlayState.SONG.strumLines.push(s.strumLine);
		}
		notesGroup.sortNotes();
		for(n in notesGroup.members) {
			if (PlayState.SONG.strumLines[n.strumLineID] != null)
				PlayState.SONG.strumLines[n.strumLineID].notes.push(buildNote(n));
		}
		buildEvents();
	}

	public function buildEvents() {
		PlayState.SONG.events = [];

		for (ce in leftEventsGroup.members) for (e in ce.events) e.global = false;
		for (ce in rightEventsGroup.members) for (e in ce.events) e.global = true;

		var events:Array<CharterEvent> = leftEventsGroup.members.concat(rightEventsGroup.members);
		events.sort(rightEventsGroup.sortEventsFilter.bind(FlxSort.ASCENDING));
		for (e in events) for (event in e.events) {
			event.time = Conductor.getTimeForStep(e.step);
			PlayState.SONG.events.push(event);
		}
	}

	public function updateBPMEvents() {
		leftEventsGroup.sortEvents();
		rightEventsGroup.sortEvents();
		Conductor.mapCharterBPMChanges(PlayState.SONG);
		buildEvents();

		for(e in leftEventsGroup.members) {
			for(event in e.events) {
				if (event.name == "BPM Change" || event.name == "Time Signature Change" || event.name == "Continuous BPM Change") {
					e.refreshEventIcons();
					break;
				}
			}
		}

		for(e in rightEventsGroup.members) {
			for(event in e.events) {
				if (event.name == "BPM Change" || event.name == "Time Signature Change" || event.name == "Continuous BPM Change") {
					e.refreshEventIcons();
					break;
				}
			}
		}

		refreshBPMSensitive();
	}

	public inline function checkSelectionForBPMUpdates() {
		for (s in selection)
			if (s is CharterEvent) {
				updateBPMEvents();
				break;
			}
	}

	public inline function hitsoundsEnabled(id:Int)
		return strumLines.members[id] != null && strumLines.members[id].hitsounds;

	public inline function __fixSelection(selection:Selection):Selection {
		var newSelection:Selection = new Selection();
		for (s in selection) newSelection.pushOnce(s);
		return newSelection.filter((s:ICharterSelectable) -> {return s != null;});
	}

	// UH OH!!! DANGER ZONE APPROACHING !!!! LUNARS SHITTY CODE !!!! -lunar

	@:noCompletion public function __relinkSingleSelection(selectable:ICharterSelectable):ICharterSelectable {
		if (selectable is CharterNote)
			return selectable.ID == -1 ? cast(selectable, CharterNote) : notesGroup.members[selectable.ID];
		else if (selectable is CharterEvent) {
			var event:CharterEvent = cast(selectable, CharterEvent);
			return selectable.ID == -1 ? event : (event.global ? rightEventsGroup : leftEventsGroup).members[selectable.ID];
		}
		return null;
	}

	@:noCompletion public function __relinkSelection(selection:Selection) @:privateAccess {
		var newSelection:Selection = new Selection();
		for (i => selectable in selection)
			newSelection[i] = __relinkSingleSelection(selectable);
		return newSelection;
	}

	@:noCompletion public inline function __relinkUndos() {
		selection = __relinkSelection(selection);

		for (list => changeList in [undos.undoList, undos.redoList]) {
			var newChanges:Array<CharterChange> = [];
			for (i => change in changeList) {
				switch (change) {
					case CCreateSelection(selection):
						newChanges[i] = CCreateSelection(__relinkSelection(selection));
					case CDeleteSelection(selection):
					 	newChanges[i] = CDeleteSelection(__relinkSelection(selection));
					case CSelectionDrag(selectionDrags):
						newChanges[i] = CSelectionDrag([
							for (selectionDrag in selectionDrags)
								{
									selectable: __relinkSingleSelection(selectionDrag.selectable),
									change: selectionDrag.change
								}
						]);
					case CEditSustains(noteChanges):
						newChanges[i] = CEditSustains([
							for (noteChange in noteChanges)
								{
									note: cast(__relinkSingleSelection(noteChange.note), CharterNote),
									before: noteChange.before,
									after: noteChange.after
								}
						]);
					case CEditEvent(event, oldEvents, newEvents):
						newChanges[i] = CEditEvent(cast(__relinkSingleSelection(event), CharterEvent), oldEvents, newEvents);
					case CEditSpecNotesType(notesChanged, oldNoteTypes, newNoteTypes):
						newChanges[i] = CEditSpecNotesType([
							for (noteChanged in notesChanged)
								cast(__relinkSingleSelection(noteChanged), CharterNote)
						], oldNoteTypes, newNoteTypes);
					default: newChanges[i] = change;
				}
			}

			if (list == 0) undos.undoList = newChanges;
			else undos.redoList = newChanges;
		}
	}

	@:noCompletion public function __resetStatics() {
		selection = new Selection();
		undos = new UndoList<CharterChange>();
		clipboard = []; playtestInfo = null;
		waveformHandler = new CharterWaveformHandler();
		autoSaveTimer = Options.charterAutoSaveTime;
	}

	@:noCompletion public function __clearStatics() {
		selection = null; undos = null; clipboard = null; playtestInfo = null;
		waveformHandler.destroy(); Charter.waveformHandler = null; autoSaveTimer = 0;
	}

	@:noCompletion public function __updatePlaytestInfo() {
		playtestInfo = {
			songPosition: Conductor.songPosition,
			playbackSpeed: playBackSlider.value,
			quantSelected: quant,
			noteTypeSelected: noteType,
			strumlinesDraggable: strumLines.draggable,
			hitSounds: [for (strumLine in strumLines.members) strumLine.hitsounds],
			mutedVocals: [for (strumLine in strumLines.members) !(strumLine.vocals.volume > 0)],
			waveforms: [for (strumLine in strumLines.members) strumLine.selectedWaveform]
		}
	}

	@:noCompletion public function __applyPlaytestInfo() {
		if (playtestInfo == null) return;

		Conductor.songPosition = playtestInfo.songPosition;
		playBackSlider.value = playtestInfo.playbackSpeed;
		quant = playtestInfo.quantSelected;
		noteType = playtestInfo.noteTypeSelected;
		strumLines.draggable = playtestInfo.strumlinesDraggable;

		for (i => strumLine in strumLines.members)
			strumLine.hitsounds = playtestInfo.hitSounds[i];
		for (i => strumLine in strumLines.members)
			strumLine.vocals.volume = playtestInfo.mutedVocals[i] ? 0 : 1;
		for (i => strumLine in strumLines.members)
			strumLine.selectedWaveform = playtestInfo.waveforms[i];
	}
}

enum CharterChange {
	CCreateStrumLine(strumLineID:Int, strumLine:ChartStrumLine);
	CEditStrumLine(strumLineID:Int, oldStrumLine:ChartStrumLine, newStrumLine:ChartStrumLine);
	COrderStrumLine(strumLineID:Int, oldID:Int, newID:Int);
	CDeleteStrumLine(strumLineID:Int, strumLine:ChartStrumLine);
	CCreateSelection(selection:Selection);
	CDeleteSelection(selection:Selection);
	CSelectionDrag(selectionDrags:Array<SelectionDragChange>);
	CEditSustains(notes:Array<NoteSustainChange>);
	CEditEvent(event:CharterEvent, oldEvents:Array<ChartEvent>, newEvents:Array<ChartEvent>);
	CEditEventGroups(events:Array<CharterEvent>);
	CEditChartData(oldData:{stage:String, speed:Float}, newData:{stage:String, speed:Float});
	CEditNoteTypes(oldArray:Array<String>, newArray:Array<String>);
	CEditBookmarks(oldArray:Array<ChartBookmark>, newArray:Array<ChartBookmark>);
	CEditSpecNotesType(notes:Array<CharterNote>, oldNoteTypes:Array<Int>, newNoteTypes:Array<Int>);

	CChangeBundle(changes:Array<CharterChange>);
}

enum CharterCopyboardObject {
	CNote(step:Float, id:Int, strumLineID:Int, susLength:Float, type:Int);
	CEvent(step:Float, events:Array<ChartEvent>, global:Bool);
}

typedef NoteSustainChange = {
	var note:CharterNote;
	var before:Float;
	var after:Float;
}

typedef SelectionDragChange = {
	var selectable:ICharterSelectable;
	var change:FlxPoint;
}

@:forward abstract Selection(Array<ICharterSelectable>) from Array<ICharterSelectable> to Array<ICharterSelectable> {
	public inline function new(?array:Array<ICharterSelectable>)
		this = array == null ? [] : array;

	// too lazy to put this in every for loop so i made it a abstract
	public inline function loop(onNote:CharterNote->Void, ?onEvent:CharterEvent->Void, ?draggableOnly:Bool = true) {
		for (s in this) {
			if (s is CharterNote && onNote != null && (draggableOnly ? s.draggable: true))
				onNote(cast s);
			else if (s is CharterEvent && onEvent != null && (draggableOnly ? s.draggable: true))
				onEvent(cast s);
		}
	}
}

interface ICharterSelectable {
	public var x(default, set):Float;
	public var y(default, set):Float;
	public var ID:Int;
	public var step:Float;

	public var selected:Bool;
	public var hovered:Bool;
	public var draggable:Bool;
	public var snappedToGrid:Bool;

	public function handleSelection(selectionBox:UISliceSprite):Bool;
	public function handleDrag(change:FlxPoint):Void;
}

enum abstract CharterGridActionType(Int) {
	var NONE = 0;
	var BOX_SELECTION = 1;
	var NOTE_DRAG = 2;
	var INVALID_DRAG = 3;
	var SUSTAIN_DRAG = 4;
	var DELETE_SELECTION = 5;
}

typedef PlaytestInfo = {
	var songPosition:Float;
	var playbackSpeed:Float;
	var quantSelected:Int;
	var noteTypeSelected:Int;
	var strumlinesDraggable:Bool;
	var hitSounds:Array<Bool>;
	var mutedVocals:Array<Bool>;
	var waveforms:Array<Int>;
}
