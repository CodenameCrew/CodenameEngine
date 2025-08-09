package funkin.options.type;

import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import funkin.backend.shaders.CustomShader;
import funkin.backend.system.github.GitHub;
import openfl.display.BitmapData;
import funkin.backend.system.github.GitHubContributor.CreditsGitHubContributor;

class GithubIconOption extends TextOption
{
	public var user(default, null):CreditsGitHubContributor;  // Can possibly be GitHubUser or GitHubContributor, but CreditsGitHubContributor has only the fields we need
	public var icon:GithubUserIcon = null;
	public var usePortrait(default, set) = true;

	public function set_usePortrait(value:Bool)
	{
		if (icon == null) return usePortrait = false;
		icon.shader = (value ? new CustomShader('engine/circleProfilePicture') : null);
		return usePortrait = value;
	}

	public function new(user:CreditsGitHubContributor, desc:String, ?callback:Void->Void, ?customName:String, size:Int = 96, usePortrait:Bool = true, waitUntilLoad:Float = 0.25) {
		super(customName == null ? user.login : customName, desc, callback == null ? function() CoolUtil.openURL(user.html_url) : callback);
		this.user = user;
		this.icon = new GithubUserIcon(user, size, waitUntilLoad);
		this.usePortrait = usePortrait;
		add(icon);
		__text.x = 100;
	}
}

class GithubUserIcon extends FlxSprite
{
	public var waitUntilLoad:Null<Float>;
	private var user:CreditsGitHubContributor;
	private var size:Int;

	public override function new(user:CreditsGitHubContributor, size:Int = 96, waitUntilLoad:Float = 0.25) {
		this.user = user;
		this.size = size;
		this.waitUntilLoad = waitUntilLoad;
		super();
		makeGraphic(size, size, FlxColor.TRANSPARENT);
		antialiasing = true;
	}

	override function update(elapsed:Float) {
		if(waitUntilLoad > 0) waitUntilLoad -= elapsed;
		super.update(elapsed);
	}

	#if target.threaded
	final mutex = new sys.thread.Mutex();
	#end

	inline function acquireMutex() {
		#if target.threaded
		mutex.acquire();
		#end
	}
	inline function releaseMutex() {
		#if target.threaded
		mutex.release();
		#end
	}

	override function drawComplex(camera:FlxCamera):Void {  // Making the image download only if the player actually sees it on the screen  - Nex
		if(waitUntilLoad <= 0) {
			waitUntilLoad = null;
			Main.execAsync(function() {
				var key:String = 'GITHUB-USER:${user.login}';
				var bmap:Dynamic = FlxG.bitmap.get(key);

				if(bmap == null) {
					trace('Downloading avatar: ${user.login}');
					var unfLink:Bool = StringTools.endsWith(user.avatar_url, '.png');
					var planB:Bool = true;

					var bytes = null;
					if(unfLink) {
						try bytes = HttpUtil.requestBytes('${user.avatar_url}?size=$size')
						catch(e) Logs.error('Failed to download github pfp for ${user.login}: ${CoolUtil.removeIP(e.message)} - (Retrying using the api..)');

						if(bytes != null) {
							bmap = BitmapData.fromBytes(bytes);
							planB = false;
						}
					}

					if(planB) {
						if(unfLink) user = cast GitHub.getUser(user.login, function(e) Logs.error('Failed to download github user info for ${user.login}: ${CoolUtil.removeIP(e.message)}'));  // Api part - Nex
						try bytes = HttpUtil.requestBytes('${user.avatar_url}&size=$size')
						catch(e) Logs.error('Failed to download github pfp for ${user.login}: ${CoolUtil.removeIP(e.message)}');

						if(bytes != null) bmap = BitmapData.fromBytes(bytes);
					}

					if(bmap != null) try {
						acquireMutex();  // Avoiding critical section  - Nex
						var leGraphic:FlxGraphic = FlxG.bitmap.add(bmap, false, key);
						leGraphic.persist = true;
						updateDaFunni(leGraphic);
						bmap = null;
						releaseMutex();
					} catch(e) {
						Logs.error('Failed to update the pfp for ${user.login}: ${e.message}');
					}
				} else {
					acquireMutex();
					updateDaFunni(bmap);
					releaseMutex();
				}
			});
		}
		super.drawComplex(camera);
	}

	public inline function updateDaFunni(graphic:FlxGraphic) {
		loadGraphic(graphic);
		this.setUnstretchedGraphicSize(size, size, false);
		updateHitbox();
		x += 90 - width;
	}
}