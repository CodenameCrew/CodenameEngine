package funkin.backend.scripting.events;

import funkin.backend.week.WeekData;

final class WeekSelectEvent extends CancellableEvent {
	/**
	 * Week that is going to be selected
	 */
	public var week:WeekData;

	/**
	 * The difficulty that has been selected
	 */
	public var difficulty:String;

	/**
	 * At which emplacement the week is. Goes from 0 to the number of weeks - 1.
	 */
	public var weekID:Int;

	/**
	 * At which emplacement the difficulty is. Goes from 0 to the number of weeks - 1.
	 */
	public var difficultyID:Int;
}