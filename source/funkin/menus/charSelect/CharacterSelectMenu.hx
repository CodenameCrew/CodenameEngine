package funkin.menus.charSelect;

import flixel.util.FlxTimer;
import haxe.Json;
import funkin.game.Character;
import dave.DaveBitmapText;
import flixel.FlxSprite;
import funkin.backend.utils.CoolUtil;
import flixel.util.FlxAxes;
import flixel.text.FlxText;

using StringTools;

class CharacterSelectMenu extends MusicBeatState
{
	public var characterSelectMode:CharacterSelectMode = CHARACTER_AND_MODE;

	public var oppMode:Bool = false;
	public var coopMode:Bool = false;

	public var curSelected:Int = 0;

	public var characters:Array<SelectCharacterData> = [];
	public var curCharacter:Character;
	public var characterName:DaveBitmapText;

	public var portraits:Array<CharacterSelectPortrait> = [];

	public var bg:FlxSprite;
	public var bgName:String = "bg";

	var selectedOption:Bool = false;

	var eventSong:String;
	var eventDiff:String;
	var eventVar:String;

	var charOffsetCs:Int = 0;

	public override function new(eventSong:String, eventDiff:String, eventVar:String)
	{
		super();
		this.eventSong = eventSong;
		this.eventDiff = eventDiff;
		this.eventVar = eventVar;
	}

	override function create()
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}

		// add character musics later
		CoolUtil.playMusic(Paths.music("charSelect/default"));

		CoolUtil.selectingCharacter = true;

		super.create();

		characterSelectMode = PlayState.SONG.meta.selectMode;

		createBg(bgName);

		for (char in PlayState.SONG.meta.allowedSelectCharacters)
		{
			characters.push(loadSelectCharacterData(char));
		}

		// Testing
		characters.push(loadSelectCharacterData("bf-3d"));
		characters.push(loadSelectCharacterData("none"));
		characters.push(loadSelectCharacterData("dave"));
		characters.push(loadSelectCharacterData("tristan-gold"));
		characters.push(loadSelectCharacterData("bambi"));
		characters.push(loadSelectCharacterData("tristan"));
		characters.push(loadSelectCharacterData("playrobot"));
		characters.push(loadSelectCharacterData("none"));

		var pageCenter = new FlxPoint(640 + 300, 370);
		if (characterSelectMode == 1)
		{
			pageCenter.x += 2000;
			charOffsetCs = 512;
		}

		var newPortId:Int = 0;
		for (char in characters)
		{
			var port = new CharacterSelectPortrait(char.selectPortrait, newPortId, characters.length - 1, char.unselectedAnim, char.transitionsAnim,
				char.selectedAnim, char.transitionuAnim, pageCenter);

			add(port);
			portraits.push(port);

			newPortId++;
		}

		characterName = new DaveBitmapText(45, 100, "Character Name", 90 * .65, "perep_outlined");
		characterName.antialiasing = Options.antialiasing;
		characterName.letterSpacing = 2;
		characterName.alignment = FlxTextAlign.CENTER;
		add(characterName);

		changeSelection(0);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!selectedOption)
		{
			if (controls.LEFT_P)
			{
				changeSelection(-1);
			}
			else if (controls.RIGHT_P)
			{
				changeSelection(1);
			}
			else if (controls.UP_P)
			{
				changeSelection(-3);
			}
			else if (controls.DOWN_P)
			{
				changeSelection(3);
			}

			if (controls.ACCEPT)
			{
				complete();
			}
			else if (controls.BACK)
			{
				selectedOption = true;
				CoolUtil.selectingCharacter = false;
				CoolUtil.playMenuSFX(CANCEL, 1);

				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.fadeOut(0.5, 0, function t(tw)
					{
						FlxG.sound.music.stop();
					});
				}

				var tim = new FlxTimer().start(0.6, function f(tim)
				{
					FlxG.switchState(new FreeplayState());
				});
			}
		}
	}

	public function complete()
	{
		selectedOption = true;

		CoolUtil.selectingCharacter = false;

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.fadeOut(0.9, 0, function t(tw)
			{
				FlxG.sound.music.stop();
			});
		}

		CoolUtil.playMenuSFX(CONFIRM, 1);

		curCharacter.playAnim("hey", true);

		Options.csLastSelected = characters[curSelected].character;

		PlayState.loadSong(eventSong, eventDiff, eventVar, oppMode, coopMode);

		var tim = new FlxTimer().start(1, function f(tim)
		{
			FlxG.switchState(new PlayState());
		});
	}

	public function changeSelection(amount:Int, cut:Bool = false)
	{
		if (cut)
		{
			curSelected = amount;
		}
		else
		{
			curSelected += amount;
			curSelected = FlxMath.wrap(curSelected, 0, characters.length - 1);
		}

		if (amount != 0 || cut)
		{
			CoolUtil.playMenuSFX(SCROLL, 0.7);
		}

		loadCharacter(characters[curSelected].character, characters[curSelected].charScrX, characters[curSelected].charScrY);

		characterName.text = characters[curSelected].displayName;
		characterName.updateHitbox();
		characterName.screenCenter(FlxAxes.X);
		characterName.x -= 335;

		for (port in portraits)
		{
			port.unselect();
		}

		portraits[curSelected].select();
	}

	public function loadCharacter(name:String, xx:Int, yy:Int)
	{
		var pos = 1;

		if (curCharacter != null)
		{
			pos = members.indexOf(curCharacter);
			remove(curCharacter);
			curCharacter.destroy();
		}

		curCharacter = new Character(0, 0, name, true);
		curCharacter.x += xx + charOffsetCs;
		curCharacter.y += yy;

		insert(pos, curCharacter);
	}

	public function createBg(bgName:String)
	{
		bg = new FlxSprite().loadGraphic(Paths.image("menus/charSelect/" + bgName));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.antialiasing = Options.antialiasing;
		bg.screenCenter();
		add(bg);
	}

	public static function loadSelectCharacterData(name:String, ?fromMods:Bool = false):SelectCharacterData
	{
		var folder = 'data/selectcharacters';
		var data:SelectCharacterData = null;
		var defaultPaths = [Paths.file('$folder/$name.json')];

		for (path in defaultPaths)
		{
			if (Assets.exists(path))
			{
				fromMods = Paths.assetsTree.existsSpecific(path, "TEXT", MODS);

				try
				{
					var tempData = Json.parse(Assets.getText(path));
					data = tempData;
				}
				catch (e)
				{
					Logs.trace('Failed to load Select Character Data for $name ($path): ${Std.string(e)}', ERROR);
				}

				if (data != null)
				{
					break;
				}
			}
		}

		return data;
	}
}
