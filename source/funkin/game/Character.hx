package funkin.game;

import flixel.util.typeLimit.OneOfTwo;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import funkin.backend.FunkinSprite;
import funkin.backend.scripting.DummyScript;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.ScriptPack;
import funkin.backend.scripting.events.CharacterNodeEvent;
import funkin.backend.scripting.events.CharacterXMLEvent;
import funkin.backend.scripting.events.DanceEvent;
import funkin.backend.scripting.events.DirectionAnimEvent;
import funkin.backend.scripting.events.PlayAnimEvent;
import funkin.backend.scripting.events.PlayAnimEvent.PlayAnimContext;
import funkin.backend.scripting.events.PointEvent;
import funkin.backend.system.Conductor;
import funkin.backend.system.interfaces.IBeatReceiver;
import funkin.backend.system.interfaces.IOffsetCompatible;
import funkin.backend.utils.XMLUtil;
import haxe.Exception;
import haxe.io.Path;
import haxe.xml.Access;
import openfl.geom.ColorTransform;

using StringTools;

@:allow(funkin.desktop.editors.CharacterEditor)
@:allow(funkin.game.StrumLine)
@:allow(funkin.game.PlayState)
class Character extends FunkinSprite implements IBeatReceiver implements IOffsetCompatible {
	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';
	public var sprite:String = 'bf';

	public var lastHit:Float = Math.NEGATIVE_INFINITY;
	public var holdTime:Float = 4;

	public var playerOffsets:Bool = false;

	public var icon:String = null;
	public var iconColor:Null<FlxColor> = null;
	public var gameOverCharacter:String = Character.FALLBACK_DEAD_CHARACTER;

	public var cameraOffset:FlxPoint = FlxPoint.get(0, 0);
	public var globalOffset:FlxPoint = FlxPoint.get(0, 0);

	public var xml:Access;
	public var scripts:ScriptPack;
	public var xmlImportedScripts:Array<XMLImportedScriptInfo> = [];
	public var script(default, set):Script;

	public function prepareInfos(node:Access)
		return XMLImportedScriptInfo.prepareInfos(node, scripts, (infos) -> xmlImportedScripts.push(infos));

	public var idleSuffix:String = "";
	public var stunned(default, set):Bool = false;

	@:noCompletion var __stunnedTime:Float = 0;
	@:noCompletion var __lockAnimThisFrame:Bool = false;

	@:noCompletion var __switchAnims:Bool = true;

	public function new(x:Float, y:Float, ?character:String = "bf", isPlayer:Bool = false, switchAnims:Bool = true, disableScripts:Bool = false) {
		super(x, y);

		animOffsets = new Map<String, FlxPoint>();
		curCharacter = character;
		this.isPlayer = isPlayer;
		__switchAnims = switchAnims;

		antialiasing = true;

		xml = getXMLFromCharName(this);

		if(!disableScripts)
			script = Script.create(Paths.script(Path.withoutExtension(Paths.xml('characters/$curCharacter')), null, true));
		else
			script = new DummyScript(curCharacter);
		script.load();

		buildCharacter(xml);
		scripts.call("create");

		if (script == null)
			script = new DummyScript(curCharacter);

		scripts.call("postCreate");
	}

	@:noCompletion var __swappedLeftRightAnims:Bool = false;
	@:noCompletion var __autoInterval:Bool = false;

	public function fixChar(switchAnims:Bool = false, autoInterval:Bool = false) {
		if ((isDanceLeftDanceRight = hasAnimation("danceLeft") && hasAnimation("danceRight")) && autoInterval)
			beatInterval = 1;
		__autoInterval = autoInterval;

		// character is flipped
		if (isPlayer != playerOffsets && switchAnims)
			swapLeftRightAnimations();

		frameOffset.set(getAnimOffset(getAnimName()).x, getAnimOffset(getAnimName()).y);
		if (isPlayer) flipX = !flipX;
		__baseFlipped = flipX;
	}

	public function swapLeftRightAnimations() {
		CoolUtil.switchAnimFrames(animation.getByName('singRIGHT'), animation.getByName('singLEFT'));
		CoolUtil.switchAnimFrames(animation.getByName('singRIGHTmiss'), animation.getByName('singLEFTmiss'));

		switchOffset('singLEFT', 'singRIGHT');
		switchOffset('singLEFTmiss', 'singRIGHTmiss');

		__swappedLeftRightAnims = true;
	}

	@:noCompletion var __baseFlipped:Bool = false;
	@:noCompletion var isDanceLeftDanceRight:Bool = false;

	override function update(elapsed:Float) {
		super.update(elapsed);
		scripts.call("update", [elapsed]);
		if (stunned) {
			__stunnedTime += elapsed;
			if (__stunnedTime > 5 / 60)
				stunned = false;
		}

		if (!__lockAnimThisFrame && lastAnimContext != DANCE)
			tryDance();

		__lockAnimThisFrame = false;
	}

