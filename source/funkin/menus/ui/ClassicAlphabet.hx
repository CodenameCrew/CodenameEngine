package funkin.menus.ui;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.backend.assets.IModsAssetLibrary;
import funkin.backend.assets.LimeLibrarySymbol;
import haxe.xml.Access;
import openfl.utils.AssetLibrary;

using StringTools;

/**
 * Loosely based on FlxTypeText lolol
 */
class ClassicAlphabet extends FlxSpriteGroup
{
	public var delay:Float = 0.05;
	public var paused:Bool = false;

	// for menu shit
	public var targetY:Float = 0;
	public var isMenuItem:Bool = false;

	public var text:String = "";

	var _finalText:String = "";
	var _curText:String = "";

	var yMulti:Float = 1;

	// custom shit
	// amp, backslash, question mark, apostrophy, comma, angry faic, period
	var lastSprite:AlphaCharacter;
	var xPosResetted:Bool = false;

	var splitWords:Array<String> = [];

	var isBold:Bool = false;

	private override function set_color(c:Int):Int {
		for(e in group.members) {
			if (e is AlphaCharacter) {
				var char:AlphaCharacter = cast e;
				char.setColor(c, isBold);
			}
		}
		return super.set_color(c);
	}

	// TODO: fix this shit refreshing
	public function refreshAlphabetXML(path:String) {
		AlphaCharacter.__alphaPath = Paths.getAssetsRoot() + path;
		try {
			var file = Assets.getText(path);
			if(file == null) return;
			var xml = new Access(Xml.parse(file).firstElement());
			AlphaCharacter.boldAnims = [];
			AlphaCharacter.letterAnims = [];
			AlphaCharacter.boldAlphabetPath = AlphaCharacter.letterAlphabetPath = 'ui/alphabet';

			for(e in xml.elements) {
				var bold = e.name == "bold";
				var list = bold ? AlphaCharacter.boldAnims : AlphaCharacter.letterAnims;
				if (e.has.spritesheet) {
					if (bold)
						AlphaCharacter.boldAlphabetPath = e.att.spritesheet;
					else
						AlphaCharacter.letterAlphabetPath = e.att.spritesheet;
				}
				for(e in e.nodes.letter) {
					if (!e.has.char || !e.has.anim) continue;
					var name = e.att.char;
					var anim = e.att.anim;
					list[name] = anim;
				}
			}
		} catch(e) {
			trace(e.details());
		}
	}
	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false)
	{
		super(x, y);

		_finalText = this.text = text;
		isBold = bold;

		var alphabetPath = Paths.xml("alphabet");
		if (Paths.getAssetsRoot() + alphabetPath != AlphaCharacter.__alphaPath) {
			refreshAlphabetXML(alphabetPath);
		}
		#if MOD_SUPPORT else {
			var libThing = new LimeLibrarySymbol(alphabetPath);
			if (libThing.library is AssetLibrary) {
				var library = cast(libThing.library, AssetLibrary);
				@:privateAccess
				if (library.__proxy != null && library.__proxy is AssetLibrary) {
					@:privateAccess
					library = cast(library.__proxy, AssetLibrary);
				}
				if (library is IModsAssetLibrary) {
					var modLib = cast(library, IModsAssetLibrary);
					@:privateAccess
					if (!modLib.__isCacheValid(library.cachedBytes, libThing.symbolName)) {
						refreshAlphabetXML(alphabetPath);
					}
				}
			}
		}
		#end

		if (text != "")
		{
			if (typed)
			{
				startTypedText();
			}
			else
			{
				addText();
			}
		}
	}

	public function addText()
	{
		doSplitWords();

		var xPos:Float = 0;
		var curRow:Int = 0;
		for (i=>character in splitWords)
		{
			if (lastSprite != null)
				xPos = lastSprite.x + lastSprite.width - x;

			if (xPosResetted && !(xPosResetted = false)) xPos = 0;

			var letter:AlphaCharacter = new AlphaCharacter(xPos, 0);
			letter.row = curRow;
			if (isBold)
				letter.createBold(character);
			else
				letter.createLetter(character);

			// anim not found
			if (!letter.visible)
				xPos += 40;

			letter.setColor(color, isBold);
			add(letter);

			lastSprite = letter;
			if (_finalText.fastCodeAt(i) == "\n".code)
			{
				xPosResetted = true;
				curRow += 1;
			}
		}
	}

	function doSplitWords():Void
	{
		splitWords = _finalText.split("");
	}

	//public var personTalking:String = Flags.DEFAULT_GIRLFRIEND;

	public function startTypedText():Void
	{
		_finalText = text;
		doSplitWords();

		// trace(arrayShit);

		var loopNum:Int = 0;

		var xPos:Float = 0;
		var curRow:Int = 0;

		new FlxTimer().start(0.05, function(tmr:FlxTimer)
		{
			// trace(_finalText.fastCodeAt(loopNum) + " " + _finalText.charAt(loopNum));
			if (_finalText.fastCodeAt(loopNum) == "\n".code)
			{
				yMulti += 1;
				xPosResetted = true;
				xPos = 0;
				curRow += 1;
			}
			loopNum += 1;

			tmr.time = FlxG.random.float(0.04, 0.09);
		}, splitWords.length);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (isMenuItem)
		{
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

			y = CoolUtil.fpsLerp(y, (scaledY * 120) + (FlxG.height * 0.48), 0.16);
			x = CoolUtil.fpsLerp(x, (targetY * 20) + 90, 0.16);
		}

		if (text != _finalText) {
			_finalText = text;
			for(e in members)
				e.destroy();
			members.clear();
			lastSprite = null;
			addText();
		}
	}
}

class AlphaCharacter extends FlxSprite
{
	@:dox(hide) @:noCompletion public static var __alphaPath:String = null;

	public static var letterAlphabetPath:String;
	public static var boldAlphabetPath:String;

	public static var boldAnims:Map<String, String> = [];
	public static var letterAnims:Map<String, String> = [];

	public var row:Int = 0;

	public function setColor(c:FlxColor, isBold:Bool) {
		if (isBold) {
			colorTransform.redMultiplier = c.redFloat;
			colorTransform.greenMultiplier = c.greenFloat;
			colorTransform.blueMultiplier = c.blueFloat;
		} else {
			colorTransform.redOffset = c.red;
			colorTransform.greenOffset = c.green;
			colorTransform.blueOffset = c.blue;
		}
	}
	public function new(x:Float, y:Float)
	{
		super(x, y);

		antialiasing = true;
	}

	public function createBold(letter:String)
	{
		if(!boldAnims.exists(letter))
			letter = letter.toUpperCase();
		if (!boldAnims.exists(letter)) {
			visible = false;
			active = false;
			scale.set();
			width = 40;
			return;
		}
		frames = Paths.getFrames(boldAlphabetPath);
		animation.addByPrefix(letter, boldAnims[letter], 24);
		animation.play(letter);
		updateHitbox();

		y += row * height;
	}

	public function createLetter(letter:String):Void
	{
		if (!letterAnims.exists(letter)) {
			visible = false;
			active = false;
			scale.set();
			width = 40;
			return;
		}
		frames = Paths.getFrames(letterAlphabetPath);
		animation.addByPrefix(letter, letterAnims[letter], 24);
		animation.play(letter);
		updateHitbox();

		y = (110 - height);
		y += row * 60;
	}
}