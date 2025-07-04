package funkin.backend;

import funkin.backend.system.framerate.Framerate;
import funkin.backend.system.GraphicCacheSprite;
import funkin.backend.system.Controls;
import funkin.backend.scripting.DummyScript;
import flixel.FlxState;
import flixel.FlxSubState;
import funkin.backend.scripting.events.*;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.ScriptPack;
import funkin.backend.system.interfaces.IBeatReceiver;
import funkin.backend.system.Conductor;
import funkin.options.PlayerSettings;

class MusicBeatState extends FlxState implements IBeatReceiver
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	/**
	 * Dummy sprite used to cache graphics to GPU.
	 */
	public var graphicCache:GraphicCacheSprite = new GraphicCacheSprite();
	/**
	 * Whenever the Conductor auto update should be enabled or not.
	 */
	public var cancelConductorUpdate:Bool = false;

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

	/**
	 * Current injected script attached to the state. To add one, create a file at path "data/states/stateName" (ex: data/states/FreeplayState)
	 */
	public var stateScripts:ScriptPack;

	public var scriptsAllowed:Bool = true;

	public static var lastScriptName:String = null;
	public static var lastStateName:String = null;

	public var scriptName:String = null;

	public static var skipTransOut:Bool = false;
	public static var skipTransIn:Bool = false;

	public static var ALLOW_DEBUG_RELOAD:Bool = true;

	inline function get_controls():Controls
		return PlayerSettings.solo.controls;
	inline function get_controlsP1():Controls
		return PlayerSettings.player1.controls;
	inline function get_controlsP2():Controls
		return PlayerSettings.player2.controls;

	public function new(scriptsAllowed:Bool = true, ?scriptName:String) {
		super();
		this.scriptsAllowed = #if SOFTCODED_STATES scriptsAllowed #else false #end;

		if(lastStateName != (lastStateName = Type.getClassName(Type.getClass(this)))) {
			lastScriptName = null;
		}
		this.scriptName = scriptName != null ? scriptName : lastScriptName;
		lastScriptName = this.scriptName;
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

		if (_requestSubStateReset) {
			_requestSubStateReset = false;
			resetSubState();
		}

		if (/*subState == null && */(ALLOW_DEBUG_RELOAD && controls.DEBUG_RELOAD)) {
			Logs.trace("Reloading Current State...", INFO, YELLOW);
			FlxG.resetState();
		}

		if (subState != null)
			subState.tryUpdate(elapsed);
	}

	override function create()
	{
		loadScript();
		Framerate.offset.y = 0;
		super.create();
		call("create");
	}

	public override function createPost() {
		super.createPost();
		persistentUpdate = true;
		call("postCreate");
		if (!skipTransIn)
			openSubState(new MusicBeatTransition(null));
		skipTransIn = false;
		skipTransOut = false;
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
		for(e in members) if (e != null && e is IBeatReceiver) cast(e, IBeatReceiver).stepHit(curStep);
		call("stepHit", [curStep]);
	}

	@:dox(hide) public function beatHit(curBeat:Int):Void
	{
		for(e in members) if (e != null && e is IBeatReceiver) cast(e, IBeatReceiver).beatHit(curBeat);
		call("beatHit", [curBeat]);
	}

	@:dox(hide) public function measureHit(curMeasure:Int):Void
	{
		for(e in members) if (e != null && e is IBeatReceiver) cast(e, IBeatReceiver).measureHit(curMeasure);
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
		graphicCache.destroy();
		call("destroy");
		stateScripts = FlxDestroyUtil.destroy(stateScripts);
	}

	public override function draw() {
		graphicCache.draw();
		var e = event("draw", EventManager.get(DrawEvent).recycle());
		if (!e.cancelled)
			super.draw();
		event("postDraw", e);
	}

	public override function switchTo(nextState:FlxState) {
		var e = event("onStateSwitch", EventManager.get(StateEvent).recycle(nextState));
		if (e.cancelled)
			return false;

		if (skipTransOut)
			return true;
		if (subState is MusicBeatTransition && cast(subState, MusicBeatTransition).newState != null)
			return true;
		openSubState(new MusicBeatTransition(nextState));
		persistentUpdate = false;
		return false;
	}

	public override function onFocus() {
		super.onFocus();
		call("onFocus");
	}

	public override function onFocusLost() {
		super.onFocusLost();
		call("onFocusLost");
	}

	public override function resetSubState() {
		super.resetSubState();
		if (subState != null && subState is MusicBeatSubstate) {
			cast(subState, MusicBeatSubstate).parent = this;
			cast(subState, MusicBeatSubstate).onSubstateOpen();
		}
	}
}