	private var danced:Bool = false;

	public function dance() {
		if(debugMode) return;

		var event = EventManager.get(DanceEvent).recycle(danced);
		scripts.call("onDance", [event]);
		if (event.cancelled) return;

		if (isDanceLeftDanceRight)
			playAnim(((danced = !danced) ? 'danceLeft' : 'danceRight') + idleSuffix, DANCE);
		else
			playAnim('idle' + idleSuffix, DANCE);
	}

	public function tryDance() {
		switch (lastAnimContext) {
			case SING | MISS:
				if (lastHit + (Conductor.stepCrochet * holdTime) < Conductor.songPosition)
					dance();
			case DANCE:
				dance();
			case LOCK:
				if (getAnimName() == null)
					dance();
			default:
				if (getAnimName() == null || isAnimFinished())
					dance();
		}
	}

	/**
	 * Whenever the character should dance on beat or not. Set to false for `gf`, since the dance animation is automatically handled by PlayState.
	 */
	public var danceOnBeat:Bool = true;
	public override function beatHit(curBeat:Int) {
		scripts.call("beatHit", [curBeat]);

		if (danceOnBeat && (curBeat + beatOffset) % beatInterval == 0 && !__lockAnimThisFrame)
			tryDance();
	}

	public override function stepHit(curStep:Int)
		scripts.call("stepHit", [curStep]);

	@:noCompletion var __reverseDrawProcedure:Bool = false;
	public override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect {
		if (__reverseDrawProcedure) {
			scale.x *= -1;
			var bounds:FlxRect = super.getScreenBounds(newRect, camera);
			scale.x *= -1;
			return bounds;
		}
		return super.getScreenBounds(newRect, camera);
	}

	public override function isOnScreen(?camera:FlxCamera):Bool {
		if (debugMode) return true;
		return super.isOnScreen(camera);
	}

	public function isFlippedOffsets()
		return (isPlayer != playerOffsets) != (flipX != __baseFlipped);

	public override function draw() {
		if (isFlippedOffsets()) {
			__reverseDrawProcedure = true;
			flipX = !flipX;
			scale.x *= -1;

			super.draw();

			flipX = !flipX;
			scale.x *= -1;
			__reverseDrawProcedure = false;
		} else super.draw();
	}

