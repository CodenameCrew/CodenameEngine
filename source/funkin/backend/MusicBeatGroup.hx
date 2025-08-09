package funkin.backend;

import funkin.backend.system.interfaces.IBeatReceiver;

/**
 * Group of FlxSprites, if the sprite implements `IBeatReceiver`, then beatHit, stepHit and measureHit will be called.
**/
class MusicBeatGroup extends FlxTypedSpriteGroup<FlxSprite> implements IBeatReceiver {
	public function beatHit(curBeat:Int) {
		for(e in members) if (e is IBeatReceiver) ({var _:IBeatReceiver = cast e;_;}).beatHit(curBeat);
	}
	public function stepHit(curStep:Int) {
		for(e in members) if (e is IBeatReceiver) ({var _:IBeatReceiver = cast e;_;}).stepHit(curStep);
	}
	public function measureHit(curMeasure:Int) {
		for(e in members) if (e is IBeatReceiver) ({var _:IBeatReceiver = cast e;_;}).measureHit(curMeasure);
	}
}