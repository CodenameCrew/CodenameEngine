package funkin.editors.charter;

import flixel.graphics.FlxGraphic;
import funkin.backend.system.Conductor;
import openfl.geom.Rectangle;
import flixel.addons.display.FlxBackdrop;

class CharterBackdropGroup extends FlxTypedGroup<CharterBackdrop> {
	public var strumLineGroup:CharterStrumLineGroup;
	public var notesGroup:CharterNoteGroup;
	var __gridGraphic:FlxGraphic;

	public var conductorSprY:Float = 0;
	public var bottomLimitY:Float = 0;
	public var sectionsVisible:Bool = true;
	public var beatsVisible:Bool = true;

	// Just here so you can update display sprites all dat and above
	public var strumlinesAmount:Int = 0;

	public function new(strumLineGroup:CharterStrumLineGroup) {
		super();
		this.strumLineGroup = strumLineGroup;

		__gridGraphic = FlxG.bitmap.create(160, 160, 0xFF272727, true);
		__gridGraphic.bitmap.lock();

		// Checkerboard
		for(y in 0...4)
			for(x in 0...2) __gridGraphic.bitmap.fillRect(new Rectangle(40*((x*2)+(y%2)), 40*y, 40, 40), 0xFF545454);

		// Edges
		__gridGraphic.bitmap.fillRect(new Rectangle(0, 0, 1, 160), 0xFFDDDDDD);
		__gridGraphic.bitmap.fillRect(new Rectangle(159, 0, 1, 160), 0xFFDDDDDD);
		__gridGraphic.bitmap.unlock();
	}

	public function createGrids(amount:Int = 0) {
		for (i in 0...amount) {
			var grid = new CharterBackdrop(__gridGraphic);
			grid.active = grid.visible = false;
			add(grid);
		}
	}

	public override function update(elapsed:Float) {
		for (grid in members)
			grid.active = grid.visible = false;

		super.update(elapsed);

		for (i => strumLine in strumLineGroup.members) {
			if (strumLine == null) continue;

			if (members[i] == null)
				members[i] = recycle(CharterBackdrop, () -> {return new CharterBackdrop(__gridGraphic);});

			var grid = members[i];
			grid.cameras = this.cameras;
			grid.strumLine = strumLine;

			grid.conductorFollowerSpr.y = conductorSprY;
			grid.bottomSeparator.y = (grid.bottomLimit.y = bottomLimitY)-2;
			grid.sectionSeparator.visible = sectionsVisible;
			grid.beatSeparator.visible = beatsVisible;

			grid.waveformSprite.shader = strumLine.waveformShader;

			grid.notesGroup.clear();
			notesGroup.forEach((n) -> {
				var onStr:Bool = (n.snappedToStrumline ? n.strumLineID : Std.int(FlxMath.bound((n.x+n.width)/(40*4), 0, strumLineGroup.members.length-1))) == i;
				if(n.exists && n.visible && onStr)
					grid.notesGroup.add(n);
			});

			grid.active = grid.visible = true;
			grid.updateSprites();
		}
	}

	public var draggingObj:CharterBackdrop = null;
	override function draw() @:privateAccess {
		var i:Int = 0;
		var basic:FlxBasic = null;

		for (grid in members) {
			if (strumLineGroup.draggingObj == null) break;
			if (grid.strumLine == null) continue;

			if (strumLineGroup.draggingObj.strumLine == grid.strumLine.strumLine) {
				draggingObj = grid;
				break;
			}
		}

		var oldDefaultCameras = FlxCamera._defaultCameras;
		if (cameras != null)
			FlxCamera._defaultCameras = cameras;

		while (i < length)
		{
			basic = members[i++];
			if (basic != null && basic != draggingObj && basic.exists && basic.visible)
				basic.draw();
		}
		if (draggingObj != null) draggingObj.draw();

		FlxCamera._defaultCameras = oldDefaultCameras;
	}
}

class CharterBackdrop extends FlxTypedGroup<Dynamic> {
	public var gridBackDrop:FlxBackdrop;
	public var topLimit:FlxSprite;
	public var topSeparator:FlxSprite;
	public var bottomLimit:FlxSprite;
	public var bottomSeparator:FlxSprite;

	public var waveformSprite:FlxSprite;

