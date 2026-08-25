package funkin.menus.gamejolt;

import funkin.backend.utils.GJUtil.GJResponse;
import funkin.backend.utils.GJUtil.RequestType;
import openfl.display.BitmapData;
import lime.graphics.Image;
import flixel.graphics.FlxGraphic;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.backend.system.gamejolt.*;
import funkin.editors.ui.*;
import funkin.menus.gamejolt.*;

class GameJoltMenu extends UIState
{
	public static var leaderboardLimit:Int = 50;
	public static var achRowSpacing:Int = 10;
	public static var achRowAmount:Int = 5;
	public static var boxContentBorderSize:Int = 5;
	public static var achievementSelectScale:Float = 1.2;
	public static var achEase:Float->Float = FlxEase.elasticOut;
	public static var achScaleTime:Float = 1.5;
	public static var displayHiddenTrophies:Bool = false;

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
	var subBoxBacking:UISprite;
	var mainBoxBacking:UISprite;
	var mainBoxScroll:UIScrollBar;
	var subBoxAch:FlxTypedSpriteGroup<UIText>;
	var mainBoxAch:FlxTypedSpriteGroup<UISprite>;
	var missingTextAch:Null<UIText> = null;
	var subBoxLead:FlxTypedSpriteGroup<UIText>;
	var mainBoxLead:FlxTypedSpriteGroup<GameJoltLeaderboardItem>;
	var missingTextLead:Null<UIText> = null;
	var trophyTitle:UIText;
	var trophyDesc:UIText;
	var noScoresLead:UIText;
	var rankLead:UIText;

