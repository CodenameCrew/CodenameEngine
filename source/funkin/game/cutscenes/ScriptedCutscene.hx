package funkin.game.cutscenes;

import haxe.io.Path;
import flixel.FlxSubState;
import funkin.backend.scripting.DummyScript;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.events.CancellableEvent;
import funkin.backend.scripting.events.NameEvent;
import funkin.backend.scripting.events.StateEvent;

/**
 * Substate made for scripted cutscenes.
 * To add cutscenes to your songs, add a `cutscene.hx` file in your song's directory (ex: `songs/song/cutscene.hx`)
 */
class ScriptedCutscene extends Cutscene {
	var scriptPath:String;
	var script:Script;

	public function new(scriptPath:String, callback:Void->Void) {
		super(callback);

		script = Script.create(this.scriptPath = Paths.script(Path.withoutExtension(scriptPath), null, scriptPath.startsWith('assets')));
		script.setPublicMap(PlayState.instance.scripts.publicVariables);
		script.setParent(this);
		script.load();
	}

	public override function create() {
		super.create();
		script.call("create");

		if(Std.isOfType(script, DummyScript))
			onErrorScriptLoading();
	}

	public function onErrorScriptLoading() {
		Logs.trace('Could not find script for scripted cutscene at "${scriptPath}"', ERROR, RED);
		close();
	}

	public override function pauseCheck():Bool
	{
		var shouldClose = super.pauseCheck();
		script.call("pauseCheck", [shouldClose]);
		return shouldClose;
	}

	public override function update(elapsed:Float)
	{
		script.call("update", [elapsed]);
		super.update(elapsed);
		script.call("postUpdate", [elapsed]);
	}

	public override function pauseCutscene()
	{
		var event = new CancellableEvent();
		script.call("pauseCutscene", [event]);
		if(!event.cancelled) super.pauseCutscene();
	}

	public override function onSkipCutscene(event:NameEvent)
	{
		script.call("onSkipCutscene", [event]);
		if(!event.cancelled) super.onSkipCutscene(event);
	}

	public override function onRestartCutscene(event:NameEvent)
	{
		script.call("onRestartCutscene", [event]);
		if(!event.cancelled) super.onRestartCutscene(event);
	}

	public override function onResumeCutscene(event:NameEvent)
	{
		script.call("onResumeCutscene", [event]);
		if(!event.cancelled) super.onResumeCutscene(event);
	}

	public override function measureHit(curMeasure:Int)
	{
		super.measureHit(curMeasure);
		script.call("measureHit", [curMeasure]);
	}

	public override function beatHit(curBeat:Int)
	{
		super.beatHit(curBeat);
		script.call("beatHit", [curBeat]);
	}

	public override function stepHit(curStep:Int)
	{
		super.stepHit(curStep);
		script.call("stepHit", [curStep]);
	}

	public override function openSubState(sub:FlxSubState)
	{
		var event = EventManager.get(StateEvent).recycle(sub);
		script.call("onSubstateClose", [event]);
		if(!event.cancelled) super.openSubState(event.substate is FlxSubState ? cast event.substate : sub);
	}

	public override function closeSubState()
	{
		var event = EventManager.get(StateEvent).recycle(subState);
		script.call("onSubstateOpen", [event]);
		if(!event.cancelled) super.closeSubState();
	}

	public override function destroy() {
		script.call("destroy");
		script.destroy();
		super.destroy();
	}

	// VIDEOS
	#if REGION
	public function startVideo(path:String, ?callback:Void->Void) {
		persistentDraw = false;
		openSubState(new VideoCutscene(path, function() {
			if (callback != null)
				callback();
		}));
	}

	public var isVideoPlaying(get, never):Bool;

	private inline function get_isVideoPlaying()
		return subState is VideoCutscene;
	#end

	// DIALOGUE
	#if REGION
	public function startDialogue(path:String, ?callback:Void->Void) {
		persistentDraw = true;
		openSubState(new DialogueCutscene(path, function() {
			if (callback != null)
				callback();
		}));
	}

	public var isDialoguePlaying(get, never):Bool;

	private inline function get_isDialoguePlaying()
		return subState is DialogueCutscene;
	#end
}
