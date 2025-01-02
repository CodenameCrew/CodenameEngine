package mobile.flixel;

import flixel.FlxG;
#if MOD_SUPPORT
import sys.FileSystem;
#end
import flixel.math.FlxPoint;
import funkin.options.Options;
import mobile.flixel.FlxButton;
import openfl.display.BitmapData;
import flixel.util.FlxDestroyUtil;
import flixel.graphics.FlxGraphic;
import funkin.backend.assets.Paths;
import mobile.objects.FlxButtonGroup;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets;
import haxe.ds.Map;
import flixel.util.typeLimit.OneOfTwo;

enum FlxDPadMode
{
	UP_DOWN;
	LEFT_RIGHT;
	LEFT_FULL;
	RIGHT_FULL;
	NONE;
}

enum FlxActionMode
{
	A;
	B;
	P;
	A_B;
	A_B_C;
	A_B_E;
	A_B_X_Y;
	A_B_M_E;
	A_B_C_X_Y;
	A_B_C_X_Y_Z;
	A_B_C_D_V_X_Y_Z;
	NONE;
}

/**
 * A highly modified FlxVirtualPad.
 * It's easy to customize the layout.
 *
 * @author Ka Wing Chin
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class FlxVirtualPad extends FlxButtonGroup
{
	public var buttonLeft:FlxButton = new FlxButton(0, 0);
	public var buttonUp:FlxButton = new FlxButton(0, 0);
	public var buttonRight:FlxButton = new FlxButton(0, 0);
	public var buttonDown:FlxButton = new FlxButton(0, 0);
	public var buttonLeft2:FlxButton = new FlxButton(0, 0);
	public var buttonUp2:FlxButton = new FlxButton(0, 0);
	public var buttonRight2:FlxButton = new FlxButton(0, 0);
	public var buttonDown2:FlxButton = new FlxButton(0, 0);
	public var buttonA:FlxButton = new FlxButton(0, 0);
	public var buttonB:FlxButton = new FlxButton(0, 0);
	public var buttonC:FlxButton = new FlxButton(0, 0);
	public var buttonD:FlxButton = new FlxButton(0, 0);
	public var buttonE:FlxButton = new FlxButton(0, 0);
	public var buttonF:FlxButton = new FlxButton(0, 0);
	public var buttonG:FlxButton = new FlxButton(0, 0);
	public var buttonH:FlxButton = new FlxButton(0, 0);
	public var buttonI:FlxButton = new FlxButton(0, 0);
	public var buttonJ:FlxButton = new FlxButton(0, 0);
	public var buttonK:FlxButton = new FlxButton(0, 0);
	public var buttonL:FlxButton = new FlxButton(0, 0);
	public var buttonM:FlxButton = new FlxButton(0, 0);
	public var buttonN:FlxButton = new FlxButton(0, 0);
	public var buttonO:FlxButton = new FlxButton(0, 0);
	public var buttonP:FlxButton = new FlxButton(0, 0);
	public var buttonQ:FlxButton = new FlxButton(0, 0);
	public var buttonR:FlxButton = new FlxButton(0, 0);
	public var buttonS:FlxButton = new FlxButton(0, 0);
	public var buttonT:FlxButton = new FlxButton(0, 0);
	public var buttonU:FlxButton = new FlxButton(0, 0);
	public var buttonV:FlxButton = new FlxButton(0, 0);
	public var buttonW:FlxButton = new FlxButton(0, 0);
	public var buttonX:FlxButton = new FlxButton(0, 0);
	public var buttonY:FlxButton = new FlxButton(0, 0);
	public var buttonZ:FlxButton = new FlxButton(0, 0);

	public var curDPadMode:FlxDPadMode = NONE;
	public var curActionMode:FlxActionMode = NONE;
	public static var dpadModes:Map<String, FlxDPadMode>;
	public static var actionModes:Map<String, FlxActionMode>;

	/**
	 * Create a gamepad.
	 *
	 * @param   FlxDPadMode     The D-Pad mode. `LEFT_FULL` for example.
	 * @param   FlxActionMode   The action buttons mode. `A_B_C` for example.
	 */
	public function new(DPad:OneOfTwo<FlxDPadMode, String>, Action:OneOfTwo<FlxActionMode, String>)
	{
		super();
		var dpadMode:FlxDPadMode;
		var actionMode:FlxActionMode;

		if(DPad is FlxDPadMode)
			dpadMode = cast DPad;
		else
			dpadMode = cast getDPadModeByString(cast DPad);

		if(Action is FlxActionMode)
			actionMode = cast DPad;
		else
			actionMode = cast getActionModeByString(cast Action);
		curDPadMode = dpadMode;
		curActionMode = actionMode;
		switch (dpadMode)
		{
			case UP_DOWN:
				add(buttonUp = createButton(0, FlxG.height - 258, 'up', 0x00FF00));
				add(buttonDown = createButton(0, FlxG.height - 131, 'down', 0x00FFFF));
			case LEFT_RIGHT:
				add(buttonLeft = createButton(0, FlxG.height - 131, 'left', 0xFF00FF));
				add(buttonRight = createButton(127, FlxG.height - 131, 'right', 0xFF0000));
			case LEFT_FULL:
				add(buttonUp = createButton(105, FlxG.height - 356, 'up', 0x00FF00));
				add(buttonLeft = createButton(0, FlxG.height - 246, 'left', 0xFF00FF));
				add(buttonRight = createButton(207, FlxG.height - 246, 'right', 0xFF0000));
				add(buttonDown = createButton(105, FlxG.height - 131, 'down', 0x00FFFF));
			case RIGHT_FULL:
				add(buttonUp = createButton(FlxG.width - 258, FlxG.height - 404, 'up', 0x00FF00));
				add(buttonLeft = createButton(FlxG.width - 384, FlxG.height - 305, 'left', 0xFF00FF));
				add(buttonRight = createButton(FlxG.width - 132, FlxG.height - 305, 'right', 0xFF0000));
				add(buttonDown = createButton(FlxG.width - 258, FlxG.height - 197, 'down', 0x00FFFF));
			case NONE: // do nothing
		}

		switch (actionMode)
		{
			case A:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 131, 'a', 0xFF0000));
			case B:
				add(buttonB = createButton(FlxG.width - 132, FlxG.height - 131, 'b', 0xFFCB00));
			case P:
				add(buttonP = createButton(FlxG.width - 132, 0, 'p', 0xFFCB00));
			case A_B:
				add(buttonB = createButton(FlxG.width - 262, FlxG.height - 131, 'b', 0xFFCB00));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 131, 'a', 0xFF0000));
			case A_B_C:
				add(buttonC = createButton(FlxG.width - 392, FlxG.height - 131, 'c', 0x44FF00));
				add(buttonB = createButton(FlxG.width - 262, FlxG.height - 131, 'b', 0xFFCB00));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 131, 'a', 0xFF0000));
			case A_B_E:
				add(buttonE = createButton(FlxG.width - 392, FlxG.height - 131, 'e', 0xFF7D00));
				add(buttonB = createButton(FlxG.width - 262, FlxG.height - 131, 'b', 0xFFCB00));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 131, 'a', 0xFF0000));
			case A_B_X_Y:
				add(buttonX = createButton(FlxG.width - 522, FlxG.height - 131, 'x', 0x99062D));
				add(buttonB = createButton(FlxG.width - 262, FlxG.height - 131, 'b', 0xFFCB00));
				add(buttonY = createButton(FlxG.width - 392, FlxG.height - 131, 'y', 0x4A35B9));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 131, 'a', 0xFF0000));
			case A_B_C_X_Y:
				add(buttonC = createButton(FlxG.width - 392, FlxG.height - 131, 'c', 0x44FF00));
				add(buttonX = createButton(FlxG.width - 262, FlxG.height - 251, 'x', 0x99062D));
				add(buttonB = createButton(FlxG.width - 262, FlxG.height - 131, 'b', 0xFFCB00));
				add(buttonY = createButton(FlxG.width - 132, FlxG.height - 251, 'y', 0x4A35B9));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 131, 'a', 0xFF0000));
			case A_B_C_X_Y_Z:
				add(buttonX = createButton(FlxG.width - 392, FlxG.height - 251, 'x', 0x99062D));
				add(buttonC = createButton(FlxG.width - 392, FlxG.height - 131, 'c', 0x44FF00));
				add(buttonY = createButton(FlxG.width - 262, FlxG.height - 251, 'y', 0x4A35B9));
				add(buttonB = createButton(FlxG.width - 262, FlxG.height - 131, 'b', 0xFFCB00));
				add(buttonZ = createButton(FlxG.width - 132, FlxG.height - 251, 'z', 0xCCB98E));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 131, 'a', 0xFF0000));
			case A_B_C_D_V_X_Y_Z:
				add(buttonV = createButton(FlxG.width - 522, FlxG.height - 251, 'v', 0x49A9B2));
				add(buttonD = createButton(FlxG.width - 522, FlxG.height - 131, 'd', 0x0078FF));
				add(buttonX = createButton(FlxG.width - 392, FlxG.height - 251, 'x', 0x99062D));
				add(buttonC = createButton(FlxG.width - 392, FlxG.height - 131, 'c', 0x44FF00));
				add(buttonY = createButton(FlxG.width - 262, FlxG.height - 251, 'y', 0x4A35B9));
				add(buttonB = createButton(FlxG.width - 262, FlxG.height - 131, 'b', 0xFFCB00));
				add(buttonZ = createButton(FlxG.width - 132, FlxG.height - 251, 'z', 0xCCB98E));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 131, 'a', 0xFF0000));
			// CNE Releated
			case A_B_M_E:
				add(buttonM = createButton(FlxG.width - 522, FlxG.height - 131, 'm', 0x00BBFF));
				add(buttonB = createButton(FlxG.width - 262, FlxG.height - 131, 'b', 0xFFCB00));
				add(buttonE = createButton(FlxG.width - 392, FlxG.height - 131, 'e', 0xFF7D00));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 131, 'a', 0xFF0000));
			case NONE: // do nothing
		}

		scrollFactor.set();
		var guh = Options.controlsAlpha;
		if (guh >= 0.9)
			guh = guh - 0.07;
		alpha = Options.controlsAlpha;
	}

	public static function getDPadModeByString(mode:String):FlxDPadMode {
		if(dpadModes == null){
			dpadModes = new Map();
			for(enumValue in FlxDPadMode.createAll())
				dpadModes.set(enumValue.getName(), enumValue);
		}
		return dpadModes.exists(mode) ? dpadModes.get(mode) : NONE;
	}

	public static function getActionModeByString(mode:String):FlxActionMode {
		if(actionModes == null){
			actionModes = new Map();
			for(enumValue in FlxActionMode.createAll())
				actionModes.set(enumValue.getName(), enumValue);
		}
		return actionModes.exists(mode) ? actionModes.get(mode) : NONE;
	}

	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		super.destroy();

		for (field in Reflect.fields(this))
			if (Std.isOfType(Reflect.field(this, field), FlxButton))
				Reflect.setField(this, field, FlxDestroyUtil.destroy(Reflect.field(this, field)));
	}

	private function createButton(X:Float, Y:Float, Graphic:String, Color:Int = 0xFFFFFF):FlxButton
	{
		var graphic:FlxGraphic;
		var path:String = Paths.image('mobile/virtualpad/$Graphic');
		#if MOD_SUPPORT
		if(FileSystem.exists(path))
			graphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(path));
		else #end if(Assets.exists(path))
			graphic = FlxGraphic.fromBitmapData(Assets.getBitmapData(path));
		else
			graphic = FlxGraphic.fromBitmapData(Assets.getBitmapData(Paths.image('mobile/virtualpad/default')));

		var button:FlxButton = new FlxButton(X, Y);
		try {
			button.frames = FlxTileFrames.fromGraphic(graphic, FlxPoint.get(Std.int(graphic.width / 2), graphic.height));
		}
		catch (e){
			trace("Failed to create button(s) " + e.message);
			return null;
		}
		button.solid = false;
		button.immovable = true;
		button.scrollFactor.set();
		button.color = Color;
		#if FLX_DEBUG
		button.ignoreDrawDebug = true;
		#end
		return button;
	}
}