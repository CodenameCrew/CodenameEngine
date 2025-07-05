package funkin.game.cutscenes.dialogue;

import funkin.backend.scripting.events.PlayAnimEvent;
import funkin.backend.scripting.events.dialogue.*;
import funkin.backend.scripting.events.CancellableEvent;
import funkin.backend.scripting.Script;
import flixel.tweens.FlxTween;
import haxe.xml.Access;

class DialogueCharacter extends FunkinSprite {
	public var charData:Access;
	public var curTween:FlxTween;
	public var curAnimContext:DialogueCharAnimContext = NONE;
	public var positionName:String;

	public var finishAnimCallback:String->Void = null;
	public var defaultAnim:String = 'normal';

	public var defPath:String = 'dialogue/characters/';
	public var dialogueCharScript:Script;
	public var cutscene:DialogueCutscene = DialogueCutscene.cutscene;

	public function new(name:String, position:String) {
		super();

		dialogueCharScript = Script.create(Paths.script('data/' + defPath + name));
		dialogueCharScript.setParent(this);
		dialogueCharScript.load();

		var event = EventManager.get(DialogueCharStructureEvent).recycle(name, position, null);
		dialogueCharScript.call('create', [event]);  // Its not really create() since its inside new() but, nah, it makes no difference at least here  - Nex
		if(event.cancelled) return;

		try {
			event.charData = new Access(Xml.parse(Assets.getText(Paths.xml(defPath + event.name))).firstElement());
			dialogueCharScript.call('structureLoaded', [event]);
			if(event.cancelled) return;
			name = event.name;
			positionName = event.position;
			charData = event.charData;

			if(!charData.has.sprite) charData.x.set("sprite", name);
			if(!charData.has.updateHitbox) charData.x.set("updateHitbox", "true");
			XMLUtil.loadSpriteFromXML(this, charData, defPath, LOOP);

			animation.finishCallback = (name:String) -> {
				if(finishAnimCallback != null) finishAnimCallback(name);

				if(name.endsWith("-show") || name == 'show') hasAnimation(defaultAnim) ? playAnim(defaultAnim, true) : animation.stop();
				else if(name.endsWith("-hide") || name == 'hide') alpha = 0;
			}

			offset.set(x, y + height);
			x = 0; y = 0;
		} catch(e) {
			var message:String = e.toString();
			Logs.trace('Failed to load dialogue character $name: ${message}', ERROR);
			dialogueCharScript.call("loadingError", [message]);
		}
		visible = false;
		dialogueCharScript.call("postCreate");
	}

	public override function playAnim(AnimName:String, ?Force:Bool, Context:PlayAnimContext = NONE, Reversed:Bool = false, Frame:Int = 0) {
		var event = EventManager.get(PlayAnimEvent).recycle(AnimName, Force, Reversed, Frame, Context);
		dialogueCharScript.call("playAnim", [event]);
		if(event.cancelled) return;

		super.playAnim(event.animName, event.force, event.context, event.reverse, event.startingFrame);
	}

	public override function beatHit(curBeat:Int) {
		super.beatHit(curBeat);
		dialogueCharScript.call("beatHit", [curBeat]);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		dialogueCharScript.call("update", [elapsed]);
	}

	public function show(x:Float, y:Float, ?animation:String, force:Bool = false) {
		if(animation == null) animation = defaultAnim;
		var lastAnimContext:DialogueCharAnimContext = force ? POPOUT : curAnimContext;
		curAnimContext = POPIN;

		var event = EventManager.get(DialogueCharShowEvent).recycle(x, y, animation, lastAnimContext);
		dialogueCharScript.call("show", [event]);
		if (event.cancelled || event.lastAnimContext == curAnimContext) return;

		visible = true;
		var anim:String;
		if (hasAnimation(anim = '${event.animation}-show') || hasAnimation(anim = 'show')) {
			playAnim(anim, true);
			setPosition(event.x, event.y);
			alpha = 1;
		} else {
			setPosition(event.x, event.y + 100);
			if(curTween != null) curTween.cancel();
			playAnim(event.animation, true);
			alpha = 0;
			curTween = FlxTween.tween(this, {alpha: 1, y: event.y}, 0.2, {ease: FlxEase.quintOut, onComplete: function(twn:FlxTween) dialogueCharScript.call("showTweenCompleted", [twn])});
		}
		dialogueCharScript.call("postShow", [event]);
	}

	public function hide(?animation:String, force:Bool = false) {
		if(animation == null) animation = defaultAnim;
		var lastAnimContext:DialogueCharAnimContext = force ? POPIN : curAnimContext;
		curAnimContext = POPOUT;

		var event = EventManager.get(DialogueCharHideEvent).recycle(animation, lastAnimContext);
		dialogueCharScript.call("hide", [event]);
		if (event.cancelled || event.lastAnimContext == curAnimContext) return;

		var anim:String;
		if(hasAnimation(anim = '${event.animation}-hide') || hasAnimation(anim = 'hide')) playAnim(anim, true);
		else {
			if(curTween != null) curTween.cancel();
			curTween = FlxTween.tween(this, {alpha: 0, y: y + 100}, 0.2, {ease: FlxEase.quintIn, onComplete: function(twn:FlxTween) dialogueCharScript.call("hideTweenCompleted", [twn])});
		}
		dialogueCharScript.call("postHide", [event]);
	}

	override function destroy()
	{
		dialogueCharScript.call("destroy");
		dialogueCharScript.destroy();

		super.destroy();
	}
}

enum abstract DialogueCharAnimContext(Int) {
	var NONE = -1;
	var POPIN = 0;
	var POPOUT = 1;
}