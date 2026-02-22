package flx3d._internal;

import flixel.FlxG;
import haxe.Exception;
import away3d.containers.View3D;
import away3d.containers.Scene3D;
import away3d.cameras.Camera3D;
import away3d.core.render.RendererBase;
import away3d.core.managers.Stage3DManager;
import away3d.core.managers.Stage3DProxy;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.Context3D;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.geom.Point;

class TextureView3D extends View3D
{
	public var bitmap:BitmapData;

	private var _framebuffer:TextureBase = null;

	public var onUpdateBitmap:(BitmapData) -> Void;

	/**
	 * Prevents the engine from disposing Flixel's Stage3D/Context3D instance
	 */
	public override function dispose() @:privateAccess {
		_stage3DProxy = null;
		super.dispose();
	}

	private override function set_height(value:Float):Float
	{
		if (_height == value)
			return value;
		super.set_height(value);
		_createFramebuffer();
		return value;
	}

	private override function set_width(value:Float):Float
	{
		if (_width == value)
			return value;
		super.set_width(value);
		_createFramebuffer();
		return value;
	}

	public function new(scene:Scene3D = null, camera:Camera3D = null, renderer:RendererBase = null, forceSoftware:Bool = false, profile:String = "baseline",
			contextIndex:Int = -1)
	{
		super(scene, camera, renderer, forceSoftware, profile, contextIndex);

		_stage3DProxy = Stage3DManager.getInstance(FlxG.stage).getStage3DProxy(0);
		_createFramebuffer();
	}

	private function _createFramebuffer()
	{
		if (width == 0 || height == 0)
			return;
		if (_framebuffer != null)
			_framebuffer.dispose();
		_framebuffer = FlxG.stage.context3D.createRectangleTexture(Std.int(_width), Std.int(_height), BGRA, true);
		bitmap = BitmapDataCrashFix.fromTextureCrashFix(_framebuffer);
		onUpdateBitmap(bitmap);
	}

	/**
	 * Renders the view.
	 */
	public override function render():Void
	{
		Stage3DProxy.drawTriangleCount = 0;

		// if context3D has Disposed by the OS,don't render at this frame
		if (stage3DProxy.context3D == null || !stage3DProxy.recoverFromDisposal())
		{
			_backBufferInvalid = true;
			return;
		}

		// reset or update render settings
		if (_backBufferInvalid)
			updateBackBuffer();

		if (_shareContext && _layeredView)
			stage3DProxy.clearDepthBuffer();

		if (!_parentIsStage)
		{
			var globalPos:Point = parent.localToGlobal(_localTLPos);
			if (_globalPos.x != globalPos.x || _globalPos.y != globalPos.y)
			{
				_globalPos = globalPos;
				_globalPosDirty = true;
			}
		}

		if (_globalPosDirty)
			updateGlobalPos();

		updateTime();

		updateViewSizeData();

		_entityCollector.clear();

		// collect stuff to render
		_scene.traversePartitions(_entityCollector);

		// update picking
		_mouse3DManager.updateCollider(this);
		_touch3DManager.updateCollider();

		if (_requireDepthRender)
			renderSceneDepthToTexture(_entityCollector);

		// todo: perform depth prepass after light update and before final render
		if (_depthPrepass)
			renderDepthPrepass(_entityCollector);

		@:privateAccess _renderer.clearOnRender = !_depthPrepass;

		if (_filter3DRenderer != null && _stage3DProxy.context3D != null)
		{
			_renderer.render(_entityCollector, _filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
			_filter3DRenderer.render(_stage3DProxy, camera, _depthRender);
		}
		else
		{
			@:privateAccess _renderer.shareContext = _shareContext;
			if (_shareContext)
				_renderer.render(_entityCollector, _framebuffer, _scissorRect);
			else
				_renderer.render(_entityCollector, _framebuffer);
		}

		if (!_shareContext)
		{
			stage3DProxy.present();

			// fire collected mouse events
			_mouse3DManager.fireMouseEvents();
			_touch3DManager.fireTouchEvents();
		}

		// clean up data for this render
		_entityCollector.cleanUp();

		// register that a view has been rendered
		stage3DProxy.bufferClear = false;
	}
}

class BitmapDataCrashFix extends BitmapData
{
	public static function fromTextureCrashFix(texture:TextureBase):BitmapDataCrashFix @:privateAccess {
		if (texture == null)
			return null;

		var bitmapData = new BitmapDataCrashFix(texture.__width, texture.__height, true, 0);
		bitmapData.readable = false;
		bitmapData.__texture = texture;
		bitmapData.__textureContext = texture.__textureContext;
		bitmapData.image = null;
		return bitmapData;
	}

	@:dox(hide) public override function getTexture(context:Context3D):TextureBase
	{
		return __texture;
	}
}