	public var singAnims = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];
	public function playSingAnim(direction:Int, suffix:String = "", Context:PlayAnimContext = SING, ?Force:Null<Bool> = null, Reversed:Bool = false, Frame:Int = 0) {
		var event = EventManager.get(DirectionAnimEvent).recycle(singAnims[direction % singAnims.length] + suffix, direction, suffix, Context, Reversed, Frame, Force);
		scripts.call("onPlaySingAnim", [event]);
		if (!event.cancelled)
			playAnim(event.animName, event.force, event.context, event.reversed, event.frame);
	}

	public override function playAnim(AnimName:String, ?Force:Bool, Context:PlayAnimContext = NONE, Reversed:Bool = false, Frame:Int = 0) {
		var event = EventManager.get(PlayAnimEvent).recycle(AnimName, Force, Reversed, Frame, Context);
		scripts.call("onPlayAnim", [event]);
		if (event.cancelled) return;

		super.playAnim(event.animName, event.force, event.context, event.reverse, event.startingFrame);

		offset.set(globalOffset.x * (isPlayer != playerOffsets ? 1 : -1), -globalOffset.y);
		if (event.context == SING || event.context == MISS)
			lastHit = Conductor.songPosition;
	}

	public inline function getCameraPosition() {
		var midpoint:FlxPoint = getMidpoint();
		var event = EventManager.get(PointEvent).recycle(
			midpoint.x + (isPlayer ? -100 : 150) + globalOffset.x + cameraOffset.x,
			midpoint.y - 100 + globalOffset.y + cameraOffset.y);
		scripts.call("onGetCamPos", [event]);

		midpoint.put();
		return new FlxPoint(event.x, event.y);
	}

	public override function destroy() {
		scripts.call('destroy');
		scripts.destroy();
		super.destroy();

		cameraOffset.put();
		globalOffset.put();
	}

	@:noCompletion var __reverseTrailProcedure:Bool = false;

	// When using trails on characters you should do `trail.beforeCache = char.beforeTrailCache;`
	public dynamic function beforeTrailCache()
		if (isFlippedOffsets()) {
			flipX = !flipX;
			scale.x *= -1;
			__reverseTrailProcedure = true;
		}

	// When using trails on characters you should do `trail.afterCache = char.afterTrailCache;`
	public dynamic function afterTrailCache()
		if (__reverseTrailProcedure) {
			flipX = !flipX;
			scale.x *= -1;
			__reverseTrailProcedure = false;
		}

	public function applyXML(xml:Access) { // just for now till i remake the dumb editor
		gameOverCharacter = Character.FALLBACK_DEAD_CHARACTER;
		cameraOffset.set(0, 0);
		globalOffset.set(0, 0);
		playerOffsets = false;
		flipX = false;
		holdTime = 4;
		iconColor = null;

		animation.destroyAnimations();
		animDatas.clear();

		__baseFlipped = false;
		buildCharacter(xml);
	}

	public inline function buildCharacter(xml:Access) {
		for(node in xml.elements)
			switch(node.name) {
				case "use-extension" | "extension" | "ext":
					if (!XMLImportedScriptInfo.shouldLoadBefore(node)) continue;
					prepareInfos(node);
			}

		xml = scripts.event("onCharacterXMLParsed", EventManager.get(CharacterXMLEvent).recycle(this, xml)).xml;

		sprite = curCharacter;
		spriteAnimType = BEAT;
		this.xml = xml; // Modders wassup :D

		if (xml.x.exists("isPlayer")) playerOffsets = (xml.x.get("isPlayer") == "true");
		if (xml.x.exists("x")) globalOffset.x = Std.parseFloat(xml.x.get("x"));
		if (xml.x.exists("y")) globalOffset.y = Std.parseFloat(xml.x.get("y"));
		if (xml.x.exists("gameOverChar")) gameOverCharacter = xml.x.get("gameOverChar");
		if (xml.x.exists("camx")) cameraOffset.x = Std.parseFloat(xml.x.get("camx"));
		if (xml.x.exists("camy")) cameraOffset.y = Std.parseFloat(xml.x.get("camy"));
		if (xml.x.exists("holdTime")) holdTime = CoolUtil.getDefault(Std.parseFloat(xml.x.get("holdTime")), 4);
		if (xml.x.exists("flipX")) flipX = (xml.x.get("flipX") == "true");
		if (xml.x.exists("icon")) icon = xml.x.get("icon");
		if (xml.x.exists("color")) iconColor = FlxColor.fromString(xml.x.get("color"));
		if (xml.x.exists("scale")) {
			var scale:Float = Std.parseFloat(xml.x.get("scale")).getDefault(1);
			this.scale.set(scale, scale);
			updateHitbox();
		}
		if (xml.x.exists("antialiasing")) antialiasing = (xml.x.get("antialiasing") == "true");
		if (xml.x.exists("sprite")) sprite = xml.x.get("sprite");

		var hasInterval:Bool = xml.x.exists("interval");
		if (hasInterval) beatInterval = Std.parseInt(xml.x.get("interval"));

		loadSprite(Paths.image('characters/$sprite'));
		for(node in xml.elements) {
			switch(node.name) {
				case "anim":
					XMLUtil.addXMLAnimation(this, node);
				case "use-extension" | "extension" | "ext":
					if (XMLImportedScriptInfo.shouldLoadBefore(node)) continue;
					prepareInfos(node);
				default:
					// nothing
			}

			scripts.event("onCharacterNodeParsed", EventManager.get(CharacterNodeEvent).recycle(this, node, node.name));
		}

		for (attribute in xml.x.attributes())
			if (!characterProperties.contains(attribute))
				extra[attribute] = xml.x.get(attribute);

		fixChar(__switchAnims, !hasInterval);
		dance();

		for (info in xmlImportedScripts) if (info.shortLived) {
			var script = info.getScript();
			if (script == null) continue;

			scripts.remove(script);
			script.destroy();
		}
	}

	public static var characterProperties:Array<String> = [
		"x", "y", "sprite", "scale", "antialiasing",
		"flipX", "camx", "camy", "isPlayer", "icon",
		"color", "gameOverChar", "holdTime"
	];
	public static var characterAnimProperties:Array<String> = [
		"name", "anim", "x", "y", "fps", "loop", "indices"
	];

	public inline function buildXML(?animsOrder:Array<String>):Xml {
		var xml:Xml = Xml.createElement("character");
		xml.attributeOrder = characterProperties.copy();

		if (globalOffset.x != 0) xml.set("x", Std.string(FlxMath.roundDecimal(globalOffset.x, 2)));
		if (globalOffset.y != 0) xml.set("y", Std.string(FlxMath.roundDecimal(globalOffset.y, 2)));

		if (cameraOffset.x != 0) xml.set("camx", Std.string(FlxMath.roundDecimal(cameraOffset.x, 2)));
		if (cameraOffset.y != 0) xml.set("camy", Std.string(FlxMath.roundDecimal(cameraOffset.y, 2)));

		if (holdTime != 4) xml.set("holdTime", Std.string(FlxMath.roundDecimal(holdTime, 4)));

		if (flipX) xml.set("flipX", Std.string(flipX));
		xml.set("icon", getIcon());

		if (gameOverCharacter != Character.FALLBACK_DEAD_CHARACTER) xml.set("gameOverChar", gameOverCharacter);
		if (iconColor != null) xml.set("color", iconColor.toWebString());

		xml.set("sprite", sprite);
		if (scale.x != 1) xml.set("scale", Std.string(FlxMath.roundDecimal(scale.x, 4)));
		if (!antialiasing) xml.set("antialiasing", antialiasing == true ? "true" : "false");

		if (playerOffsets) xml.set("isPlayer", playerOffsets == true ? "true" : "false");

		var anims:Array<AnimData> = [];
		if (animsOrder != null) {
			for (name in animsOrder)
				if (animDatas.exists(name)) anims.push(animDatas.get(name));
		} else
			anims = Lambda.array(animDatas);

		for (anim in anims) {
			var animXml:Xml = Xml.createElement('anim');
			animXml.attributeOrder = characterAnimProperties;

			animXml.set("name", anim.name);
			animXml.set("anim", anim.anim);
			animXml.set("loop", Std.string(anim.loop));
			animXml.set("fps", Std.string(FlxMath.roundDecimal(anim.fps, 2)));

			var offset:FlxPoint = getAnimOffset(anim.name);
			animXml.set("x", Std.string(FlxMath.roundDecimal(offset.x, 2)));
			animXml.set("y", Std.string(FlxMath.roundDecimal(offset.y, 2)));
			offset.putWeak();

			if (anim.indices.length > 0)
				animXml.set("indices", CoolUtil.formatNumberRange(anim.indices));

			xml.addChild(animXml);
		}

		for (name => val in extra)
			if (!xml.attributeOrder.contains(name)) {
				xml.attributeOrder.push(name);
				xml.set(name, Std.string(val));
			}

		this.xml = new Access(xml);
		return xml;
	}

	public inline function getIcon()
		return (icon != null) ? icon : curCharacter;

	public function getAnimOrder()
		return [for(a in xml.nodes.anim) if(a.has.name) a.att.name];

	@:noCompletion private function set_stunned(b:Bool) {
		__stunnedTime = 0;
		return stunned = b;
	}

	// ---- Backwards compat ----
	// Interval at which the character will dance (higher number = slower dance)
	@:noCompletion public var danceInterval(get, set):Int;
	@:noCompletion private function set_danceInterval(v:Int)
		return beatInterval = v;
	@:noCompletion private function get_danceInterval()
		return beatInterval;

	private function set_script(script:Script):Script {
		if (scripts == null) (scripts = new ScriptPack("Character")).setParent(this);

		var lastIndex = scripts.scripts.indexOf(this.script);
		if(lastIndex >= 0) {
			if(script == null) // last != null && new == null
				scripts.scripts.splice(lastIndex, 1);
			else // last != null && new != null
				scripts.scripts[lastIndex] = script;
		} else if(script != null) // last == null
			scripts.insert(0, script);

		return this.script = script;
	}
	// ---- end of Backwards compat ----


	public static var FALLBACK_CHARACTER:String = "bf";
	public static var FALLBACK_DEAD_CHARACTER:String = "bf-dead";
	public static function getXMLFromCharName(character:OneOfTwo<String, Character>):Access {
		var char:Character = null;
		if (character is Character) {
			char = cast(character, Character);
			character = char.curCharacter;
		}

		var xml:Access = null;
		while (true) {
			var xmlPath:String = Paths.xml('characters/$character');
			if (!Assets.exists(xmlPath)) {
				character = FALLBACK_CHARACTER;
				if (char != null) 
					char.curCharacter = character;
				continue;
			}

			var plainXML:String = Assets.getText(xmlPath);
			try {
				var charXML:Xml = Xml.parse(plainXML).firstElement();
				if (charXML == null) throw new Exception("Missing \"character\" node in XML.");
				xml = new Access(charXML);
			} catch (e) {
				Logs.trace('Error while loading character ${character}: ${e}', ERROR);

				character = FALLBACK_CHARACTER;
				if (char != null)
					char.curCharacter = character;
				continue;
			}
			break;
		}
		return xml;
	}

	public static function getIconFromCharName(?character:String) {
		if(character == null) return "face";
		var icon:String = character;

		var xml:Access = getXMLFromCharName(character);
		if (xml != null && xml.x.exists("icon")) icon = xml.x.get("icon");

		return icon;
	}

	public static function getList(?mods:Bool = false):Array<String>
		return [
			for (path in Paths.getFolderContent('data/characters/', true, mods ? MODS : BOTH))
				if (Path.extension(path) == "xml") CoolUtil.getFilename(path)
		];
}