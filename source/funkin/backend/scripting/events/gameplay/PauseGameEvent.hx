package funkin.backend.scripting.events.gameplay;

import funkin.backend.utils.FunkinParentDisabler.ParentDisableable;

final class PauseGameEvent extends CancellableEvent {
	/**
	 * List of ParentDisableable instances that FunkinParentDisabler will exclude from
	 * its disabling list on instanciation. Instances in the list will startDelay enabled.
	 */
	public var excludeList:Array<ParentDisableable>;

	/**
	 * Whether the pause will be allowed to trigger the Gitaroo pause menu easter egg.
	 */
	public var allowGitaroo:Bool;
}