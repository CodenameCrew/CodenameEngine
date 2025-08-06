package funkin.backend.scripting.events.healthicon;

import flixel.util.typeLimit.OneOfTwo;

final class HealthIconChangeEvent extends CancellableEvent {
	/**
	 * Animation State
	 */
	public var anim:OneOfTwo<String, Int>;

	/**
	 * The health icon
	 */
	public var healthIcon:funkin.game.HealthIcon;
}