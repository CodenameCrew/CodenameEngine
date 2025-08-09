package funkin.game.cutscenes;

import flixel.sound.FlxSound;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.events.CancellableEvent;
import funkin.backend.scripting.events.DynamicEvent;
import funkin.backend.scripting.events.dialogue.*;
import funkin.backend.utils.FunkinParentDisabler;
import funkin.game.cutscenes.dialogue.*;
import haxe.io.Path;
import haxe.xml.Access;

/**
 * Substate made for dialogue cutscenes. To use it in a scripted cutscene, call `startDialogue`.
 */
class DialogueCutscene extends ScriptedCutscene {
	public var dialoguePath:String;
	public var dialogueData:Access;

	public var charMap:Map<String, DialogueCharacter> = [];

	public var dialogueLines:Array<DialogueLine> = [];
	public var curLine(default, set):DialogueLine = null;
	public var lastLine:DialogueLine = null;
	public var dialogueBox:DialogueBox;

	public var dialogueCamera:FlxCamera;
	public var curMusic:FlxSound = null;

	public static var cutscene:DialogueCutscene;
	public var dialogueScript(get, set):Script;

	public inline function set_curLine(val:DialogueLine) {
		lastLine = curLine;
		return curLine = val;
	}

	// Backwards compat funcs  - Nex
	public inline function set_dialogueScript(val:Script) return script = val;
	public inline function get_dialogueScript() return script;

	public function new(dialoguePath:String, callback:Void->Void) {
		super(this.dialoguePath = dialoguePath, callback);

		camera = dialogueCamera = new FlxCamera();
		dialogueCamera.bgColor = 0;
		FlxG.cameras.add(dialogueCamera, false);

		cutscene = this;
	}

	public override function onErrorScriptLoading() {
		//Logs.trace('Could not find script for dialogue cutscene at "${scriptPath}"', WARNING, YELLOW);  // Too many warnings honestly, stawp  - Nex
	}

	var parentDisabler:FunkinParentDisabler;
	public override function create() {
		super.create();

		add(parentDisabler = new FunkinParentDisabler());  // MESS WITH THIS IN SCRIPTS TO RESUME PLAYSTATE'S TWEENS!!  - Nex
		try {
			var event = EventManager.get(DialogueStructureEvent).recycle(dialogueData);
			event.dialogueData = new Access(Xml.parse(Assets.getText(dialoguePath)).firstElement());
			dialogueScript.call('structureLoaded', [event]);
			if (event.cancelled) return;
			dialogueData = event.dialogueData;

			// Add characters
			for (char in dialogueData.nodes.char) {
				if (!char.has.name) continue;
				if (charMap.exists(char.att.name)) {
					Logs.warn('2 dialogue characters share the same name (${char.att.name}, ${char.att.name}). The old character has been replaced.');
					remove(charMap[char.att.name], true);
				}

				var leChar:DialogueCharacter = new DialogueCharacter(char.att.name, char.getAtt('position').getDefault('default'));
				if (char.has.defaultAnim) leChar.defaultAnim = char.att.defaultAnim;
				add(charMap[char.att.name] = leChar);
			}

			var useDef:Bool = false;
			if (dialogueData.has.forceBoxDefaultTxtSound && dialogueData.att.forceBoxDefaultTxtSound == "true")
				useDef = true;

			// Add lines
			for (node in dialogueData.nodes.line) {
				var formats = XMLUtil.getTextFormats(XMLUtil.fixSpacingInNode(node));
				var volume:Null<Float> = 0.8;
				var line:DialogueLine = {
					text: [for(x in formats) x.text].join(""),
					format: formats,
					char: node.getAtt('char').getDefault('boyfriend'),
					bubble: node.getAtt('bubble').getDefault('normal'),
					callback: node.getAtt('callback'),
					changeDefAnim: node.getAtt('changeDefAnim'),
					speed: Std.parseFloat(node.getAtt("speed")).getDefault(0.05),
					musicVolume: node.has.musicVolume ? (volume = Std.parseFloat(node.att.musicVolume).getDefault(0.8)) : null,
					changeMusic: node.has.changeMusic ? FlxG.sound.load(Paths.music(node.att.changeMusic), volume, true) : null,
					playSound: node.has.playSound ? FlxG.sound.load(Paths.sound(node.att.playSound)) : null,
					nextSound: node.has.nextSound ? FlxG.sound.load(Paths.sound(node.att.nextSound)) : null,
					textSound: null
				};

				if (node.has.textSound) line.textSound = FlxG.sound.load(Paths.sound(node.att.textSound));
				else if (!useDef) {
					var char:DialogueCharacter = charMap[line.char];
					if(char != null && char.charData != null && char.charData.has.textSound)
						line.textSound = FlxG.sound.load(Paths.sound(char.charData.att.textSound));
				}

				dialogueLines.push(line);
			}

			// Add dialogue box
			dialogueBox = new DialogueBox(dialogueData.getAtt("box").getDefault("default"));
			add(dialogueBox);
			add(dialogueBox.text);

			next(true);
		} catch(e) {
			var message:String = e.toString();
			Logs.trace('Error while loading dialogue at ${dialoguePath}: $message', ERROR, RED);
			dialogueScript.call("loadingError", [message]);
			close();
		}

		dialogueScript.call("postCreate");
	}

