package funkin.menus.gamejolt;

import flixel.addons.display.FlxBackdrop;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.backend.system.gamejolt.*;
import funkin.editors.ui.*;
import funkin.menus.gamejolt.*;

class GameJoltMenu extends UIState
{
	// Main page variables
	var bg:FlxBackdrop;
	var userBorder:UISprite;
	var userBackground:UISprite;
	var mainTitleText:UIText;
	var userPhoto:UISprite;
	var subTitleText:UIText;
	var trophyOrLoginButton:UIButton;
	var leaderOrRegisterButton:UIButton;
	var userDataButton:UIButton;
	var ownerDataButton(default, null):UIButton;
	var logoutButton:UIButton;

	// Secondary page variables
	var secondaryTitleText:UIText;
	var subBox:UISprite;
	var mainBox:UISprite;

	var onHome(default, set):Bool;
	var secondaryPage(default, set):String;
	var isDaOwner(default, null):Bool = (GameJoltSecurity.userId == GameJoltData.ownerUserId && GameJoltSecurity.userId != null);

	var daSprites:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();
	override function create()
	{
		super.create();

		add(bg = new FlxBackdrop());
		bg.loadGraphic(Paths.image('editors/bgs/default'));
		bg.antialiasing = true;
		bg.rotation = -5;
		bg.velocity.set(85, 0).degrees = bg.rotation;

		add(daSprites);

		userBorder = new UISprite();
		userBorder.makeGraphic(264, 264, FlxColor.BLACK);
		userBorder.screenCenter(X);
		daSprites.add(userBorder);

		userBackground = new UISprite();
		userBackground.makeGraphic(256, 256, FlxColor.GRAY);
		userBackground.screenCenter(X);
		daSprites.add(userBackground);

		mainTitleText = new UIText(0, 80, FlxG.width, (GJUtil.loggedIn ? "GAMEJOLT: " + GJUtil.userName : "NOT LOGGED IN"), 60);
		mainTitleText.alignment = CENTER;
		userBorder.y = mainTitleText.y + mainTitleText.height + 20;
		userBackground.y = userBorder.y + 4;
		daSprites.add(mainTitleText);

		userPhoto = new UISprite(userBackground.x, userBackground.y);

		if (GJUtil.loggedIn) {
			GJUtil.getAvatarImage(userPhoto, () -> {
				userPhoto.setGraphicSize(256, 256);
				userPhoto.updateHitbox();
				userPhoto.screenCenter(X);
				userPhoto.visible = true;
			});
			userPhoto.screenCenter(X);
			daSprites.add(userPhoto);
			userPhoto.visible = false;

			subTitleText = new UIText(20, userBorder.y + userBorder.height + 20, FlxG.width - 40, '"${GJUtil.userDescription}"', 16);
			subTitleText.alignment = CENTER;
			subTitleText.italic = true;
			daSprites.add(subTitleText);

			trophyOrLoginButton = new UIButton((FlxG.width / 2) - (isDaOwner ? 470  : 390), FlxG.height - 128, "Achievements", () -> {
				secondaryPage = 'achievements';
				onHome = false;
			}, 180, 48);
			// trophyOrLoginButton.color = 0xFF31FF31;
			trophyOrLoginButton.field.size = 23;
			daSprites.add(trophyOrLoginButton);

			leaderOrRegisterButton = new UIButton((FlxG.width / 2) - (isDaOwner ? 280 : 190), FlxG.height - 128, "Leaderboards", () -> {
				secondaryPage = 'leaderboards';
				onHome = false;
			}, 180, 48);
			// leaderOrRegisterButton.color = 0xFF31FF31;
			leaderOrRegisterButton.field.size = 23;
			daSprites.add(leaderOrRegisterButton);

			userDataButton = new UIButton((FlxG.width / 2) - (isDaOwner ? 90 : -10), FlxG.height - 128, "User Data", () -> {
				// UI Window - WIP
				openSubState(new GameJoltDataWindow(USER));
			}, 180, 48);
			// userDataButton.color = 0xFF31FF31;
			userDataButton.field.size = 23;
			daSprites.add(userDataButton);

			if(isDaOwner) {
				ownerDataButton = new UIButton((FlxG.width / 2) + 100, FlxG.height - 128, "Global Data", () -> {
					// UI Window - WIP
					openSubState(new GameJoltDataWindow(GLOBAL));
				}, 180, 48);
				// ownerDataButton.color = 0xFF31FF31;
				ownerDataButton.field.size = 23;
				daSprites.add(ownerDataButton);
			}

			logoutButton = new UIButton((FlxG.width / 2) + (isDaOwner ? 290 : 210), FlxG.height - 128, "Logout", () -> {
				openSubState(new GameJoltConfirmationWindow('Logout', 'Are you sure you want to log out of GameJolt? This will log you out of ALL mods on this build of CNE!', () -> {
					closeSubState();
					GJUtil.logout(true);
					FlxG.resetState();
				}));
			}, 180, 48);
			logoutButton.color = 0xFFFF0000;
			logoutButton.field.size = 23;
			daSprites.add(logoutButton);

			secondaryTitleText = new UIText(FlxG.width, 80, FlxG.width, "", 60);
			secondaryTitleText.alignment = CENTER;
			daSprites.add(secondaryTitleText);

			subBox = new UISprite(FlxG.width + 100, secondaryTitleText.height + 100);
			subBox.makeGraphic(Std.int(((FlxG.width - 200) / 4) - 25), Std.int(FlxG.height - subBox.y - 100), FlxColor.WHITE);
			daSprites.add(subBox);

			mainBox = new UISprite(subBox.width + subBox.x + 50, subBox.y);
			mainBox.makeGraphic(Std.int((subBox.width * 3) + 25), Std.int(subBox.height), FlxColor.WHITE);
			daSprites.add(mainBox);
		} else {
			userPhoto.loadGraphic(Paths.image('menus/gamejolt-icon'));
			userPhoto.setGraphicSize(248, 248);
			userPhoto.updateHitbox();
			userPhoto.screenCenter(X);
			userPhoto.y += 4;
			daSprites.add(userPhoto);

			subTitleText = new UIText(0, userPhoto.y + userPhoto.height + 30, FlxG.width, "Login with your GameJolt account to see leaderboards, get achievements, save your data, and more!", 35);
			subTitleText.alignment = CENTER;
			daSprites.add(subTitleText);

			trophyOrLoginButton = new UIButton((FlxG.width / 2) + 10, FlxG.height - 128, "Login", () -> {
				openSubState(new GameJoltLoginWindow());
			}, 180, 48);
			trophyOrLoginButton.color = 0xFF31FF31;
			trophyOrLoginButton.field.size = 23;
			daSprites.add(trophyOrLoginButton);

			leaderOrRegisterButton = new UIButton((FlxG.width / 2) - 190, FlxG.height - 128, "Register", () -> {
				CoolUtil.openURL('https://gamejolt.com/join');
			}, 180, 48);
			leaderOrRegisterButton.color = 0xFF31FF31;
			leaderOrRegisterButton.field.size = 23;
			daSprites.add(leaderOrRegisterButton);
		}

		@:bypassAccessor onHome = true;
		secondaryPage = 'achievements';
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK) {
			CoolUtil.playMenuSFX(CANCEL, 0.7);
			if (onHome)
				FlxG.switchState(new MainMenuState());
			else
				onHome = true;
		}
	}

	function set_onHome(onH:Bool):Bool
	{
		FlxTween.num(0, FlxG.width, 1, { }, function(num:Float) {
			var prcnt:Float = num / FlxG.width;
			bg.velocity.set(85 * (1 + (Math.sin(Math.PI * prcnt) * (onH ? -1 : 1))));
			daSprites.x = FlxEase.elasticInOut(onH ? (1 - prcnt) : prcnt) * -FlxG.width;
		});
		return onHome = onH;
	}

	function set_secondaryPage(type:String):String
	{
		if (secondaryTitleText != null) secondaryTitleText.text = type.toUpperCase();
		return secondaryPage = type;
	}
}