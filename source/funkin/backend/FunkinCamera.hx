package funkin.backend;

import animate.internal.RenderTexture;
import flash.geom.ColorTransform;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxShader;
import funkin.backend.shaders.BlendModeShader;
import funkin.backend.framebuffer.FixedBitmapData;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.OpenGLRenderer;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Matrix;

/**
 * Camera extension for blend mode rendering support.
 * Taken from V-Slice (GitHub branch `blend-mode-experiment-2-electric-boogaloo`).
**/
@:nullSafety
@:access(openfl.display.DisplayObject)
@:access(openfl.display.BitmapData)
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.geom.ColorTransform)
class FunkinCamera extends FlxCamera
{
  public static final SHADER_REQUIRED_BLEND_MODES:Array<BlendMode> = [
    DARKEN,
    HARDLIGHT,
    #if !desktop LIGHTEN, #end
    INVERT,
    OVERLAY,
    DIFFERENCE,
	COLORDODGE,
	COLORBURN,
	SOFTLIGHT,
	EXCLUSION,
	HUE,
	SATURATION,
	COLOR,
	LUMINOSITY
  ];

  var _blendShader:BlendModeShader;

  var _blendRenderTexture:RenderTexture;
  var _backgroundRenderTexture:RenderTexture;

  var _cameraTexture:Null<BitmapData>;
  var _cameraMatrix:FlxMatrix;

  var _renderer:OpenGLRenderer;

  @:nullSafety(Off)
  public function new(x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, zoom:Float = 0)
  {
    var w:Int = (width  < 1) ? FlxG.width  : width;
    var h:Int = (height < 1) ? FlxG.height : height;

    super(x, y, w, h, zoom);

    _blendShader = new BlendModeShader();

    _backgroundRenderTexture = new RenderTexture(w, h);
    _blendRenderTexture = new RenderTexture(w, h);

    _cameraMatrix = new FlxMatrix();

    _renderer = new OpenGLRenderer(FlxG.stage.context3D);
    _renderer.__worldTransform = new Matrix();
    _renderer.__worldColorTransform = new ColorTransform();
  }
  
  public function grabScreen(clearScreen:Bool = false):Null<BitmapData>
  {
    var w:Int = (width  < 1) ? 1 : width;
    var h:Int = (height < 1) ? 1 : height;

    if (_cameraTexture == null || _cameraTexture.width != w || _cameraTexture.height != h)
    {
      if (_cameraTexture != null)
      {
        _cameraTexture.dispose();
        _cameraTexture = null;
      }

      var texture:Null<TextureBase> = _createTexture(w, h);
      if (texture == null) return null;

      _cameraTexture = FixedBitmapData.fromTexture(texture);
    }

    if (_cameraTexture != null)
    {
      var matrix:FlxMatrix = new FlxMatrix();
      var pivotX:Float = FlxG.scaleMode.scale.x;
      var pivotY:Float = FlxG.scaleMode.scale.y;

      matrix.setTo(1 / pivotX, 0, 0, 1 / pivotY, flashSprite.x / pivotX, flashSprite.y / pivotY);

      _cameraTexture.__fillRect(_cameraTexture.rect, 0, true);

      // render this camera, then draw its openFL canvas into the gpu texture
      this.render();
      this.flashSprite.__update(false, true);

      _renderer.__cleanup();
      _renderer.setShader(_renderer.__defaultShader);
      _renderer.__allowSmoothing = false;
      _renderer.__pixelRatio = Lib.current.stage.window.scale;

      _renderer.__worldAlpha = 1 / this.flashSprite.__worldAlpha;
      _renderer.__worldTransform.copyFrom(this.flashSprite.__renderTransform);
      _renderer.__worldTransform.invert();
      _renderer.__worldTransform.concat(matrix);
      _renderer.__worldColorTransform.__copyFrom(this.flashSprite.__worldColorTransform);
      _renderer.__worldColorTransform.__invert();

      _renderer.__setRenderTarget(_cameraTexture);
      _cameraTexture.__drawGL(this.canvas, _renderer);

      if (clearScreen)
      {
        this.clearDrawStack();
        this.canvas.graphics.clear();
      }
    }

    return _cameraTexture;
  }

  override function drawPixels(?frame:flixel.graphics.frames.FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix,
      ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader):Void
  {
    var shouldUseShader:Bool = (blend != null) && SHADER_REQUIRED_BLEND_MODES.contains(blend);
    if (!shouldUseShader)
    {
      super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
      return;
    }

    var lastBackground = grabScreen(true);

    // build source (the sprite being drawn) into a RT
    _blendRenderTexture.init(this.width, this.height);
    _blendRenderTexture.drawToCamera((camera, frameMatrix) ->
    {
      var pivotX:Float = width / 2;
      var pivotY:Float = height / 2;

      frameMatrix.copyFrom(matrix);
      frameMatrix.translate(-pivotX, -pivotY);
      frameMatrix.scale(this.scaleX, this.scaleY);
      frameMatrix.translate(pivotX, pivotY);

      camera.drawPixels(frame, pixels, frameMatrix, transform, null, smoothing, shader);
    });
    _blendRenderTexture.render();

    if (lastBackground == null || _blendRenderTexture.graphic == null || _blendRenderTexture.graphic.bitmap == null)
    {
      FlxG.log.error('Failed to get bitmap for blending!');
      super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
      return;
    }

    _blendShader.sourceSwag = _blendRenderTexture.graphic.bitmap;
    _blendShader.backgroundSwag = lastBackground;
    _blendShader.blendSwag = blend;
    _blendShader.updateViewInfo(width, height, this);

    // (fixes "frame null ... size (0,0)")
    var srcFrame = _blendRenderTexture.graphic.imageFrame.frame;

    _backgroundRenderTexture.init(this.width, this.height);
    _backgroundRenderTexture.drawToCamera((camera, mtx) ->
    {
      camera.zoom = this.zoom;

      mtx.identity();
      camera.drawPixels(srcFrame, null, mtx, canvas.transform.colorTransform, null, false, _blendShader);
    });
    _backgroundRenderTexture.render();
	
    _cameraMatrix.identity();
    _cameraMatrix.scale(1 / this.scaleX, 1 / this.scaleY);
    _cameraMatrix.translate(((width - width / this.scaleX) * 0.5), ((height - height / this.scaleY) * 0.5));

    super.drawPixels(_backgroundRenderTexture.graphic.imageFrame.frame, null, _cameraMatrix, null, null, smoothing, null);
  }

  override function destroy():Void
  {
    super.destroy();

    if (_blendRenderTexture != null) _blendRenderTexture.destroy();
    if (_backgroundRenderTexture != null) _backgroundRenderTexture.destroy();

    if (_cameraTexture != null)
    {
      _cameraTexture.dispose();
      _cameraTexture = null;
    }
  }

  function _createTexture(width:Int, height:Int):Null<TextureBase>
  {
    width = width < 1 ? 1 : width;
    height = height < 1 ? 1 : height;
    return Lib.current.stage.context3D.createTexture(width, height, BGRA, true);
  }
}
