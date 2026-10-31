package funkin.game.modchart;

import funkin.game.modchart.drawing.ModchartDrawing;
import foxlite.FoxScene;

// for now
class ModchartManager/* extends FoxScene */ extends flixel.FlxBasic {
	public static var references:Map<String, Class<BaseModifier>>;
	public var storage:Array<Map<String, Float>> = [];
	public var aliases:Map<String, String> = [];

	public var madeRef:Map<String, Bool> = [];
	public var allMods:Array<BaseModifier> = [];

	public var curField:Int = 0;
	public var curLane:Int = 0;
	public var laneCount:Int = 1;

	public var drawer:ModchartDrawing;
	public var strumLines(get, never):FlxTypedGroup<StrumLine>;

	static final digitRegex = ~/\d/g;

	public function new(strumLines:FlxTypedGroup<StrumLine>) {
		//super(FlxG.width, FlxG.height);
		super();
		drawer = new ModchartDrawing(this, strumLines);
		for (field in strumLines.members) {
			storage.push([]);
			laneCount = MathUtil.maxInt(laneCount, field.members.length, field.data.keyCount);
		}
	}
	override function destroy() {
		drawer.removeSignals();
		super.destroy();
	}

	public function get(name:String, ?field:Int = -1) {
		field = FlxMath.maxInt(field, 0);

		name = name.toLowerCase();
		if (storage[field].exists(name)) {
			return storage[field].get(name);
		} else if (aliases.exists(name)) {
			return get(aliases[name], field);
		} else if (tryReference(name)) {
			return get(name, field);
		}

		return 0;
	}
	public function setNow(name:String, value:Float, ?field:Int = -1) {
		if (field < 0) {
			for (i in 0...storage.length)
				setNow(name, value, i);
			return;
		}

		name = name.toLowerCase();
		if (storage[field].exists(name)) {
			storage[field].set(name, value);
			updateActive(field);
		} else if (aliases.exists(name)) {
			setNow(aliases[name], value, field);
		} else if (tryReference(name)) {
			setNow(name, value, field);
		}
	}


	public function tryReference(ref:String) {
		if (madeRef.exists(ref))
			return false;

		var getRef = ref;
		if (!references.exists(getRef)) {
			inline function fail() {
				madeRef.set(ref, false);
				return false;
			}

			if (digitRegex.match(getRef)) {
				var matchedOne = false;
				function digitMap(e) {
					final result = matchedOne ? "" : "%c";
					matchedOne = true;
					return result;
				}
				getRef = digitRegex.map(getRef, digitMap);
				if (!references.exists(getRef))
					return fail();
			} else
				return fail();
		}

		getInstance(references[getRef]);
		madeRef.set(ref, true);
		return true;
	}
	public function getInstance(cls:Class<BaseModifier>) {
		for (mod in allMods) {
			if (Std.isOfType(mod, cls))
				return mod;
		}
		return addMod(Type.createInstance(cls, [this]));
	}
	public function addMod(mod:BaseModifier) {
		var idx = allMods.length;
		while (idx > 0 && allMods[idx - 1].priority > mod.priority)
			--idx;
		allMods.insert(idx, mod);
		mod.ready();
		return mod;
	}

	public function updateActive(field:Int) {
		if (field < 0) {
			for (i in 0...storage.length)
				updateActive(i);
		} else {
			for (mod in allMods)
				mod.active[field] = mod.isActive(field);
		}
	}

	inline function get_strumLines()
		return drawer.strumLines;
}