	var onHome(default, set):Bool;
	@:bypassAccessor var daInd(default, set):Int = 0;
	var daMax:Int = 0;
	var secondaryPage(default, set):String;
	var isDaOwner(default, null):Bool = (GameJoltSecurity.userId == GameJoltData.ownerUserId && GameJoltSecurity.userId != null);
	var scoresMap:Map<String, Int> = new Map<String, Int>();
	var trophiesMap:Map<Int, GJUtil.Trophy> = new Map<Int, GJUtil.Trophy>();
	var daSprites:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();
	var noScaleTween:Bool = false;
	var inTween:FlxTween = null;
	var outTween:FlxTween = null;

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
			//region Main Page
			GJUtil.getAvatarImage(userPhoto, null, () -> {
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
			//endregion

			//region Secondary Page
			secondaryTitleText = new UIText(FlxG.width, 80, FlxG.width, "", 60);
			secondaryTitleText.alignment = CENTER;
			daSprites.add(secondaryTitleText);

			subBoxBacking = new UISprite(FlxG.width + 100, secondaryTitleText.height + 100);
			subBoxBacking.makeGraphic(Std.int(((FlxG.width - 200) / 4) - 25), Std.int(FlxG.height - subBoxBacking.y - 100), FlxColor.GRAY);
			daSprites.add(subBoxBacking);

			mainBoxBacking = new UISprite(subBoxBacking.width + subBoxBacking.x + 50, subBoxBacking.y);
			mainBoxBacking.makeGraphic(Std.int((subBoxBacking.width * 3) + 25), Std.int(subBoxBacking.height), FlxColor.GRAY);
			daSprites.add(mainBoxBacking);

			// for achievements, put the main box on the left and the sub box on the right
			mainBoxAch = new FlxTypedSpriteGroup<UISprite>(subBoxBacking.x + boxContentBorderSize, subBoxBacking.y + boxContentBorderSize);
			mainBoxAch.clipRect = new FlxRect(0, 0, mainBoxBacking.width - (boxContentBorderSize * 4), mainBoxBacking.height - (boxContentBorderSize * 4));
			daSprites.add(mainBoxAch);

			subBoxAch = new FlxTypedSpriteGroup<UIText>(subBoxBacking.x + mainBoxBacking.width + boxContentBorderSize + 50, subBoxBacking.y + boxContentBorderSize);
			subBoxAch.clipRect = new FlxRect(0, 0, subBoxBacking.width - (boxContentBorderSize * 3), subBoxBacking.height - (boxContentBorderSize * 4));
			daSprites.add(subBoxAch);

			subBoxLead = new FlxTypedSpriteGroup<UIText>(subBoxBacking.x + boxContentBorderSize, subBoxBacking.y + boxContentBorderSize);
			subBoxLead.clipRect = new FlxRect(0, 0, subBoxBacking.width - (boxContentBorderSize * 3), subBoxBacking.height - (boxContentBorderSize * 4));
			daSprites.add(subBoxLead);

			mainBoxLead = new FlxTypedSpriteGroup<GameJoltLeaderboardItem>(mainBoxBacking.x + boxContentBorderSize, mainBoxBacking.y + boxContentBorderSize);
			mainBoxLead.clipRect = new FlxRect(0, 0, mainBoxBacking.width - (boxContentBorderSize * 4), mainBoxBacking.height - (boxContentBorderSize * 4));
			daSprites.add(mainBoxLead);

			var reqsToMake:Array<RequestType> = [];
			if (GameJoltData.definedTrophies.toString() == '[]' && GameJoltData.customTrophies.toString() == '[]')
				daSprites.add(missingTextAch = new UIText(mainBoxAch.x, mainBoxAch.y, mainBoxAch.clipRect.width, "NO TROPHIES FOUND FOR THIS MOD!", 48));
			else
				reqsToMake.push(TROPHIES_FETCH());

			if (GameJoltData.leaderboards.toString() == '[]')
				daSprites.add(missingTextLead = new UIText(mainBoxLead.x, mainBoxLead.y, mainBoxLead.clipRect.width, "NO LEADERBOARDS AVAILABLE FOR THIS MOD!", 48));
			else
				reqsToMake.push(SCORES_TABLES);

			// do this in a batch to make sure we get everything
			GameJoltSecurity.sendTrusted(BATCH(true, false, reqsToMake), true, function(err) {
				daSprites.add(missingTextAch = new UIText(mainBoxAch.x, mainBoxAch.y, mainBoxAch.clipRect.width, "UNABLE TO FETCH TROPHIES: " + err, 48));
				daSprites.add(missingTextLead = new UIText(mainBoxLead.x, mainBoxLead.y, mainBoxLead.clipRect.width, "UNABLE TO FETCH LEADERBOARDS: " + err, 48));
			}, function(resp) {
				// seeing if we have a response for trophies or scoreboards
				var trophyResp:Null<GJResponse> = null;
				var scoresResp:Null<GJResponse> = null;
				if (resp.responses.length > 1) {
					trophyResp = resp.responses[0];
					scoresResp = resp.responses[1];
				} else {
					if (resp.responses[0].trophies == null || resp.responses[0].trophies.length <= 0)
						trophyResp = resp.responses[0]
					else if (resp.responses[0].tables == null || resp.responses[0].tables.length <= 0)
						scoresResp = resp.responses[0];
				}

				// achievement trophy image loading
				if (trophyResp == null) {
					daSprites.add(missingTextAch = new UIText(mainBoxAch.x, mainBoxAch.y, mainBoxAch.clipRect.width, "NO TROPHIES FOUND FOR THIS MOD!", 48));
				} else {
					var placeInd:Int = 0;
					var photoSize:Int = Std.int((mainBoxAch.clipRect.width - (achRowSpacing * Math.max(0, achRowAmount - 1))) / achRowAmount);
					for (trop in trophyResp.trophies) {
						var canDisplay:Bool = false;
						var hiddenTrop:Bool = false;
						for (t in GameJoltData.definedTrophies) {
							if ('${t.id}' == '${trop.id}') {
								canDisplay = true;
								if (t.hidden != null && t.hidden)
									hiddenTrop = true;
							}
						}

						for (t in GameJoltData.customTrophies) {
							if ('${t.id}' == '${trop.id}') {
								canDisplay = true;
								if (t.hidden != null && t.hidden)
									hiddenTrop = true;
							}
						}

						if (!canDisplay || (hiddenTrop && !displayHiddenTrophies))
							continue;

						var tropSprite:UISprite = new UISprite(((achRowSpacing + photoSize) * (placeInd % achRowAmount)) + (achRowSpacing / 2), ((photoSize + achRowSpacing) * Math.floor(placeInd / achRowAmount)) + (achRowSpacing / 2));
						GJUtil.getTrophyImage(tropSprite, trop, () -> {
							tropSprite.setGraphicSize(photoSize, photoSize);
							tropSprite.updateHitbox();
						});
						tropSprite.ID = placeInd;
						if (trop.achieved == "false")
							tropSprite.color = FlxColor.GRAY;
						trophiesMap.set(placeInd, trop);
						mainBoxAch.add(tropSprite);
						placeInd++;
					}

					if (placeInd == 0)
						daSprites.add(missingTextAch = new UIText(mainBoxAch.x, mainBoxAch.y, mainBoxAch.clipRect.width, "NO TROPHIES FOUND FOR THIS MOD!", 48));
					else {
						subBoxAch.add(trophyTitle = new UIText(achRowSpacing / 2, achRowSpacing / 2, subBoxAch.clipRect.width - (boxContentBorderSize * 2), "", 38));
						trophyTitle.alignment = CENTER;
						subBoxAch.add(trophyDesc = new UIText(achRowSpacing / 2, achRowSpacing / 2, subBoxAch.clipRect.width - (boxContentBorderSize * 2), "", 20));
						trophyDesc.alignment = CENTER;
					}
				}

				// leaderboard loading
				if (scoresResp == null)
					daSprites.add(missingTextLead = new UIText(mainBoxLead.x, mainBoxLead.y, mainBoxLead.clipRect.width, "NO LEADERBOARDS AVAILABLE FOR THIS MOD!", 48));
				else {
					var amount:Int = 0;
					for (board in scoresResp.tables) {
						for (b in GameJoltData.leaderboards) {
							if ('$b' == '${board.id}') {
								scoresMap.set(board.name, board.id);
								amount++;
							}
						}
					}

					if (amount == 0) {
						daSprites.add(missingTextLead = new UIText(mainBoxLead.x, mainBoxLead.y, mainBoxLead.clipRect.width, "NO LEADERBOARDS AVAILABLE FOR THIS MOD!", 48));
					} else {
						var daY:Float = 0;
						for (name in scoresMap.keys()) {
							var daText:UIText = new UIText(0, daY, subBoxLead.clipRect.width, name, 24);
							daText.textField.background = true;
							daText.textField.backgroundColor = 0x0011AA00;
							daText.wordWrap = false;
							daText.autoSize = false;
							subBoxLead.add(daText);
							daY += daText.height;
						}

						for (i in 0...leaderboardLimit) {
							var anEntry:GameJoltLeaderboardItem = new GameJoltLeaderboardItem();
							mainBoxLead.add(anEntry);
						}

						daSprites.add(noScoresLead = new UIText(mainBoxLead.x, mainBoxLead.y, mainBoxLead.clipRect.width, "NO SCORES AVAILABLE FOR THIS LEADERBOARD!", 48));
						noScoresLead.alignment = CENTER;
						daSprites.add(rankLead = new UIText(mainBoxLead.x, mainBoxLead.y, mainBoxLead.clipRect.width, "YOUR RANK: --- (NOT SCORED YET!)", 32));
						rankLead.alignment = CENTER;
					}
				}
			});

			if (missingTextAch != null)
				missingTextAch.alignment = CENTER;
			
			if (missingTextLead != null)
				missingTextLead.alignment = CENTER;
			//endregion
		} else {
			//region Login Page
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
			//endregion
		}

		@:bypassAccessor onHome = true;
		secondaryPage = 'achievements';
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var scroll = FlxG.mouse.wheel;
		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;

		if (!onHome) switch (secondaryPage) {
			case "leaderboards":
				if (subBoxLead.members.length > 1 && (upP || downP || scroll != 0))
					daInd = FlxMath.wrap(daInd + (upP ? -1 : 0) + (downP ? 1 : 0) - scroll, 0, mainBoxLead.members.length - 1);
			case "achievements":
				if (mainBoxAch.members.length > 1 && (leftP || rightP || scroll != 0))
					daInd = FlxMath.wrap(daInd + (leftP ? -1 : 0) + (rightP ? 1 : 0) - scroll, 0, mainBoxAch.members.length - 1);
			case _:

		}
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

	function set_daInd(newInd:Int):Int
	{
		if (secondaryTitleText != null) switch(secondaryTitleText.text) {
			case "LEADERBOARDS":
				if (mainBoxLead.members.length > 0) {
					for (member in mainBoxLead.members)
						member.clearData();
				
					if (daInd != newInd && subBoxLead.members[daInd] != null)
						subBoxLead.members[daInd].textField.backgroundColor = 0x0011AA00;
					subBoxLead.members[newInd].textField.backgroundColor = 0xff11AA00;
					var daId:Int = scoresMap.get(subBoxLead.members[newInd].text);
					GameJoltSecurity.sendTrusted(BATCH(true, false, [SCORES_FETCH(false, daId, leaderboardLimit), SCORES_FETCH(true, daId)]), true, function(err) {
						Logs.error("Leaderboard fetch error: " + err, RED, 'GameJolt');
					}, function(resp) {
						if (resp.responses[0].scores == null || resp.responses[0].scores.length <= 0) {
							noScoresLead.visible = true;
							rankLead.visible = false;
						} else {
							rankLead.visible = true;
							noScoresLead.visible = false;
							for (i in 0...resp.responses[0].scores.length) {
								var usr = resp.responses[0].scores[i];
								mainBoxLead.members[i].setData(Std.int(mainBoxLead.clipRect.width), Std.int(mainBoxLead.clipRect.height / 8.5), usr.user, usr.score, i);
								// fun fact: wanted to try and include pfp's, but the calls would've been a bit much, at least imo. ~SPD
							}

							if(resp.responses[1].scores[0] != null)
								GameJoltSecurity.sendTrusted(SCORES_GETRANK(resp.responses[1].scores[0].sort, daId), true, function(err) {
									Logs.error("Error fetching user rank: " + err, RED, 'GameJolt');
									rankLead.text = 'YOUR RANK: --- (??????)';
								}, function(respSec) {
									rankLead.text = 'YOUR RANK: ${respSec.rank != null ? '${respSec.rank}' : '---'} (${resp.responses[1].scores[0].score})';
								})
							else
								rankLead.text = 'YOUR RANK: --- (NOT SCORED YET!)';
						}
					});
				}

			case "ACHIEVEMENTS":
				if (mainBoxAch.members.length > 0) {
					if (noScaleTween) {
						mainBoxAch.members[daInd].scale.set(1, 1);
						mainBoxAch.members[daInd].scale.set(achievementSelectScale, achievementSelectScale);
					} else {
						FlxTween.cancelTweensOf(mainBoxAch.members[daInd].scale);
						FlxTween.cancelTweensOf(mainBoxAch.members[newInd].scale);
						FlxTween.tween(mainBoxAch.members[daInd].scale, { x: 1, y: 1 }, achScaleTime, { ease: achEase });
						FlxTween.tween(mainBoxAch.members[newInd].scale, { x: achievementSelectScale, y: achievementSelectScale }, achScaleTime, { ease: achEase });
					}

					trophyTitle.text = trophiesMap.get(mainBoxAch.members[newInd].ID).title.toUpperCase();
					trophyDesc.y = trophyTitle.y + trophyTitle.height + achRowSpacing;
					trophyDesc.text = trophiesMap.get(mainBoxAch.members[newInd].ID).description;
				}
		}
		return daInd = newInd;
	}

	function set_secondaryPage(type:String):String
	{
		if (secondaryTitleText != null) switch(type) {
			case "leaderboards":
				secondaryTitleText.text = type.toUpperCase();
				subBoxAch.active = subBoxAch.visible = mainBoxAch.active = mainBoxAch.visible = false;
				if (missingTextAch != null)
					missingTextAch.visible = false;
				subBoxLead.active = subBoxLead.visible = mainBoxLead.active = mainBoxLead.visible = true;
				if (missingTextLead != null)
					missingTextLead.visible = true;
				subBoxBacking.x = FlxG.width + 100;
				mainBoxBacking.x = subBoxBacking.width + subBoxBacking.x + 50;
				noScaleTween = true;
				daInd = 0;
				noScaleTween = false;

			case "achievements":
				secondaryTitleText.text = type.toUpperCase();
				subBoxAch.active = subBoxAch.visible = mainBoxAch.active = mainBoxAch.visible = true;
				if (missingTextAch != null)
					missingTextAch.visible = true;
				subBoxLead.active = subBoxLead.visible = mainBoxLead.active = mainBoxLead.visible = false;
				if (missingTextLead != null)
					missingTextLead.visible = false;
				if (noScoresLead != null)
					noScoresLead.visible = false;
				if (rankLead != null)
					rankLead.visible = false;
				mainBoxBacking.x = FlxG.width + 100;
				subBoxBacking.x = mainBoxBacking.width + mainBoxBacking.x + 50;
				noScaleTween = true;
				daInd = 0;
				noScaleTween = false;
		}
			
		return secondaryPage = type;
	}
}

//region Leaderboard Items
class GameJoltLeaderboardItem extends FlxTypedSpriteGroup<FlxSprite>
{
	public var selected(default, set):Bool;

