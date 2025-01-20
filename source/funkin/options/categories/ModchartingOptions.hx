package funkin.options.categories;

#if MODCHARTING_FEATURES
class ModchartingOptions extends OptionsScreen {
	public override function new() {
		super("Modcharting Options", "Customize your modcharting experience.");
		add(new NumOption(
			"Hold Subdivisions",
			"Softens the tail/hold/sustain of the arrows by subdividing it, giving them greater quality. By higher the subdivisions number is, performance will be affected.",
			1, // minimum
			128, // maximum
			1, // change
			"hold_subs" // save name
			)); // callback
	}
}
#end