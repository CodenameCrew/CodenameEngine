package funkin.menus;

import funkin.backend.MusicBeatGroup;
import funkin.backend.utils.XMLUtil;
import flixel.util.typeLimit.OneOfTwo;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.Assets;
import haxe.xml.Access;

using StringTools;

@:allow(funkin.backend.assets.ModsFolder)
@:allow(funkin.backend.system.MainState)
class TitleState extends MusicBeatState
{
	static var initialized:Bool = false;
	static var hasCheckedUpdates:Bool = false;

	public var curWacky:Array<String> = [];

	public var blackScreen:FlxSprite;
	public var textGroup:FlxGroup;
	public var ngSpr:FlxSprite;

	public var wackyImage:FlxSprite;

	override public function create():Void
	{
		curWacky = FlxG.random.getObject(getIntroTextShit());

		MusicBeatState.skipTransIn = true;

		startIntro();

		super.create();

		DiscordUtil.call("onMenuLoaded", ["Title Screen"]);
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var titleScreenSprites:MusicBeatGroup;

	function startIntro()
	{
		if (!initialized)
			CoolUtil.playMenuSong(true);

		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite().makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		#if TITLESCREEN_XML
		titleScreenSprites = new MusicBeatGroup();
		add(titleScreenSprites);
		loadXML();
		#end

		if (titleText == null) {
			titleText = new FlxSprite(100, FlxG.height * 0.8);
			titleText.frames = Paths.getFrames('menus/titlescreen/titleEnter');
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
			titleText.antialiasing = true;
			titleText.animation.play('idle');
			titleText.updateHitbox();
		}
		add(titleText);

		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(blackScreen);

		#if !TITLESCREEN_XML
		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadAnimatedGraphic(Paths.image('newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = true;
		#end

		FlxG.mouse.visible = false;

		if (initialized)
			skipIntro();
		else
			initialized = true;

		add(textGroup);
	}

	public function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('titlescreen/introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.F)  FlxG.fullscreen = !FlxG.fullscreen;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
			if (touch.justPressed)
				pressedEnter = true;
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		if (pressedEnter && transitioning && skippedIntro) {
			FlxG.camera.stopFX();// FlxG.camera.visible = false;
			goToMainMenu();
		}

		if (pressedEnter && !transitioning && skippedIntro)
		{
			pressEnter();
		}

		if (pressedEnter && !skippedIntro)
			skipIntro();

		super.update(elapsed);
	}

	public function pressEnter() {
		titleText.animation.play('press');

		FlxG.camera.flash(FlxColor.WHITE, 1);
		CoolUtil.playMenuSFX(CONFIRM, 0.7);

		transitioning = true;
		// FlxG.sound.music.stop();

		new FlxTimer().start(2, (_) -> goToMainMenu());
	}

	function goToMainMenu() {
		#if UPDATE_CHECKING
		var report = hasCheckedUpdates ? null : funkin.backend.system.updating.UpdateUtil.checkForUpdates();
		hasCheckedUpdates = true;

		if (report != null && report.newUpdate) {
			FlxG.switchState(new funkin.backend.system.updating.UpdateAvailableScreen(report));
		} else {
			FlxG.switchState(new MainMenuState());
		}
		#else
		FlxG.switchState(new MainMenuState());
		#end
	}

	public function createCoolText(textArray:Array<String>)
	{
		for (i=>text in textArray)
		{
			if (text == "" || text == null) continue;
			var money:Alphabet = new Alphabet(0, (i * 60) + 200, text, true, false);
			money.screenCenter(X);
			textGroup.add(money);
		}
	}

	public function addMoreText(text:String)
	{
		var coolText:Alphabet = new Alphabet(0, (textGroup.length * 60) + 200, text, true, false);
		coolText.screenCenter(X);
		textGroup.add(coolText);
	}

	public function deleteCoolText()
	{
		while (textGroup.members.length > 0) {
			textGroup.members[0].destroy();
			textGroup.remove(textGroup.members[0], true);
		}
	}

	override function beatHit(curBeat:Int)
	{
		super.beatHit(curBeat);

		#if TITLESCREEN_XML
		if (curBeat >= titleLength || skippedIntro) {
			if (!skippedIntro) skipIntro();
			return;
		}
		var introText = titleLines[curBeat];
		if (introText != null)
			introText.show();
		#else
		switch (curBeat)
		{
			case 1:		createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
			case 3:		addMoreText('present');
			case 4:		deleteCoolText();
			case 5:		createCoolText(['In association', 'with']);
			case 7:		addMoreText('newgrounds');	ngSpr.visible = true;
			case 8:		deleteCoolText();			ngSpr.visible = false;
			case 9:		createCoolText([curWacky[0]]);
			case 11:	addMoreText(curWacky[1]);
			case 12:	deleteCoolText();
			case 13:	addMoreText('Friday');
			case 14:	addMoreText('Night');
			case 15:	addMoreText('Funkin');
			case 16:	skipIntro();
		}
		#end
	}

	#if TITLESCREEN_XML
	public var xml:Access;
	public var titleLength:Int = 16;
	public var titleLines:Map<Int, IntroText> = [
		1 => new IntroText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']),
		3 => new IntroText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er', 'present']),
		4 => new IntroText(),
		5 => new IntroText(['In association', 'with']),
		7 => new IntroText(['In association', 'with', 'newgrounds', {
			name: "newgroundsLogo",
			path: "menus/titlescreen/newgrounds_logo",
			scale: 0.8
		}]),
		8 => new IntroText(),
		9 => new IntroText(["{introText1}"]),
		11 => new IntroText(["{introText1}", "{introText2}"]),
		12 => new IntroText(),
		13 => new IntroText(['Friday']),
		14 => new IntroText(['Friday', 'Night']),
		15 => new IntroText(['Friday', 'Night', "Funkin'"]),
	];

	public function loadXML() {
		try {
			xml = new Access(Xml.parse(Assets.getText(Paths.xml('titlescreen/titlescreen'))).firstElement());
			if (xml.hasNode.intro) {
				titleLines = [];
				if (xml.node.intro.has.length) titleLength = CoolUtil.getDefault(Std.parseInt(xml.node.intro.att.length), 16);
				for(node in xml.nodes.sprites) {
					var parentFolder:String = node.getAtt("folder").getDefault("");
					if (parentFolder != "" && !parentFolder.endsWith("/")) parentFolder += "/";
					for(sprNode in node.elements) {
						var spr = XMLUtil.createSpriteFromXML(sprNode, parentFolder);
						switch(node.name) {
							case "press-enter":
								titleText = spr;
							default:
								titleScreenSprites.add(spr);
						}
					}
				}
				for(text in xml.node.intro.nodes.text) {
					var beat:Int = CoolUtil.getDefault(text.has.beat ? Std.parseInt(text.att.beat) : null, 0);
					var texts:Array<OneOfTwo<String, TitleStateImage>> = [];
					for(e in text.elements) {
						switch(e.name) {
							case "line":
								if (!e.has.text) continue;
								texts.push(e.att.text);
							case "introtext":
								if (!e.has.line) continue;
								texts.push('{introText${e.att.line}}');
							case "sprite":
								if (!e.has.path) continue;
								var name:String = e.has.name ? e.att.name : null;
								var path:String = e.att.path;
								var flipX:Bool = e.has.flipX ? e.att.flipX == "true" : false;
								var flipY:Bool = e.has.flipY ? e.att.flipY == "true" : false;
								var scale:Float = e.has.scale ? CoolUtil.getDefault(Std.parseFloat(e.att.scale), 1) : 1;
								texts.push({
									name: name,
									path: path,
									flipX: flipX,
									flipY: flipY,
									scale: scale
								});
						}
					}
					titleLines[beat] = new IntroText(texts);
				}
			}
		} catch(e) {
			Logs.trace('Failed to load titlescreen XML: $e', ERROR);
		}
	}
	#end

	var skippedIntro:Bool = false;

	public function skipIntro():Void
	{
		if (!skippedIntro)
		{
			#if !TITLESCREEN_XML
			remove(ngSpr);
			#end

			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(blackScreen);
			blackScreen.destroy();
			remove(textGroup);
			skippedIntro = true;
		}
	}
}

class IntroText {
	public var lines:Array<OneOfTwo<String, TitleStateImage>> = [];

	public function new(?lines:Array<OneOfTwo<String, TitleStateImage>>) {
		this.lines = lines;
	}

	public function show() {
		var state = cast(FlxG.state, TitleState);
		state.deleteCoolText();
		if (lines == null) return;
		for(e in lines) {
			if (e is String) {
				var text = cast(e, String);
				for(k=>e in state.curWacky) text = text.replace('{introText${k+1}', e);
				state.addMoreText(text);
			} else if (e is Dynamic) {
				var image:TitleStateImage = e;
				if (image.path == null) continue;

				var scale:Float = CoolUtil.getDefault(image.scale, 1);

				var yPos:Float = 200;
				if(state.textGroup.members.length > 0) {
					var lastLine:FlxSprite = cast state.textGroup.members[state.textGroup.members.length-1];
					yPos = lastLine.y + lastLine.height + 10;
				}

				var sprite = new FlxSprite(0, yPos).loadAnimatedGraphic(Paths.image(image.path));
				sprite.flipX = CoolUtil.getDefault(image.flipX, false);
				sprite.flipY = CoolUtil.getDefault(image.flipY, false);
				sprite.scale.set(scale, scale);
				sprite.updateHitbox();
				sprite.screenCenter(X);
				state.textGroup.add(sprite);
			}
		}
	}
}

typedef TitleStateImage = {
	var name:String;
	var path:String;
	@:optional var scale:Null<Float>;
	@:optional var flipX:Null<Bool>;
	@:optional var flipY:Null<Bool>;
}
