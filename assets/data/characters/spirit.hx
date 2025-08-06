import flixel.addons.effects.FlxTrail;

var self = this;
var trail:FlxTrail;
function postCreate() {
	trail = new FlxTrail(self, null, 4, 24, 0.3, 0.069);
}

var toAdd:Bool = true;  // Using this just to make sure
function update(elapsed) {
	if(toAdd) {
		toAdd = false;
		PlayState.instance.insert(PlayState.instance.members.indexOf(self), trail);
		disableScript();
	}
}