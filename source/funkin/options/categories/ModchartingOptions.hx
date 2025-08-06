package funkin.options.categories;

#if MODCHARTING_FEATURES
class ModchartingOptions extends TreeMenuScreen {
	public override function new() {
		super("Modcharting Options", "Customize your modcharting experience.");
		add(new NumOption(
			"Hold Subdivisions",
			"Subdivides the arrow's hold/sustain tail for smoother visuals, higher values improve quality but can hurt performance",
			1, // minimum
			128, // maximum
			1, // change
			"modchartingHoldSubdivisions" // save name
			)); // callback
	}
}
#end