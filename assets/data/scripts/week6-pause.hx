import funkin.ui.FunkinText;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.util.FlxAxes;

var pixelScript:Script;
var pauseCam = new FlxCamera();

var bg:FlxSprite;
var hand:FlxSprite;

var texts:Array<FlxText> = [];

var isThorns = PlayState.SONG.meta.name.toLowerCase() == "thorns";

function create(event) {
	// cancel default pause menu!!
	event.cancel();

	event.music = isThorns ? "pixel/LunchboxScary" : "pixel/Lunchbox";

	cameras = [];

	pixelScript = game.scripts.getByName("pixel.hx");
	pixelScript.call("pixelCam", [pauseCam]);

	FlxG.cameras.add(pauseCam, false);

	pauseCam.bgColor = isThorns ? 0x88000000 : 0x88FF99CC;
	pauseCam.alpha = 0;

	bg = new FlxSprite(44 * 6, 14 * 6);
	bg.loadGraphic(Paths.image('stages/school/pause/bg'));
	if (isThorns)
		bg.color = 0xFF000000;
	bg.scale.set(6, 6);
	bg.updateHitbox();
	bg.scale.y = 4;
	bg.cameras = [pauseCam];
	add(bg);

	songText = new FlxText(0, 22 * 6, 0, "Pause", 8, false);
	confText(songText);
	add(songText);

	var i = 2;
	for(e in menuItems) {
		text = new FlxText(0, (22 * 6) + (i * 9 * 6), 0, e, 8, false);
		confText(text);
		add(text);
		texts.push(text);
		i++;
	}

	hand = new FlxSprite().loadGraphic(Paths.image('stages/school/ui/hand_textbox'));
	hand.scale.set(6, 6);
	hand.updateHitbox();
	add(hand);

	FlxTween.tween(bg, {"scale.y": 6}, 0.75, {ease: FlxEase.elasticOut});

	cameras = [pauseCam];

	FlxG.sound.play(Paths.sound(isThorns ? 'pixel/ANGRY' : 'pixel/clickText'));

	addVirtualPad('UP_DOWN', 'A');
	addVirtualPadCamera();
}

function confText(text) {
	text.scale.set(6, 6);
	text.updateHitbox();
	text.screenCenter(FlxAxes.X);
	text.borderStyle = FlxTextBorderStyle.OUTLINE;
	if (!isThorns) text.borderColor = 0xFF953E3E;
}

function destroy() {
	if(FlxG.cameras.list.contains(pauseCam))
		FlxG.cameras.remove(pauseCam);
}

var canDoShit = true;
var time:Float = 0;
function update(elapsed) {
	pixelScript.call("postUpdate", [elapsed]);

	pauseCam.alpha = lerp(pauseCam.alpha, 1, 0.25);
	time += elapsed;

	var curText = texts[curSelected];
	hand.setPosition(curText.x - hand.width - 18 + (Math.sin(time * Math.PI * 2) * 12), curText.y + (text.height - hand.height) - 6);
	hand.x -= hand.x % 6;
	hand.y -= hand.y % 6;

	if (!canDoShit) return;
	var oldSec = curSelected;

	changeSelection((controls.UP_P ? -1 : 0) + (controls.DOWN_P ? 1 : 0) - FlxG.mouse.wheel);

	if (oldSec != curSelected)
		FlxG.sound.play(Paths.sound(isThorns ? 'pixel/type' : 'pixel/pixelText'));

	if (controls.ACCEPT) {
		FlxG.sound.play(Paths.sound(isThorns ? 'pixel/ANGRY' : 'pixel/clickText'));
		var option = menuItems[curSelected];
		if (option == "Resume" || option == "Exit to menu") {
			canDoShit = false;
			for(t in texts) t.visible = false;
			hand.visible = songText.visible = false;
			FlxTween.tween(bg, {"scale.y": 0}, 0.125, {ease: FlxEase.cubeOut, onComplete: function() {
				selectOption();
			}});
		} else {
			selectOption();
		}
	}
}

function changeSelection(change) {  // this overrides the function inside of the normal pause btw, so no event gets called  - Nex
	curSelected += change;

	if (curSelected < 0)
		curSelected = menuItems.length - 1;
	if (curSelected >= menuItems.length)
		curSelected = 0;
}