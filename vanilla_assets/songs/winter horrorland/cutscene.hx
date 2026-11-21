var self = this;
__script__.setParent(PlayState.instance);

function create() {
	FlxG.sound.play(Paths.sound('Lights_Turn_On'));
	camFollow.setPosition(500, -2050);
	FlxG.camera.focusOn(camFollow.getPosition());
	FlxG.camera.zoom = 1.5;

	FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
		ease: FlxEase.quadInOut, startDelay: 0.8,
		onComplete: function(twn:FlxTween)
		{
			self.close();
		}
	});
}