	var name(default, set):String;
	var score(default, set):String;
	var rank(default, set):Int;

	var daWidth(default, set):Int;
	var daHeight(default, set):Int;

	var nameText:UIText;
	var scoreText:UIText;
	var rankText:UIText;
	var profilePic:UISprite;
	var background:UISprite;

	override public function new()
	{
		super();

		add(background = new UISprite());
		background.alpha = 0.6;
		background.visible = false;

		add(nameText = new UIText(0, 0, width, ""));
		add(scoreText = new UIText(0, 0, width, ""));
		add(rankText = new UIText(0, 0, width, ""));
		add(profilePic = new UISprite());

		@:bypassAccessor selected = false;
	}

	public function setData(width:Int = 200, height:Int = 200, name:String, score:String, rank:Int, ?image:FlxGraphic)
	{
		this.name = name;
		this.score = score;
		this.rank = rank;

		if (image != null)
			profilePic.loadGraphic(image);

		this.height = height;
		this.width = width;

		active = visible = true;
	}

	public function clearData()
	{
		name = "";
		score = "";
		rank = 0;
		height = 0;
		width = 0;
		active = visible = false;
	}

	inline function set_selected(sel:Bool):Bool
	{
		background.visible = sel;
		return selected = sel;
	}

	inline function set_name(n:String):String
	{
		nameText.text = n;
		return name = n;
	}

	inline function set_score(s:String):String
	{
		scoreText.text = s;
		return score = s;
	}

	inline function set_rank(r:Int):Int
	{
		rankText.text = '$r';
		return rank = r;
	}

	inline function set_daWidth(w:Int):Int
	{
		if (w != 0) {
			background.makeGraphic(w, daHeight, FlxColor.YELLOW);
			profilePic.x = Std.int(w * 0.01);
			rankText.x = Std.int(profilePic.x + profilePic.width + (w * 0.02));
			nameText.x = Std.int(w / 2);
			scoreText.fieldWidth = Std.int(w * 0.99);
		}
		return daWidth = w;
	}

	inline function set_daHeight(h:Int):Int
	{
		if (h != 0) {
			if (profilePic.graphic != null) {
				background.makeGraphic(daWidth, h, FlxColor.YELLOW);
				profilePic.setGraphicSize(Std.int(h * 0.9), Std.int(h * 0.9));
				profilePic.updateHitbox();
			}
		}
		return daHeight = h;
	}
}
//endregion