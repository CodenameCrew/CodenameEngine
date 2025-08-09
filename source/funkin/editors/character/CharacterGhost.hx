package funkin.editors.character;

import funkin.backend.system.FakeCamera.FakeCallCamera;
import openfl.geom.ColorTransform;
import flixel.animation.FlxAnimation;
import funkin.game.Character;

typedef AtlasState = {
	var oldAnim:String;
	var oldFrame:Int;
	var oldTick:Float;
	var oldPlaying:Bool;
};

class CharacterGhost extends Character {
	public var ghosts:Array<String> = [];
	public override function draw() @:privateAccess {
		ghostDraw = FakeCallCamera.instance.ignoreDraws = true;

		var wasInvalidFrame:Bool = !colorTransform.__isDefault(false);
		colorTransform.__identity();

		if (animateAtlas != null) {
			storeAtlasState();
			for (anim in ghosts) {
				animateAtlas.anim.play(anim, true, false, 0);
				setAnimOffset(anim);

				alpha = 0.4; color = 0xFFAEAEAE;
				super.draw();
			}

			if (ghosts.length > 0) restoreAtlasState();
		}
		else {
			for (anim in ghosts) @:privateAccess {
				alpha = 0.4; color = 0xFFAEAEAE;
	
				var flxanim:FlxAnimation = animation._animations.get(anim);
				var frameIndex:Int = flxanim.frames.getDefault([0])[0];
				frame = frames.frames[frameIndex];
	
				setAnimOffset(anim);
				super.draw();
			}

			if (ghosts.length > 0)
				frame = frames.frames[animation.frameIndex];
		}
		ghostDraw = FakeCallCamera.instance.ignoreDraws = false; 

		alpha = 1; color = 0xFFFFFFFF;
		if (wasInvalidFrame) {
			frameOffset.set(0, 0); 
			offset.set(globalOffset.x * (isPlayer != playerOffsets ? 1 : -1), -globalOffset.y);
			colorTransform.color = 0xFFEF0202;
		} else
			setAnimOffset(animateAtlas != null ? atlasPlayingAnim : animation.name);
		
		super.draw();
	}

	public function setAnimOffset(anim:String) {
		var daOffset:FlxPoint = animOffsets.get(anim);
		if (daOffset != null) {
			frameOffset.set(daOffset.x, daOffset.y);
			daOffset.putWeak();
		}

		offset.set(globalOffset.x * (isPlayer != playerOffsets ? 1 : -1), -globalOffset.y);
	}

	// This gets annoying lmao -lunar
	private var atlasState:AtlasState = null;
	public function storeAtlasState():AtlasState @:privateAccess {
		return atlasState = {
			oldAnim: atlasPlayingAnim,
			oldFrame: animateAtlas.anim.curFrame,
			oldTick: animateAtlas.anim._tick,
			oldPlaying: animateAtlas.anim.isPlaying,
		};
	}

	public function restoreAtlasState(state:AtlasState = null) @:privateAccess {
		if (state == null) state = atlasState;

		animateAtlas.anim.play(state.oldAnim, true, false, state.oldFrame);
		animateAtlas.anim._tick = state.oldTick;
		animateAtlas.anim.isPlaying = state.oldPlaying;
	}
}