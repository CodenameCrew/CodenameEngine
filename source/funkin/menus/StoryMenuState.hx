package funkin.menus;

import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.OneOfTwo;
import funkin.backend.FunkinText;
import funkin.backend.scripting.events.*;
import funkin.backend.week.*;
import funkin.savedata.FunkinSave;
import haxe.io.Path;

class StoryMenuState extends MusicBeatState {
	public var characters:Map<String, WeekData.WeekCharacter> = [];
	public var weeks:Array<WeekData> = [];
	public var weekList:StoryWeeklist;

	public var scoreText:FlxText;
	public var tracklist:FlxText;
	public var weekTitle:FlxText;

	public var curDifficulty:Int = 0;
	public var curWeek:Int = 0;

	public var difficultySprites:Map<String, FlxSprite> = [];
	public var weekBG:FlxSprite;
	public var leftArrow:FlxSprite;
	public var rightArrow:FlxSprite;
	public var blackBar:FlxSprite;

	public var lerpScore:Float = 0;
	public var intendedScore:Int = 0;

	public var canSelect:Bool = true;

	public var weekSprites:FlxTypedGroup<MenuItem>;
	public var characterSprites:FlxTypedGroup<MenuCharacterSprite>;

	//public var charFrames:Map<String, FlxFramesCollection> = [];

	public override function create() {
		super.create();
		loadXMLs();
		persistentUpdate = persistentDraw = true;

		// WEEK INFO
		blackBar = new FlxSprite(0, 0).makeSolid(FlxG.width, 56, 0xFFFFFFFF);
		blackBar.color = 0xFF000000;
		blackBar.updateHitbox();

		scoreText = new FunkinText(10, 10, 0, "SCORE: -", 36);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32);

		weekTitle = new FlxText(10, 10, FlxG.width - 20, "", 32);
		weekTitle.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		weekTitle.alpha = 0.7;

		weekBG = new FlxSprite(0, 56).makeSolid(FlxG.width, 400, 0xFFFFFFFF);
		weekBG.color = 0xFFF9CF51;
		weekBG.updateHitbox();

		weekSprites = new FlxTypedGroup<MenuItem>();

		// DUMBASS ARROWS
		var assets = Paths.getFrames('menus/storymenu/assets');
		var directions = ["left", "right"];

		leftArrow = new FlxSprite((FlxG.width + 400) / 2, weekBG.y + weekBG.height + 10 + 10);
		rightArrow = new FlxSprite(FlxG.width - 10, weekBG.y + weekBG.height + 10 + 10);
		for(k=>arrow in [leftArrow, rightArrow]) {
			var dir = directions[k];

			arrow.frames = assets;
			arrow.animation.addByPrefix('idle', 'arrow $dir');
			arrow.animation.addByPrefix('press', 'arrow push $dir', 24, false);
			arrow.animation.play('idle');
			arrow.antialiasing = true;
			add(arrow);
		}
		rightArrow.x -= rightArrow.width;

		tracklist = new FunkinText(16, weekBG.y + weekBG.height + 44, Std.int(((FlxG.width - 400) / 2) - 80), "TRACKS", 32);
		tracklist.alignment = CENTER;
		tracklist.color = 0xFFE55777;

		add(weekSprites);
		for (e in [blackBar, scoreText, weekTitle, weekBG, tracklist]) {
			e.scrollFactor.set();
			add(e);
		}

		characterSprites = new FlxTypedGroup<MenuCharacterSprite>();
		for (i in 0...3) characterSprites.add(new MenuCharacterSprite(i));
		add(characterSprites);

		for (i=>week in weeks) {
			var spr:MenuItem = new MenuItem(0, (i * 120) + 480, 'menus/storymenu/weeks/${week.sprite}');
			weekSprites.add(spr);

			for (e in week.difficulties) {
				var le = e.toLowerCase();
				if (difficultySprites[le] == null) {
					var diffSprite = new FlxSprite(leftArrow.x + leftArrow.width, leftArrow.y);
					diffSprite.loadAnimatedGraphic(Paths.image('menus/storymenu/difficulties/${le}'));
					diffSprite.setUnstretchedGraphicSize(Std.int(rightArrow.x - leftArrow.x - leftArrow.width), Std.int(leftArrow.height), false, 1);
					diffSprite.antialiasing = true;
					diffSprite.scrollFactor.set();
					add(diffSprite);

					difficultySprites[le] = diffSprite;
				}
			}
		}

