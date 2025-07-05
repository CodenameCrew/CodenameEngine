package funkin.editors.ui;

import openfl.display.ShaderParameter;
import openfl.display.ShaderInput;
import openfl.filters.ShaderFilter;
import flixel.tweens.FlxTween;
import funkin.backend.shaders.CustomShader;

// TODO: make UIWarningSubstate extend this
class UISubstateWindow extends MusicBeatSubstate {
	var camShaders:Array<FlxCamera> = [];
	var blurShader:CustomShader = {
		var _ = new CustomShader(Options.intensiveBlur ? "engine/editorBlur" : "engine/editorBlurFast");
		if(!Options.intensiveBlur) {
			var noiseTexture:ShaderInput<openfl.display.BitmapData> = _.data.noiseTexture;
			noiseTexture.input = Assets.getBitmapData("assets/shaders/noise256.png");
			noiseTexture.wrap = REPEAT;
			var noiseTextureSize:ShaderParameter<Float> = _.data.noiseTextureSize;
			noiseTextureSize.value = [noiseTexture.input.width, noiseTexture.input.height];
		}
		_;
	};

	var titleSpr:UIText;
	var messageSpr:UIText;

	var subCam:FlxCamera;

	var windowSpr:UISliceSprite;

	public override function onSubstateOpen() {
		super.onSubstateOpen();
		parent.persistentUpdate = false;
		parent.persistentDraw = true;
	}

	var winWidth:Int = 560;
	var winHeight:Int = 570;
	var winTitle:String = "";

	public override function create() {
		super.create();

		for(c in FlxG.cameras.list) {
			// Prevent adding a shader if it already has one
			@:privateAccess if(c._filters != null) {
				var shouldSkip = false;
				for(filter in c._filters) {
					if(filter is ShaderFilter) {
						var filter:ShaderFilter = cast filter;
						if(filter.shader is CustomShader) {
							var shader:CustomShader = cast filter.shader;

							if(shader.path == blurShader.path) {
								shouldSkip = true;
								break;
							}
						}
					}
				}
				if(shouldSkip)
					continue;
			}
			camShaders.push(c);
			c.addShader(blurShader);
		}

		camera = subCam = new FlxCamera();
		subCam.bgColor = 0;
		subCam.alpha = 0;
		subCam.zoom = 0.1;
		FlxG.cameras.add(subCam, false);

		windowSpr = new UISliceSprite(0, 0, winWidth, winHeight, "editors/ui/normal-popup");
		add(windowSpr);

		add(titleSpr = new UIText(windowSpr.x + 25, windowSpr.y, windowSpr.bWidth - 50, winTitle, 15, -1));
		titleSpr.y = windowSpr.y + ((30 - titleSpr.height) / 2);

		FlxTween.tween(camera, {alpha: 1}, 0.25, {ease: FlxEase.cubeOut});
		FlxTween.tween(camera, {zoom: 1}, 0.66, {ease: FlxEase.elasticOut});
	}

	public override function destroy() {
		super.destroy();
		for(e in camShaders)
			e.removeShader(blurShader);

		blurShader = null;
		FlxTween.cancelTweensOf(subCam);
		FlxG.cameras.remove(subCam);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		subCam.scroll.set(Std.int(-(FlxG.width - windowSpr.bWidth) / 2), Std.int(-(FlxG.height - windowSpr.bHeight) / 2));
	}
}