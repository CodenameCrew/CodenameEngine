package funkin.game.modchart;

class LaneModValue {
	var prefix:String = "";
	var suffix:String = "";
	var parent:BaseModifier;
	var manager(get, never):ModchartManager;
	var ignoreBase:Bool = false;
	var aliases:Array<String>;
	var def:Float = 0;

	public function new(prefix:String, suffix:String, ?def:Float = 0, ?aliases:Array<String>, ?ignoreBase:Bool = false) {
		this.prefix = prefix.toLowerCase();
		this.suffix = suffix.toLowerCase();
		this.def = def;
		this.aliases = aliases;
		this.ignoreBase = ignoreBase;
	}

	public function base() {
		return parent.get(prefix + suffix, manager.curField);
	}
	public function get(idx:Int):Float {
		return parent.get(prefix + idx + suffix, manager.curField);
	}

	public function ready(parent:BaseModifier) {
		this.parent = parent;
		for (i in 0...manager.storage.length) {
			final map = manager.storage[i];

			if (!ignoreBase)
				map.set(prefix + suffix, def);

			for (i in 0...manager.laneCount)
				map.set(prefix + i + suffix, def);
		}

		if (aliases != null) {
			for (alias in aliases) {
				if (!ignoreBase)
					manager.aliases.set(alias.replace("%c", ""), prefix + suffix);
	
				for (i in 0...manager.laneCount)
					manager.aliases.set(alias.replace("%c", Std.string(i)), prefix + i + suffix);
			}
		}
	}
	public function isActive(field:Int) {
		if (!ignoreBase && parent.get(prefix + suffix, field) != def)
			return true;

		for (i in 0...manager.laneCount) {
			if (parent.get(prefix + i + suffix, field) != def)
				return true;
		}
		return false;
	}

	function get_manager() {
		return parent.parent;
	}
}