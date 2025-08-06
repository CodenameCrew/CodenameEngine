package funkin.backend.scripting.events.menu;

final class MenuChangeEvent extends CancellableEvent {
	/**
	 * Value before the change
	 */
	public var oldValue:Int;

	/**
	 * Value after the change
	 */
	public var value:Int;

	/**
	 * Amount of change
	 */
	public var change:Int;

	/**
	 * Whenever the menu SFX should be played.
	 */
	public var playMenuSFX:Bool = true;
}