		// default difficulty should be the middle difficulty in the array
		// to be consistent with base game and whatnot, you know the drill
		curDifficulty = Math.floor(weeks[0].difficulties.length * 0.5);
		// debug stuff lol
		Logs.trace('Middle Difficulty for Week 1 is ${weeks[0].difficulties[curDifficulty]} (ID: $curDifficulty)');

		changeWeek(0, true);

		DiscordUtil.call("onMenuLoaded", ["Story Menu"]);
		CoolUtil.playMenuSong();
	}

	var __lastDifficultyTween:FlxTween;
	public override function update(elapsed:Float) {
		super.update(elapsed);

		lerpScore = lerp(lerpScore, intendedScore, 0.5);
		scoreText.text = 'WEEK SCORE:${Math.round(lerpScore)}';

		if (canSelect) {
			if (leftArrow != null && leftArrow.exists) leftArrow.animation.play(controls.LEFT ? 'press' : 'idle');
			if (rightArrow != null && rightArrow.exists) rightArrow.animation.play(controls.RIGHT ? 'press' : 'idle');

			if (controls.BACK) {
				goBack();
			}

			changeDifficulty((controls.LEFT_P ? -1 : 0) + (controls.RIGHT_P ? 1 : 0));
			changeWeek((controls.UP_P ? -1 : 0) + (controls.DOWN_P ? 1 : 0) - FlxG.mouse.wheel);

			if (controls.ACCEPT)
				selectWeek();
		} else {
			for(e in [leftArrow, rightArrow])
				if (e != null && e.exists)
					e.animation.play('idle');
		}
	}

	public function goBack() {
		var event = event("onGoBack", new CancellableEvent());
		if (!event.cancelled)
			FlxG.switchState(new MainMenuState());
	}

	public function changeWeek(change:Int, force:Bool = false) {
		if (change == 0 && !force) return;

		var event = event("onChangeWeek", EventManager.get(MenuChangeEvent).recycle(curWeek, FlxMath.wrap(curWeek + change, 0, weeks.length-1), change));
		if (event.cancelled) return;
		curWeek = event.value;

		if (!force) CoolUtil.playMenuSFX();
		for(k=>e in weekSprites.members) {
			e.targetY = k - curWeek;
			e.alpha = k == curWeek ? 1.0 : 0.6;
		}
		tracklist.text = 'TRACKS\n\n${[for(e in weeks[curWeek].songs) if (!e.hide) e.displayName.getDefault(e.name).toUpperCase()].join('\n')}';
		weekTitle.text = weeks[curWeek].name.getDefault("");

		for (i in 0...3) {
			var char = weeks[curWeek].chars[i];  // will use the characters map in any case since a map is for sure easier to edit for mods, we didnt load characters by default anyways  - Nex
			characterSprites.members[i].changeCharacter(char == null ? null : characters[char.name]);
		}

		changeDifficulty(0, true);

		MemoryUtil.clearMinor();
	}

	var __oldDiffName = null;
	public function changeDifficulty(change:Int, force:Bool = false) {
		if (change == 0 && !force) return;

		var event = event("onChangeDifficulty", EventManager.get(MenuChangeEvent).recycle(curDifficulty, FlxMath.wrap(curDifficulty + change, 0, weeks[curWeek].difficulties.length-1), change));
		if (event.cancelled) return;
		curDifficulty = event.value;

		if (__oldDiffName != (__oldDiffName = weeks[curWeek].difficulties[curDifficulty].toLowerCase())) {
			for(e in difficultySprites) e.visible = false;

			var diffSprite = difficultySprites[__oldDiffName];
			if (diffSprite != null) {
				diffSprite.visible = true;

				if (__lastDifficultyTween != null)
					__lastDifficultyTween.cancel();
				diffSprite.alpha = 0;
				diffSprite.y = leftArrow.y - 15;

				__lastDifficultyTween = FlxTween.tween(diffSprite, {y: leftArrow.y, alpha: 1}, 0.07);
			}
		}

		intendedScore = FunkinSave.getWeekHighscore(weeks[curWeek].id, weeks[curWeek].difficulties[curDifficulty]).score;
	}

	public function loadXMLs() {
		weekList = StoryWeeklist.get(true, false);  // will only load week files AND NOT characters too (we will load them later only if needed)!!  - Nex
		weeks = weekList.weeks;
		for (week in weeks) for (char in week.chars) if (char != null)
			addCharacter(char.name);
	}

	public function addCharacter(char:OneOfTwo<String, WeekData.WeekCharacter>) {
		// better to use unsafe casts for going fast  - Nex
		var charObj:WeekData.WeekCharacter = null;
		var charName:String;

		charName = char is String ? cast char : (charObj = cast char).name;
		if (characters[charName] != null) return;  // will load only if it can be saved inside the map  - Nex
		characters[charName] = charObj == null ? Week.loadWeekCharacter(charName) : charObj;
	}

	public override function destroy() {
		super.destroy();
		for (e in characters)
			if (e != null && e.offset != null)
				e.offset.put();
	}

	public function selectWeek() {
		var event = event("onWeekSelect", EventManager.get(WeekSelectEvent).recycle(weeks[curWeek], weeks[curWeek].difficulties[curDifficulty], curWeek, curDifficulty));
		if (event.cancelled) return;

		canSelect = false;
		CoolUtil.playMenuSFX(CONFIRM);

		for(char in characterSprites)
			if (char.animation.exists("confirm"))
				char.animation.play("confirm");

		PlayState.loadWeek(event.week, event.difficulty);

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			FlxG.switchState(new PlayState());
		});
		weekSprites.members[event.weekID].startFlashing();
	}
}

