package funkin.game.modchart;

import funkin.game.modchart.drawing.ModchartDrawing;

typedef ModifierFloat = Float;
typedef ModifierBool = Bool;
typedef ModifierInt = Int;

@:autoBuild(funkin.backend.system.macros.ModifierMacro.createModifier())
class BaseModifier {
	public var priority:Int = 0;
	public var active:Array<Bool> = [];

	public var parent:ModchartManager;

	public function new(parent:ModchartManager, priority:Int) {
		this.parent = parent;
		this.priority = priority;
	}

	public function edit(queue:QueuedDraw) {}

	public function ready() {}
	public function isActive(field:Int) {return false;}

	public function get(name:String, field:Int) {
		return parent.storage[field].get(name);
	}
	public function set(name:String, value:Float, field:Int) {
		if (field < 0) {
			for (i in 0...parent.storage.length) {
				parent.storage[i].set(name, value);
				active[i] = isActive(i);
			}
		} else if (field < parent.storage.length) {
			parent.storage[field].set(name, value);
			active[field] = isActive(field);
		}
	}
}