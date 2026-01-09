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

class TextureView3D extends View3D {
	public var bitmap:BitmapData;
	private var _framebuffer:TextureBase = null;
	private var _initialised:Bool = false;
	public var addCallback:() -> Void;
	
	public override function dispose() @:privateAccess{
		/*_stage3DProxy._stage3DManager.removeStage3DProxy(_stage3DProxy);
		_stage3DProxy._stage3DIndex = -1;
		_stage3DProxy._stage3DManager = null;
		_stage3DProxy._stage3D = null;*/
		_stage3DProxy = null;
		super.dispose();
	}

	private override function set_height(value:Float):Float {
		if (_height == value) return value;
		super.set_height(value);
		_createFramebuffer();
		return value;
	}
	private override function set_width(value:Float):Float {
		if (_width == value) return value;
		super.set_width(value);
		_createFramebuffer();
		return value;
	}

	public function new(scene:Scene3D = null, camera:Camera3D = null, renderer:RendererBase = null, forceSoftware:Bool = false, profile:String = "baseline",
			contextIndex:Int = -1) {
		super(scene, camera, renderer, forceSoftware, profile, contextIndex);
		
		_stage3DProxy = Stage3DManager.getInstance(FlxG.stage).getStage3DProxy(0);
		_initialised = true;
		_createFramebuffer();
	}

	private function _createFramebuffer() {
		if (width == 0 || height == 0) return;
		_framebuffer = FlxG.stage.context3D.createRectangleTexture(Std.int(_width), Std.int(_height), BGRA, true);
		bitmap = BitmapDataCrashFix.fromTextureCrashFix(_framebuffer);
		addCallback();
	}

	/**
	 * Renders the view.
	 */
	public override function render():Void 
	{
		Stage3DProxy.drawTriangleCount = 0;

		// if context3D has Disposed by the OS,don't render at this frame
		if (stage3DProxy.context3D == null || !stage3DProxy.recoverFromDisposal()) {
			_backBufferInvalid = true;
			return;
		}

		// reset or update render settings
		if (_backBufferInvalid)
			updateBackBuffer();

		if (_shareContext && _layeredView)
			stage3DProxy.clearDepthBuffer();

		if (!_parentIsStage) {
			var globalPos:Point = parent.localToGlobal(_localTLPos);
			if (_globalPos.x != globalPos.x || _globalPos.y != globalPos.y) {
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

		if (_filter3DRenderer != null && _stage3DProxy.context3D != null) {
			_renderer.render(_entityCollector, _filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
			_filter3DRenderer.render(_stage3DProxy, camera, _depthRender);
		} else {
			@:privateAccess _renderer.shareContext = _shareContext;
			if (_shareContext)
				_renderer.render(_entityCollector, _framebuffer, _scissorRect);
			else
				_renderer.render(_entityCollector, _framebuffer);
		}

		if (!_shareContext) {
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

	// idk if i need this but i'll keep commented in case removing it breaks anything

	/*private override function updateBackBuffer():Void {
		// No reason trying to configure back buffer if there is no context available.
		// Doing this anyway (and relying on _stage3DProxy to cache width/height for
		// context does get available) means usesSoftwareRendering won't be reliable.
		if (_stage3DProxy.context3D != null && !_shareContext) {
			if (_globalWidth > 0 && _globalHeight > 0) {
				// Backbuffers are limited to 2048x2048 in software mode and
				// trying to configure the backbuffer to be bigger than that
				// will throw an error. Capping the value is a graceful way of
				// avoiding runtime exceptions for developers who are unable
				// to test their Away3D implementation on screens that are
				// large enough for this error to ever occur.
				if (_stage3DProxy.usesSoftwareRendering) {
					// Even though these checks where already made in the width
					// and height setters, at that point we couldn't be sure that
					// the context had even been retrieved and the software flag
					// thus be reliable. Make checks again.
					if (_globalWidth > 2048)
						_globalWidth = 2048;
					if (_globalHeight > 2048)
						_globalHeight = 2048;
				}

				_stage3DProxy.configureBackBuffer(Std.int(_globalWidth), Std.int(_globalHeight), _antiAlias, true);
				_backBufferInvalid = false;
			} else {
				/*var stageBR:Point = new Point(stage.x + stage.stageWidth, stage.y + stage.stageHeight);
				width = parent != null ? parent.globalToLocal(stageBR).x - _localTLPos.x : stage.stageWidth;
				height = parent != null ? parent.globalToLocal(stageBR).y - _localTLPos.y : stage.stageHeight;* /
			}
		}
	}*/
}


class BitmapDataCrashFix extends BitmapData {
	public static function fromTextureCrashFix(texture:TextureBase):BitmapDataCrashFix
	@:privateAccess {
		if (texture == null) return null;

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