	public override function pauseCheck():Bool {
		return super.pauseCheck() && !controls.ACCEPT;  // Avoids next() and pause() being called at the same time  - Nex
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		if(controls.ACCEPT) {
			if(dialogueBox.dialogueEnded) next();
			else dialogueBox.text.skip();
		}
	}

	/**
	 * Use this to cancel `next`!
	 */
	public var canProceed:Bool = true;

	public function next(playFirst:Bool = false) {
		var event = EventManager.get(DialogueNextLineEvent).recycle(playFirst);
		dialogueScript.call("next", [event]);
		if(event.cancelled || !canProceed) return;

		if ((curLine = dialogueLines.shift()) == null) {
			if(lastLine != null && dialogueBox.hasAnimation(lastLine.bubble + "-close")) {
				dialogueBox.playBubbleAnim(lastLine.bubble, "-close");
				dialogueBox.animation.finishCallback = (_) -> close();
			} else {
				FlxG.sound.play(dialogueBox.nextSFX);
				close();
			}
			return;
		}

		if (curLine.callback != null)
			dialogueScript.call(curLine.callback, [event.playFirst]);

		for (k=>c in charMap)
			if (k != curLine.char)
				c.hide();

		var char = charMap[curLine.char];
		if (char != null) {
			var force:Bool;
			if(force = (curLine.changeDefAnim != null)) char.defaultAnim = curLine.changeDefAnim;
			dialogueBox.popupChar(char, force);
		}

		var finalSuffix:String = event.playFirst && dialogueBox.hasAnimation(curLine.bubble + "-firstOpen") ? "-firstOpen" : dialogueBox.hasAnimation(curLine.bubble + "-open") ? "-open" : "";
		dialogueBox.playBubbleAnim(curLine.bubble, finalSuffix, curLine.text, curLine.format, curLine.speed, curLine.nextSound, curLine.textSound != null ? [curLine.textSound] : null, finalSuffix == "-firstOpen" || finalSuffix == "-open", !event.playFirst);

		if(curLine.playSound != null) curLine.playSound.play();
		if(curLine.changeMusic != null) {
			if(curMusic != null) curMusic.destroy();
			curMusic = curLine.changeMusic;
			curMusic.play();
			curMusic.fadeIn(1, 0, curMusic.volume);
		} else if(curLine.musicVolume != null && curMusic != null) curMusic.volume = curLine.musicVolume;

		dialogueScript.call("postNext", [event]);
	}

	public override function close() {
		var event = new CancellableEvent();
		for (c in charMap) c.dialogueCharScript.call("close", [event]);
		if (dialogueBox != null) dialogueBox.dialogueBoxScript.call("close", [event]);
		dialogueScript.call("close", [event]);
		if (event.cancelled) return;

		super.close();
	}

	public override function destroy() {
		if (curMusic != null && !curMusic.persist) curMusic.destroy();

		super.destroy();
		if (cutscene == this) cutscene = null;
		FlxG.cameras.remove(dialogueCamera);
	}
}

typedef DialogueLine = {
	var text:String;
	var format:Array<XMLUtil.TextFormat>;
	var char:String;
	var bubble:String;
	var callback:String;
	var speed:Float;
	var musicVolume:Null<Float>;
	var changeMusic:FlxSound;
	var playSound:FlxSound;
	var nextSound:FlxSound;
	var textSound:FlxSound;
	var changeDefAnim:String;
}