	public var conductorFollowerSpr:FlxSprite;
	public var beatSeparator:FlxBackdrop;
	public var sectionSeparator:FlxBackdrop;

	public var notesGroup:FlxTypedGroup<CharterNote> = new FlxTypedGroup<CharterNote>();
	public var strumLine:CharterStrumline;

	public function new(gridGraphic:FlxGraphic) {
		super();

		gridBackDrop = new FlxBackdrop(gridGraphic, Y, 0, 0);
		add(gridBackDrop);

		waveformSprite = new FlxSprite().makeSolid(1, 1, 0xFF000000);
		waveformSprite.scale.set(160, 1);
		waveformSprite.updateHitbox(); 
		add(waveformSprite);

		sectionSeparator = new FlxBackdrop(null, Y, 0, 0);
		sectionSeparator.y = -2;
		sectionSeparator.visible = Options.charterShowSections;

		beatSeparator = new FlxBackdrop(null, Y, 0, 0);
		beatSeparator.y = -1;
		beatSeparator.visible = Options.charterShowBeats;

		for(sep in [sectionSeparator, beatSeparator]) {
			sep.makeSolid(1, 1, -1);
			sep.alpha = 0.5;
			sep.scrollFactor.set(1, 1);
			sep.scale.set((4 * 40), sep == sectionSeparator ? 4 : 2);
			sep.updateHitbox();
		}
		add(beatSeparator);
		add(sectionSeparator);
		add(notesGroup);

		bottomSeparator = new FlxSprite(0,-2);
		bottomSeparator.makeSolid(1, 1, -1);
		bottomSeparator.alpha = 0.5;
		bottomSeparator.scrollFactor.set(1, 1);
		bottomSeparator.scale.set(4 * 40, 4);
		bottomSeparator.updateHitbox();
		add(bottomSeparator);

		topSeparator = new FlxSprite(0, -2);
		topSeparator.makeSolid(1, 1, -1);
		topSeparator.alpha = 0.5;
		topSeparator.scrollFactor.set(1, 1);
		topSeparator.scale.set(4 * 40, 4);
		topSeparator.updateHitbox();
		add(topSeparator);

		// Limits
		topLimit = new FlxSprite();
		topLimit.makeSolid(1, 1, -1);
		topLimit.color = 0xFF888888;
		topLimit.blend = MULTIPLY;
		add(topLimit);

		bottomLimit = new FlxSprite();
		bottomLimit.makeSolid(1, 1, -1);
		bottomLimit.color = 0xFF888888;
		bottomLimit.blend = MULTIPLY;
		add(bottomLimit);

		// Follower
		conductorFollowerSpr = new FlxSprite(0, 0).makeSolid(1, 1, -1);
		conductorFollowerSpr.scale.set(4 * 40, 4);
		conductorFollowerSpr.updateHitbox();
		add(conductorFollowerSpr);
	}

	public function updateSprites() {
		var x:Float = 0; // fuck you
		var alpha:Float = 0.9;

		if (strumLine != null) {
			x = strumLine.x;
			alpha = strumLine.strumLine.visible ? 0.9 : 0.4;
		} else alpha = 0.9;

		for (spr in [gridBackDrop, sectionSeparator, beatSeparator, topLimit, bottomLimit, 
				topSeparator, bottomSeparator, conductorFollowerSpr, waveformSprite]) {
			spr.x = x; if (spr != waveformSprite) spr.alpha = alpha;
			spr.cameras = this.cameras;
		}

		sectionSeparator.spacing.y = (10 * Conductor.beatsPerMeasure * Conductor.stepsPerBeat) - 1;
		beatSeparator.spacing.y = (20 * Conductor.stepsPerBeat) - 1;

		topLimit.scale.set(4 * 40, Math.ceil(FlxG.height / cameras[0].zoom));
		topLimit.updateHitbox();
		topLimit.y = -topLimit.height;

		bottomLimit.scale.set(4 * 40, Math.ceil(FlxG.height / cameras[0].zoom));
		bottomLimit.updateHitbox();

		waveformSprite.visible = waveformSprite.shader != null;
		if (waveformSprite.shader == null) return;

		waveformSprite.scale.set(160, FlxG.height * (1/cameras[0].zoom));
		waveformSprite.updateHitbox();

		waveformSprite.y = (cameras[0].scroll.y+FlxG.height/2)-(waveformSprite.height/2);

		if (waveformSprite.y < 0) {waveformSprite.scale.y += waveformSprite.y; waveformSprite.y = 0;}
		if (waveformSprite.y + waveformSprite.height > bottomLimit.y) {
			waveformSprite.scale.y -= (waveformSprite.y + waveformSprite.height)-(bottomLimit.y);
			waveformSprite.y = (bottomLimit.y) - waveformSprite.scale.y;
		}
		waveformSprite.updateHitbox();

		waveformSprite.shader.data.pixelOffset.value = [Math.max(conductorFollowerSpr.y - ((FlxG.height * (1/cameras[0].zoom)) * 0.5), 0)];
		waveformSprite.shader.data.textureRes.value = [waveformSprite.width, waveformSprite.height];
		waveformSprite.shader.data.playerPosition.value = [conductorFollowerSpr.y];
	}
}

