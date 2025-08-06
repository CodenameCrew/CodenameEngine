var loopedTimer:FlxTimer;  // Hey! a man has fallen into the river in lego city! and if youre asking why this is here, you shall disappear!  - Nex
var bgFade:FlxSprite;
var hand:FlxSprite;

function postCreate() {
	bgFade = new FlxSprite().makeSolid(FlxG.width + 100, FlxG.height + 100, 0xFFB3DFd8);
	bgFade.screenCenter();
	bgFade.scrollFactor.set();
	bgFade.alpha = 0;
	cutscene.insert(0, bgFade);

	loopedTimer = new FlxTimer().start(0.83, function(tmr:FlxTimer)
	{
		bgFade.alpha += (1 / 5) * 0.7;
		if (bgFade.alpha > 0.7)
			bgFade.alpha = 0.7;
	}, 5);

	hand = new FlxSprite(0, 600).loadGraphic(Paths.image('stages/school/ui/hand_textbox'));
	hand.scale.set(4, 4);
	hand.updateHitbox();
}

var finished:Bool = false;
function close(event) {
	if(finished) return;
	else event.cancelled = true;
	cutscene.canProceed = false;

	cutscene.curMusic?.fadeOut(1, 0);
	for(c in cutscene.charMap) c.visible = false;

	loopedTimer.cancel();
	loopedTimer = new FlxTimer().start(0.2, function(tmr:FlxTimer)
	{
		if (tmr.elapsedLoops <= 5) {
			cutscene.dialogueBox.alpha -= 1 / 5;
			cutscene.dialogueBox.text.alpha -= 1 / 5;
			bgFade.alpha -= (1 / 5) * 0.7;
			hand.alpha -= 1 / 5;
		} else {
			finished = true;
			cutscene.close();
		}
	}, 6);
}

var time:Float = 0;
function update(elapsed:Float) {
	if(hand.visible = dialogueEnded) {
		hand.x = 1060 + Math.sin((time += elapsed) * Math.PI * 2) * 12;
		hand.x -= hand.x % hand.scale.x;
		hand.y -= hand.y % hand.scale.y;
	}
}

function postPlayBubbleAnim() {
	cutscene.remove(hand);
	if(active && visible)
		cutscene.add(hand);
}