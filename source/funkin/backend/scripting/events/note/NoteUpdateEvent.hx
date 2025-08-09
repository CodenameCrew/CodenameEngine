package funkin.backend.scripting.events.note;

import funkin.game.Note;
import funkin.game.Strum;

final class NoteUpdateEvent extends CancellableEvent {
	@:dox(hide) public var __updateHitWindow = true;
	@:dox(hide) public var __autoCPUHit = true;
	@:dox(hide) public var __reposNote = true;
	/**
	 * Note that is being updated
	 */
	public var note:Note;

	/**
	 * Time elapsed since last frame
	 */
	public var elapsed:Null<Float>;

	/**
	 * Note's strum (can be changed)
	 */
	public var strum:Strum;

	/**
	 * Cancels the hit window update.
	 */
	public function cancelWindowUpdate() {
		__updateHitWindow = false;
	}
	@:dox(hide) public function preventWindowUpdate() { cancelWindowUpdate(); }

	/**
	 * Cancels the automatic CPU hit.
	 */
	public function cancelAutoCPUHit() {
		__autoCPUHit = false;
	}
	@:dox(hide) public function preventAutoCPUHit() { cancelAutoCPUHit(); }

	/**
	 * Cancels the note position update (note will freeze).
	 */
	public function cancelPositionUpdate() {
		__reposNote = false;
	}
	@:dox(hide) public function preventPositionUpdate() { cancelPositionUpdate(); }
}