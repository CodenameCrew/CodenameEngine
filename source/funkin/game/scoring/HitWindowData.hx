package funkin.game.scoring;

import haxe.ds.StringMap;

class HitWindowData
{
	public static function getWindows(preset:WindowPreset):StringMap<Float>
	{
		var map = new StringMap<Float>();

		switch (preset) {
			// Old Codename, really forgiving inputs (hard to get bad ratings)
			case CNE_CLASSIC:
				map.set("sick", 50.0);
				map.set("good", 187.5);
				map.set("bad", 225.0);
				map.set("shit", 250.0);
			// Week 7
			case FNF_CLASSIC:
				map.set("sick", 33.334);
				map.set("good", 125.0025);
				map.set("bad", 150.003);
				map.set("shit", 166.67);
			// V-Slice
			case FNF_VSLICE:
				map.set("sick", 45.0);
				map.set("good", 90.0);
				map.set("bad", 135.0);
				map.set("shit", 160.0);
			// Default, taken from Etterna
			case _:
				map.set("sick", 37.8);
				map.set("good", 75.6);
				map.set("bad", 113.4);
				map.set("shit", 180.0);
		}

		return map;
	}

	public static function scaleWindows(windows:StringMap<Float>, scale:Float):StringMap<Float>
	{
		var scaled = new StringMap<Float>();
		for (k in windows.keys())
			scaled.set(k, windows.get(k) * scale);
		return scaled;
	}

	public static function offsetWindows(windows:StringMap<Float>, offset:Float):StringMap<Float>
	{
		var adjusted = new StringMap<Float>();
		for (k in windows.keys())
			adjusted.set(k, windows.get(k) + offset);
		return adjusted;
	}
}

enum abstract WindowPreset(Int) from Int to Int
{
	var DEFAULT = 0;
	var CNE_CLASSIC = 1;
	var FNF_CLASSIC = 2;
	var FNF_VSLICE = 3;

	public function toString():String
	{
		return switch (cast this : WindowPreset)
		{
			case CNE_CLASSIC: "Codename (Classic)";
			case FNF_CLASSIC: "Funkin' (Week 7)";
			case FNF_VSLICE: "Funkin' (V-Slice)";
			case _: "Default";
		}
	}
}