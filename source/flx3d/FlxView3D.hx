package flx3d;

#if THREE_D_SUPPORT
import flx3d._internal.TextureView3D;
import away3d.containers.View3D;
import away3d.library.assets.IAsset;
import flixel.FlxG;
import openfl.display.BitmapData;
#end
import flixel.FlxSprite;

/**
 * @author Ne_Eo
 * @see https://twitter.com/Ne_Eo_Twitch
 *
 * @author lunarcleint
 * @see https://twitter.com/lunarcleint
 */
class FlxView3D extends FlxSprite
{
	#if THREE_D_SUPPORT
	@:noCompletion private var bmp:BitmapData = null;

	/**
	 * The Away3D View
	 */
	public var view:TextureView3D;

	/**
	 * Set this flag to true to force the View3D to update during the `draw()` call.
	 */
	public var dirty3D:Bool = true;

	/**
	 * Creates a new instance of a View3D from Away3D and renders it as a FlxSprite
	 * ! Call Flx3DUtil.is3DAvailable(); to make sure a 3D stage is usable
	 * @param x
	 * @param y
	 * @param width Leave as -1 for screen width
	 * @param height Leave as -1 for screen height
	 */
	public function new(x:Float = 0, y:Float = 0, width:Int = -1, height:Int = -1)
	{
		super(x, y);
		view = new TextureView3D();
		view.addCallback = function() {
			trace("ADDED");
			bmp = view.bitmap; //new BitmapData(Std.int(view.width), Std.int(view.height), true, 0x0);
			loadGraphic(bmp);
		}
		view.visible = false;
		//view.width = width == -1 ? FlxG.width : width;
		//view.height = height == -1 ? FlxG.height : height;
		this.width = width == -1 ? FlxG.width : width;
		this.height = height == -1 ? FlxG.height : height;

		view.backgroundAlpha = 0;
		FlxG.stage.addChildAt(view, 0);

	}

	override function resetHelpers():Void
	{
		resetFrameSize();
		//resetSizeFromFrame(); // commenting out this shit because it's causing issues
		_flashRect2.x = 0;
		_flashRect2.y = 0;

		if (graphic != null)
		{
			_flashRect2.width = graphic.width;
			_flashRect2.height = graphic.height;
		}

		centerOrigin();

		if (FlxG.renderBlit)
		{
			dirty = true;
			updateFramePixels();
		}
	}

	/**
	 * Disposes (destroys) the asset and returns null
	 * @param obj
	 * @return T null
	 */
	public static function dispose<T:IAsset>(obj:Null<T>):T
	{
		return Flx3DUtil.dispose(obj);
	}

	/**
	 * Disposes of all the Away3D assets associated with the FlxView3D
	 */
	override function destroy()
	{
		FlxG.stage.removeChild(view);
		super.destroy();

		if (bmp != null)
		{
			bmp.dispose();
			bmp = null;
		}

		if (view != null)
		{
			view.dispose();
			view = null;
		}
	}

	override function update(elapsed:Float) {
		if (bmp != view.bitmap) {
			funkin.backend.system.Logs.warn("FlxView3D bitmaps do not match, correcting...");
			bmp = view.bitmap;
		}
		
	}

	/*@:noCompletion override function draw()
	{
		super.draw();
		if (dirty3D)
		{
			view.x = 0;
			view.visible = false;
			FlxG.stage.addChildAt(view, 0);

			var old = FlxG.game.filters;
			FlxG.game.filters = null;

			//view.renderer.queueSnapshot(bmp);
			view.render();

			FlxG.game.filters = old;
			FlxG.stage.removeChild(view);
		}
	}*/

	@:noCompletion override function set_width(newWidth:Float):Float
	{
		super.set_width(newWidth);
		return view != null ? view.width = width : width;
	}

	@:noCompletion override function set_height(newHeight:Float):Float
	{
		super.set_height(newHeight);
		return view != null ? view.height = height : height;
	}
	#end
}
