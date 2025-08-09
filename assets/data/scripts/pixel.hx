//
import funkin.game.HudCamera;
import funkin.backend.scripting.events.NoteHitEvent;

public var pixelNotesForBF = true;
public var pixelNotesForDad = true;
public var pixelSplashes = true;
public var enablePixelUI = true;
public var enablePixelGameOver = true;
public var enableCameraHacks = Options.week6PixelPerfect;
public var enablePauseMenu = true;
public var isSpooky = false;

var oldStageQuality = FlxG.game.stage.quality;
public var daPixelZoom = PlayState.daPixelZoom;

/**
 * UI
 */
function onNoteCreation(event) {
	if ((event.note.strumLine == playerStrums && !pixelNotesForBF) || (event.note.strumLine == cpuStrums && !pixelNotesForDad)) return;
	event.cancel();

	var note = event.note;
	var strumID = event.strumID;
	if (event.note.isSustainNote) {
		note.loadGraphic(Paths.image('stages/school/ui/arrowEnds'), true, 7, 6);
		var maxCol = Math.floor(note.graphic.width / 7);
		note.animation.add("hold", [strumID%maxCol]);
		note.animation.add("holdend", [maxCol + strumID%maxCol]);
	} else {
		note.loadGraphic(Paths.image('stages/school/ui/arrows-pixels'), true, 17, 17);
		var maxCol = Math.floor(note.graphic.width / 17);
		note.animation.add("scroll", [maxCol + strumID%maxCol]);
	}
	var strumScale = event.note.strumLine.strumScale;
	note.scale.set(daPixelZoom*strumScale, daPixelZoom*strumScale);
	note.updateHitbox();
	note.antialiasing = false;
}

function onPostNoteCreation(event) if (pixelSplashes)
	event.note.splash = "pixel-default";

function onStrumCreation(event) {
	if ((event.player == 1 && !pixelNotesForBF) || (event.player == 0 && !pixelNotesForDad)) return;
	event.cancel();

	var strum = event.strum;
	strum.loadGraphic(Paths.image('stages/school/ui/arrows-pixels'), true, 17, 17);
	var maxCol = Math.floor(strum.graphic.width / 17);
	var strumID = event.strumID % maxCol;

	strum.animation.add("static", [strumID]);
	strum.animation.add("pressed", [maxCol + strumID, (maxCol*2) + strumID], 12, false);
	strum.animation.add("confirm", [(maxCol*3) + strumID, (maxCol*4) + strumID], 24, false);

	var strumScale = strumLines.members[event.player].strumScale;
	strum.scale.set(daPixelZoom*strumScale, daPixelZoom*strumScale);
	strum.updateHitbox();
	strum.antialiasing = false;
}

function onCountdown(event) {
	if (!enablePixelUI) return;

	if (event.soundPath != null) event.soundPath = 'pixel/' + event.soundPath;
	event.antialiasing = false;
	event.scale = daPixelZoom;
	event.spritePath = switch(event.swagCounter) {
		case 0: null;
		case 1: 'stages/school/ui/ready';
		case 2: 'stages/school/ui/set';
		case 3: 'stages/school/ui/go';
	};
}

function onPlayerHit(event:NoteHitEvent) {
	if (!enablePixelUI) return;
	event.ratingPrefix = "stages/school/ui/";
	event.ratingScale = daPixelZoom * 0.7;
	event.ratingAntialiasing = false;

	event.numScale = daPixelZoom;
	event.numAntialiasing = false;
}

/**
 * CAMERA HACKS!!
 */
function postCreate() {
	if (enablePauseMenu)
		PauseSubState.script = 'data/scripts/week6-pause';

	if (enableCameraHacks) {
		camGame.pixelPerfectRender = true;
		camGame.antialiasing = false;

		makeCameraPixely(camGame);
		defaultCamZoom /= daPixelZoom;
	}

	if (enablePixelGameOver) {
		gameOverSong = "pixel/gameOver";
		lossSFX = "pixel/gameOverSFX";
		retrySFX = "pixel/gameOverEnd";
	}
}

/*function onStartCountdown() {
	var newNoteCamera = new HudCamera();
	newNoteCamera.bgColor = 0; // transparent
	FlxG.cameras.add(newNoteCamera, false);

	var pixelSwagWidth = Note.swagWidth + (daPixelZoom - (Note.swagWidth % daPixelZoom));

	for(p in strumLines) {
		var i = 0;
		for(str in p.members) {
			str.x = (FlxG.width * strumOffset) + (pixelSwagWidth * (i - 2));
			str.x -= str.x % daPixelZoom;
			i++;
		}
	}
	makeCameraPixely(newNoteCamera);
}*/

/**
 * Use this to make any camera pixelly (you wont be able to zoom with it anymore!)
 */
public function makeCameraPixely(cam) {
	cam.pixelPerfectRender = true;
	if(!enableCameraHacks) return;

	cam.zoom /= Math.min(FlxG.scaleMode.scale.x, FlxG.scaleMode.scale.y) * daPixelZoom;

	var shad = new CustomShader('pixelZoomShader');
	cam.addShader(shad);

	pixellyCameras.push(cam);
	pixellyShaders.push(shad);

	FlxG.game.stage.quality = 2;
}

function destroy() {
	// resets the stage quality
	FlxG.game.stage.quality = oldStageQuality;
}

function pixelCam(cam)
	makeCameraPixely(cam);

var pixellyCameras = [];
var pixellyShaders = [];

function postUpdate() {
	for (e in pixellyCameras) if (Std.isOfType(e, HudCamera))
		e.downscroll = camHUD.downscroll;

	if (enableCameraHacks) for (p in strumLines) {
		p.notes.forEach(function(n) {
			if(n.isSustainNote) return; // hacky fix for hold
			n.y -= n.y % daPixelZoom;
			n.x -= n.x % daPixelZoom;
		});
	}

	var zoom = 1 / daPixelZoom / Math.min(FlxG.scaleMode.scale.x, FlxG.scaleMode.scale.y);
	for (e in pixellyCameras) {
		if (!e.exists) continue;
		e.zoom = zoom;
	}
	for (e in pixellyShaders)
		e.pixelZoom = zoom;
}
