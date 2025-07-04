package funkin.backend;

import flixel.FlxState;
import funkin.backend.scripting.events.*;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.ScriptPack;
import funkin.backend.scripting.DummyScript;
import funkin.backend.system.interfaces.IBeatReceiver;
import funkin.backend.system.Conductor;
import funkin.backend.system.Controls;
import funkin.options.PlayerSettings;
import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState implements IBeatReceiver
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	/**
	 * Current step
	 */
	public var curStep(get, never):Int;
	/**
	 * Current beat
	 */
	public var curBeat(get, never):Int;
	/**
	 * Current beat
	 */
	public var curMeasure(get, never):Int;
	/**
	 * Current step, as a `Float` (ex: 4.94, instead of 4)
	 */
	public var curStepFloat(get, never):Float;
	/**
	 * Current beat, as a `Float` (ex: 1.24, instead of 1)
	 */
	public var curBeatFloat(get, never):Float;
	/**
	 * Current beat, as a `Float` (ex: 1.24, instead of 1)
	 */
	public var curMeasureFloat(get, never):Float;
	/**
	 * Current song position (in milliseconds).
	 */
	public var songPos(get, never):Float;

	inline function get_curStep():Int
		return Conductor.curStep;
	inline function get_curBeat():Int
		return Conductor.curBeat;
	inline function get_curMeasure():Int
		return Conductor.curMeasure;
	inline function get_curStepFloat():Float
		return Conductor.curStepFloat;
	inline function get_curBeatFloat():Float
		return Conductor.curBeatFloat;
	inline function get_curMeasureFloat():Float
		return Conductor.curMeasureFloat;
	inline function get_songPos():Float
		return Conductor.songPosition;

	/**
	 * Current injected script attached to the state. To add one, create a file at path "data/states/stateName" (ex: "data/states/PauseMenuSubstate.hx")
	 */
	public var stateScripts:ScriptPack;

	public var scriptsAllowed:Bool = true;

	public var scriptName:String = null;

	/**
	 * Game Controls. (All players / Solo)
	 */
	public var controls(get, never):Controls;

	/**
	 * Game Controls (Player 1 only)
	 */
	public var controlsP1(get, never):Controls;

	/**
	 * Game Controls (Player 2 only)
	 */
	public var controlsP2(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.solo.controls;
	inline function get_controlsP1():Controls
		return PlayerSettings.player1.controls;
	inline function get_controlsP2():Controls
		return PlayerSettings.player2.controls;


	public function new(scriptsAllowed:Bool = true, ?scriptName:String) {
		super();
		this.scriptsAllowed = #if SOFTCODED_STATES scriptsAllowed #else false #end;
		this.scriptName = scriptName;
	}

	function loadScript() {
		var className = Type.getClassName(Type.getClass(this));
		if (stateScripts == null)
			(stateScripts = new ScriptPack(className)).setParent(this);
		if (scriptsAllowed) {
			if (stateScripts.scripts.length == 0) {
				var scriptName = this.scriptName != null ? this.scriptName : className.substr(className.lastIndexOf(".")+1);
				for (i in funkin.backend.assets.ModsFolder.getLoadedMods()) {
					var path = Paths.script('data/states/${scriptName}/LIB_$i');
					var script = Script.create(path);
					if (script is DummyScript) continue;
					script.remappedNames.set(script.fileName, '$i:${script.fileName}');
					stateScripts.add(script);
					script.load();
				}
			}
			else stateScripts.reload();
		}
	}

	public override function tryUpdate(elapsed:Float):Void
	{
		if (persistentUpdate || subState == null) {
			call("preUpdate", [elapsed]);
			update(elapsed);
			call("postUpdate", [elapsed]);
		}

		// if (subState == null && (MusicBeatState.ALLOW_DEBUG_RELOAD && controls.DEBUG_RELOAD)) {
		// 	Logs.trace("Reloading Current SubState...", INFO, YELLOW);
		// 	var test = Type.createInstance(Type.getClass(this), [this.scriptsAllowed, this.scriptName]);
		// 	parent.openSubState(test);
		// }

		if (_requestSubStateReset) {
			_requestSubStateReset = false;
			resetSubState();
		}

		if (subState != null)
			subState.tryUpdate(elapsed);
	}

	override function close() {
		var event = event("onClose", new CancellableEvent());
		if (!event.cancelled) {
			super.close();
			call("onClosePost");
		}
	}

	override function create()
	{
		loadScript();
		super.create();
		call("create");
	}

	public override function createPost() {
		super.createPost();
		call("postCreate");
	}
	public function call(name:String, ?args:Array<Dynamic>, ?defaultVal:Dynamic):Dynamic {
		// calls the function on the assigned script
		if(stateScripts != null)
			return stateScripts.call(name, args);
		return defaultVal;
	}

	public function event<T:CancellableEvent>(name:String, event:T):T {
		if(stateScripts != null)
			stateScripts.call(name, [event]);
		return event;
	}

	override function update(elapsed:Float)
	{
		call("update", [elapsed]);
		super.update(elapsed);
	}

	@:dox(hide) public function stepHit(curStep:Int):Void
	{
		for(e in members) if (e is IBeatReceiver) cast(e, IBeatReceiver).stepHit(curStep);
		call("stepHit", [curStep]);
	}

	@:dox(hide) public function beatHit(curBeat:Int):Void
	{
		for(e in members) if (e is IBeatReceiver) cast(e, IBeatReceiver).beatHit(curBeat);
		call("beatHit", [curBeat]);
	}

	@:dox(hide) public function measureHit(curMeasure:Int):Void
	{
		for(e in members) if (e is IBeatReceiver) cast(e, IBeatReceiver).measureHit(curMeasure);
		call("measureHit", [curMeasure]);
	}

	/**
	 * Shortcut to `FlxMath.lerp` or `CoolUtil.lerp`, depending on `fpsSensitive`
	 * @param v1 Value 1
	 * @param v2 Value 2
	 * @param ratio Ratio
	 * @param fpsSensitive Whenever the ratio should not be adjusted to run at the same speed independent of framerate.
	 */
	public function lerp(v1:Float, v2:Float, ratio:Float, fpsSensitive:Bool = false) {
		if (fpsSensitive)
			return FlxMath.lerp(v1, v2, ratio);
		else
			return CoolUtil.fpsLerp(v1, v2, ratio);
	}

	/**
	 * SCRIPTING STUFF
	 */
	public override function openSubState(subState:FlxSubState) {
		var e = event("onOpenSubState", EventManager.get(StateEvent).recycle(subState));
		if (!e.cancelled)
			super.openSubState(subState);
	}

	public override function onResize(w:Int, h:Int) {
		super.onResize(w, h);
		event("onResize", EventManager.get(ResizeEvent).recycle(w, h, null, null));
	}

	public override function destroy() {
		super.destroy();
		call("destroy");
		stateScripts = FlxDestroyUtil.destroy(stateScripts);
	}

	public override function switchTo(nextState:FlxState) {
		var e = event("onStateSwitch", EventManager.get(StateEvent).recycle(nextState));
		if (e.cancelled)
			return false;
		return super.switchTo(nextState);
	}

	public override function onFocus() {
		super.onFocus();
		call("onFocus");
	}

	public override function onFocusLost() {
		super.onFocusLost();
		call("onFocusLost");
	}

	public var parent:FlxState;

	public function onSubstateOpen() {

	}

	public override function resetSubState() {
		if (subState != null && subState is MusicBeatSubstate) {
			cast(subState, MusicBeatSubstate).parent = this;
			super.resetSubState();
			if (subState != null)
				cast(subState, MusicBeatSubstate).onSubstateOpen();
			return;
		}
		super.resetSubState();
	}
}
