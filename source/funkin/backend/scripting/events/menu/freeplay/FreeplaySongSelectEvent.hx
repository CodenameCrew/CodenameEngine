package funkin.backend.scripting.events.menu.freeplay;

import funkin.menus.FreeplayState.FreeplayGameMode;

final class FreeplaySongSelectEvent extends CancellableEvent {
	/**
	 * Song name that is about to be played
	 */
	public var song:String;
	/**
	 * Difficulty name
	 */
	public var difficulty:String;
	/**
	 * Variation Name
	 */
	public var variant:String;
	/**
	 * Used game mode's data.
	 */
	public var gameMode:FreeplayGameMode;


	// Backwards compat
	@:noCompletion public var opponentMode(get, set):Bool;
	@:noCompletion private function get_opponentMode() return gameMode.modeID == "codename.opponent" || gameMode.modeID == "codename.coop-opponent";
	@:noCompletion private function set_opponentMode(val:Bool) {
		gameMode = coopMode ?
			(val ? new FreeplayGameMode("Co-Op Mode (Switched)", "codename.coop-opponent", ["coop-switched", "opponent", "coop"]) : new FreeplayGameMode("Opponent Mode", "codename.opponent", ["opponent"])) :
			(val ? new FreeplayGameMode("Opponent Mode", "codename.opponent", ["opponent"]) : null);
		return val;
	}
	@:noCompletion public var coopMode(get, set):Bool;
	@:noCompletion private function get_coopMode() return gameMode.modeID == "codename.coop" || gameMode.modeID == "codename.coop-opponent";
	@:noCompletion private function set_coopMode(val:Bool) {
		gameMode = opponentMode ?
			(val ? new FreeplayGameMode("Co-Op Mode (Switched)", "codename.coop-opponent", ["coop-switched", "opponent", "coop"]) : new FreeplayGameMode("Co-Op Mode", "codename.coop", ["coop"])) :
			(val ? new FreeplayGameMode("Co-Op Mode", "codename.coop", ["coop"]) : null);
		return val;
	}
}