class MenuCharacterSprite extends FlxSprite
{
	public var character:String;

	var pos:Int;

	public function new(pos:Int) {
		super(0, 70);
		this.pos = pos;
		visible = false;
		antialiasing = true;
	}

	public var oldChar:WeekData.WeekCharacter = null;

	public function changeCharacter(data:WeekData.WeekCharacter) {
		if (!(visible = (data != null && data.xml != null))) return;

		if (oldChar != (oldChar = data)) {
			CoolUtil.loadAnimatedGraphic(this, data.spritePath);
			for (e in data.xml.nodes.anim) {
				if (e.getAtt("name") == "idle") animation.remove("idle");
				XMLUtil.addXMLAnimation(this, e);
			}
			animation.play("idle");
			scale.set(data.scale, data.scale);
			updateHitbox();
			offset.x += data.offset.x;
			offset.y += data.offset.y;

			x = (FlxG.width * 0.25) * (1 + pos) - 150;
		}
	}
}

class MenuItem extends FlxSprite
{
	public var targetY:Float = 0;

	public function new(x:Float, y:Float, path:String)
	{
		super(x, y);
		CoolUtil.loadAnimatedGraphic(this, Paths.image(path, null, true));
		screenCenter(X);
		antialiasing = true;
	}

	private var isFlashing:Bool = false;

	public function startFlashing():Void
	{
		isFlashing = true;
	}

	// if it runs at 60fps, fake framerate will be 6
	// if it runs at 144 fps, fake framerate will be like 14, and will update the graphic every 0.016666 * 3 seconds still???
	// so it runs basically every so many seconds, not dependant on framerate??
	// I'm still learning how math works thanks whoever is reading this lol
	// var fakeFramerate:Int = Math.round((1 / FlxG.elapsed) / 10);

	// hi ninja muffin
	// i have found a more efficient way
	// dw, judging by how week 7 looked you prob know how to do maths
	// goodbye
	var time:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		time += elapsed;
		y = CoolUtil.fpsLerp(y, (targetY * 120) + 480, 0.17);

		if (isFlashing)
			color = (time % 0.1 > 0.05) ? FlxColor.WHITE : 0xFF33ffff;
	}
}

class StoryWeeklist {
	public var weeks:Array<WeekData> = [];

	public function new() {}

	public function getWeeksFromSource(source:funkin.backend.assets.AssetsLibraryList.AssetSource, useTxt:Bool = true, loadCharactersData:Bool = true) {
		var path:String = Paths.txt('weeks/weeks');
		var weeksFound:Array<String> = useTxt && Paths.assetsTree.existsSpecific(path, "TEXT", source) ? CoolUtil.coolTextFile(path) :
			[for (c in Paths.getFolderContent('data/weeks/weeks/', false, source)) if (Path.extension(c).toLowerCase() == "xml") Path.withoutExtension(c)];

		if (weeksFound.length > 0) {
			for (w in weeksFound) {
				var week = Week.loadWeek(w, loadCharactersData);
				if (week != null) weeks.push(week);
			}
			return false;
		}
		return true;
	}

	public static function get(useTxt:Bool = true, loadCharactersData:Bool = true) {
		var weekList = new StoryWeeklist();

		if (weekList.getWeeksFromSource(MODS, useTxt, loadCharactersData))
			weekList.getWeeksFromSource(SOURCE, useTxt, loadCharactersData);

		return weekList;
	}
}