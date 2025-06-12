//
import funkin.backend.system.modules.FunkinCache;

function new()
    FunkinCache.instance.clearSecondLayer();

function update(elapsed:Float)
	if (FlxG.keys.justPressed.F5) FlxG.resetState();
