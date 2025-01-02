package funkin.options;

import funkin.options.type.OptionType;

class OptionsScreen extends FlxTypedSpriteGroup<OptionType> {
	public static var optionHeight:Float = 120;

	public var parent:OptionsTree;

	public var curSelected:Int = 0;
	public var id:Int = 0;

	private var __firstFrame:Bool = true;

	public var name:String;
	public var desc:String;

	public var dpadMode:String = 'NONE';
	public var actionMode:String = 'NONE';
	public var prevVPadModes:Array<String> = [];

	public function new(name:String, desc:String, ?options:Array<OptionType>, dpadMode:String = 'NONE', actionMode:String = 'NONE') {
		super();
		this.name = name;
		this.desc = desc;
		if (options != null) for(o in options) add(o);
		#if TOUCH_CONTROLS
		if(MusicBeatState.getState().virtualPad != null)
			prevVPadModes = [MusicBeatState.getState().virtualPad.curDPadMode.getName(), MusicBeatState.getState().virtualPad.curActionMode.getName()];
		this.dpadMode = dpadMode;
		this.actionMode = actionMode;
		MusicBeatState.getState().removeVirtualPad();
		MusicBeatState.getState().addVirtualPad(dpadMode, actionMode);
		MusicBeatState.getState().addVirtualPadCamera();
		#end
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		var controls = PlayerSettings.solo.controls;

		changeSelection((controls.UP_P ? -1 : 0) + (controls.DOWN_P ? 1 : 0) - FlxG.mouse.wheel);
		x = id * FlxG.width;
		for(k=>option in members) {
			if(option == null) continue;

			var y:Float = ((FlxG.height - optionHeight) / 2) + ((k - curSelected) * optionHeight);

			option.selected = false;
			option.y = __firstFrame ? y : CoolUtil.fpsLerp(option.y, y, 0.25);
			option.x = x + (-50 + (Math.abs(Math.cos((option.y + (optionHeight / 2) - (FlxG.camera.scroll.y + (FlxG.height / 2))) / (FlxG.height * 1.25) * Math.PI)) * 150));
		}
		if (__firstFrame) {
			__firstFrame = false;
			return;
		}

		if (members.length > 0) {
			members[curSelected].selected = true;
			if (controls.ACCEPT || (FlxG.mouse.justReleased && !controls.touchC))
				members[curSelected].onSelect();
			if (controls.LEFT_P)
				members[curSelected].onChangeSelection(-1);
			if (controls.RIGHT_P)
				members[curSelected].onChangeSelection(1);
		}
		if (controls.BACK || (FlxG.mouse.justReleasedRight && !controls.touchC))
			close();
	}

	public function close() {
		onClose(this);
		if(prevVPadModes.length > 0){
			MusicBeatState.getState().removeVirtualPad();
			MusicBeatState.getState().addVirtualPad(prevVPadModes[0], prevVPadModes[1]);
			MusicBeatState.getState().addVirtualPadCamera();
		}
	}

	public function changeSelection(sel:Int, force:Bool = false) {
		if (members.length <= 0 || (sel == 0 && !force)) return;

		CoolUtil.playMenuSFX(SCROLL);
		curSelected = FlxMath.wrap(curSelected + sel, 0, members.length-1);
		members[curSelected].selected = true;
		updateMenuDesc();
	}

	public function updateMenuDesc(?customTxt:String) {
		if (parent == null || parent.treeParent == null) return;
		parent.treeParent.updateDesc(customTxt != null ? customTxt : members[curSelected].desc);
	}

	public dynamic function onClose(o:OptionsScreen) {}
}
