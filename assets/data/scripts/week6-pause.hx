import funkin.ui.FunkinText;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxAxes;

var pixelScript:Script = game.scripts.getByName("pixel.hx");
var pauseCam = new FlxCamera();

var bg:FlxSprite;
var hand:FlxSprite;

var texts:Array<FlxText> = [];

var isThorns = PlayState.SONG.meta.name.toLowerCase() == "thorns";

function create(event) {
	menuItems.remove("Change Controls");

	// cancel default pause menu!!
	event.cancel();

	event.music = isThorns ? "pixel/LunchboxScary" : "pixel/breakfast";

	// allowing this pause script even if the pixel script is not loaded  - Nex
	pixelScript?.call("pixelCam", [pauseCam]);

	FlxG.cameras.add(pauseCam, false);
	cameras = [pauseCam];

	pauseCam.bgColor = isThorns ? 0x88000000 : 0x88FF99CC;
	pauseCam.alpha = 0;

	bg = new FlxSprite(44 * 6, 14 * 6, Paths.image('stages/school/pause/bg'));
	bg.antialiasing = false;
	if (isThorns) bg.color = 0xFF000000;
	bg.scale.set(6, 6);
	bg.updateHitbox();
	bg.scale.y = 4;
	add(bg);

	songText = new FlxText(0, 0, 0, "Pause", 8, false);
	confText(songText);
	add(songText);

	for (e in menuItems) {
		text = new FlxText(0, 0, 0, e, 8, false);
		confText(text);
	}

	hand = new FlxSprite().loadGraphic(Paths.image('stages/school/ui/hand_textbox'));
	hand.antialiasing = false;
	hand.scale.set(6, 6);
	hand.updateHitbox();
	add(hand);

	placePause();

	FlxTween.tween(bg.scale, {y: 6}, 0.75, {ease: FlxEase.elasticOut});


	FlxG.sound.play(Paths.sound(isThorns ? 'pixel/ANGRY' : 'pixel/clickText'));
}

function confText(text) {
	text.scale.set(6, 6);
	text.updateHitbox();
	text.screenCenter(FlxAxes.X);
	text.borderStyle = FlxTextBorderStyle.OUTLINE;
	if (!isThorns) text.borderColor = 0xFF953E3E;

	text.antialiasing = false;
	texts.push(text);
	add(text);
}

function destroy() if (FlxG.cameras.list.contains(pauseCam))
	FlxG.cameras.remove(pauseCam);

var canDoShit = true;
var time:Float = 0;
function update(elapsed) {
	pixelScript?.call("postUpdate", [elapsed]);

	pauseCam.alpha = lerp(pauseCam.alpha, 1, 0.25);
	time += elapsed;

	var curText = texts[curSelected + 1];
	if (curText != null) {
		hand.setPosition(curText.x - hand.width - 24 + (Math.sin(time * Math.PI * 2) * 12), curText.y + ((text.height) / 2) - 6);
		hand.x -= hand.x % 6;
		hand.y -= hand.y % 6;
	}

	if (FlxG.touches != null) for (touch in FlxG.touches.list) {
		if (!touch.justReleased) continue;
		for (i in 0...menuItems.length) {
			var opt = texts[i + 1];
			if (opt == null || !touch.overlaps(opt, pauseCam)) continue;
			if (curSelected != i) {
				curSelected = i;
				scrollSFX.play();
			} else enterOption();
			break;
		}
	}

	changeSelection((controls.UP_P ? -1 : 0) + (controls.DOWN_P ? 1 : 0) - FlxG.mouse.wheel);

	if (controls.ACCEPT) enterOption();
}

function placePause() {
	var pad = 16 * 6;
	var boxW = 125 * 6;
	var boxH = 99 * 6;
	var left = bg.x + pad;
	var top = bg.y + pad;
	var right = bg.x + boxW - pad;
	var bottom = bg.y + boxH - pad;
	var mid = bg.x + boxW * 0.5;
	var textW = right - left;

	songText.y = top;
	fitText(songText, textW);
	songText.x = mid - songText.width * 0.5;
	songText.x -= songText.x % 6;

	var count = menuItems.length;
	if (count <= 0) return;
	var rowTop = songText.y + songText.height + 12;
	var rowH = (bottom - rowTop) / count;
	for (i in 0...count) {
		var t = texts[i + 1];
		if (t == null) continue;
		fitText(t, textW);
		t.x = mid - t.width * 0.5;
		t.y = rowTop + rowH * i + (rowH - t.height) * 0.5;
		t.x -= t.x % 6;
		t.y -= t.y % 6;
	}
}

function fitText(t, maxW) {
	t.scale.set(6, 6);
	t.updateHitbox();
	if (t.width > maxW && t.width > 0) {
		var s = 6 * (maxW / t.width);
		t.scale.set(s, s);
		t.updateHitbox();
	}
}

var scrollSFX = FlxG.sound.load(Paths.sound(isThorns ? 'pixel/type' : 'pixel/pixelText'));
function changeSelection(change) if (canDoShit) {  // this overrides the function inside of the normal pause btw, so no event gets called  - Nex
	curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
	if (change != 0) scrollSFX.play();
}

var enterSFX = FlxG.sound.load(Paths.sound(isThorns ? 'pixel/ANGRY' : 'pixel/clickText'));
function enterOption() if (canDoShit) {
	var option = menuItems[curSelected];
	enterSFX.play();

	switch(option) {
		case "Resume", "Exit to menu":
			canDoShit = false;
			for(t in texts) t.visible = false;
			hand.visible = songText.visible = false;
			FlxTween.tween(bg.scale, {y: 0}, 0.125, {ease: FlxEase.cubeOut, onComplete: selectOption});
		default: selectOption();
	}
}
