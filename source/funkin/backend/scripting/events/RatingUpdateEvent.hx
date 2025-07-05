package funkin.backend.scripting.events;

final class RatingUpdateEvent extends CancellableEvent {
	/**
		New combo (may be null if no ratings were found)
	**/
	public var rating:Null<ComboRating>;
	/**
		Old combo (may be null)
	**/
	public var oldRating:Null<ComboRating>;

}