package funkin.menus.ui;

import funkin.backend.scripting.events.CancellableEvent;
import funkin.backend.scripting.events.soundtray.*;
import funkin.backend.scripting.Script;
import flixel.system.ui.FlxSoundTray;
import openfl.text.TextFormat;

class FunkinSoundTray extends FlxSoundTray
{
	public var script:Script;

	// Ne_Eo wanted them since it would reduce lags for some people if activated  - Nex
	public var callsUpdate:Bool = true;
	public var callsPostUpdate:Bool = true;

	public function new()
	{
		script = Script.create(Paths.script('data/soundTray'));
		script.setParent(this);
		script.load();

		script.call("create");
		super();

		FlxSoundTray.volumeChangeSFX = Paths.sound('menu/volume');
		FlxSoundTray.volumeUpChangeSFX = null;
		FlxSoundTray.volumeDownChangeSFX = null;
		FlxSoundTray.volumeMaxChangeSFX = null;
		text.setTextFormat(new TextFormat(Paths.font("vcr.ttf")));

		script.call("postCreate");
	}

	public override function reloadText(checkIfNull:Bool = true, reloadDefaultTextFormat:Bool = true, displayTxt:String = "VOLUME", y:Float = 16)
	{
		var event = EventManager.get(SoundTrayTextEvent).recycle(checkIfNull, reloadDefaultTextFormat, displayTxt, y);
		script.call("reloadText", [event]);
		if (event.cancelled) return;

		super.reloadText(event.checkIfNull, event.reloadDefaultTextFormat, event.displayTxt, event.y);
		script.call("postReloadText", [event]);
	}

	public override function reloadDtf()
	{
		var event = new CancellableEvent();
		script.call("reloadDtf", [event]);
		if (event.cancelled) return;

		super.reloadDtf();
		script.call("postReloadDtf");
	}

	public override function regenerateBarsArray()
	{
		var event = new CancellableEvent();
		script.call("regenerateBarsArray", [event]);
		if (event.cancelled) return;

		super.regenerateBarsArray();
		script.call("postRegenerateBarsArray");
	}

	public override function regenerateBars()
	{
		var event = new CancellableEvent();
		script.call("regenerateBars", [event]);
		if (event.cancelled) return;

		super.regenerateBars();
		script.call("postRegenerateBars");
	}

	public override function update(elapsed:Float)
	{
		if (callsUpdate) script.call("update", [elapsed]);
		super.update(elapsed);
		if (callsPostUpdate) script.call("postUpdate", [elapsed]);
	}

	public override function saveSoundPreferences()
	{
		var event = new CancellableEvent();
		script.call("saveSoundPreferences", [event]);
		if (event.cancelled) return;

		super.saveSoundPreferences();
		script.call("postSaveSoundPreferences");
	}

	public override function show(up:Bool = false)
	{
		var event = EventManager.get(SoundTrayShowEvent).recycle(up);
		script.call("show", [event]);
		if (event.cancelled) return;

		super.show(event.up);
		script.call("postShow", [event]);
	}

	public override function screenCenter()
	{
		var event = new CancellableEvent();
		script.call("screenCenter", [event]);
		if (event.cancelled) return;

		super.screenCenter();
		script.call("postScreenCenter");
	}

	private override function __cleanup()
	{
		script.call("destroy");
		script.destroy();
		super.__cleanup();
	}
}