class CharterBackdropDummy extends UISprite {
	var parent:CharterBackdropGroup;
	public function new(parent:CharterBackdropGroup) {
		super();
		this.parent = parent;
		cameras = parent.cameras;
		scrollFactor.set(1, 0);
	}

	public override function updateButton() {
		camera.getViewRect(__rect);
		UIState.state.updateRectButtonHandler(this, __rect, onHovered);
	}

	public override function draw() {
		@:privateAccess
		__lastDrawCameras = cameras.copy();
	}
}

class EventBackdrop extends FlxBackdrop {
	public var eventBeatSeparator:FlxBackdrop;
	public var eventSecSeparator:FlxBackdrop;

	public var topSeparator:FlxSprite;
	public var bottomSeparator:FlxSprite;

	public function new() {
		super(Paths.image('editors/charter/events-grid'), Y, 0, 0);
		alpha = 0.9;

		// Separators
		eventSecSeparator = new FlxBackdrop(null, Y, 0, 0);
		eventSecSeparator.y = -2;
		eventSecSeparator.visible = Options.charterShowSections;

		eventBeatSeparator = new FlxBackdrop(null, Y, 0, 0);
		eventBeatSeparator.y = -1;
		eventBeatSeparator.visible = Options.charterShowBeats;

		for(sep in [eventSecSeparator, eventBeatSeparator]) {
			sep.makeSolid(1, 1, -1);
			sep.alpha = 0.5;
			sep.scrollFactor.set(1, 1);
		}

		eventSecSeparator.scale.set(20, 4);
		eventSecSeparator.updateHitbox();

		eventBeatSeparator.scale.set(10, 2);
		eventBeatSeparator.updateHitbox();

		bottomSeparator = new FlxSprite(0,-2);
		bottomSeparator.makeSolid(1, 1, -1);
		bottomSeparator.alpha = 0.5;
		bottomSeparator.scrollFactor.set(1, 1);
		bottomSeparator.scale.set(20, 4);
		bottomSeparator.updateHitbox();

		topSeparator = new FlxSprite(0, -2);
		topSeparator.makeSolid(1, 1, -1);
		topSeparator.alpha = 0.5;
		topSeparator.scrollFactor.set(1, 1);
		topSeparator.scale.set(20, 4);
		topSeparator.updateHitbox();

	}

	public override function draw() {
		super.draw();

		eventSecSeparator.spacing.y = (10 * Conductor.beatsPerMeasure * Conductor.stepsPerBeat) - 1;
		eventBeatSeparator.spacing.y = (20 * Conductor.stepsPerBeat) - 1;

		eventSecSeparator.cameras = cameras;
		eventSecSeparator.x = (x+width) - 20;
		if (eventSecSeparator.visible) eventSecSeparator.draw();

		eventBeatSeparator.cameras = cameras;
		eventBeatSeparator.x = (x+width) - 10;
		if (eventBeatSeparator.visible) eventBeatSeparator.draw();

		topSeparator.x = (x+width) - 20;
		topSeparator.cameras = this.cameras;
		if (!eventSecSeparator.visible) topSeparator.draw();

		bottomSeparator.x = (x+width) - 20;
		bottomSeparator.cameras = this.cameras;
		bottomSeparator.draw();
	}
}