package funkin.backend.scripting.events.dialogue;

/**
 * CANCEL this event to prevent continuing with the next dialogue.
 *
 * **NOTE**: To access the current, past or next lines, use `curLine`, `lastLine` or also `dialogueLines` in the `DialogueCutscene` class (they're globals and can be accessed at any time as long as the Dialogue Cutscene is active)!
 */
final class DialogueNextLineEvent extends CancellableEvent
{
	/**
	 * If the dialogue has just been opened.
	 */
	public var playFirst:Bool = false;
}