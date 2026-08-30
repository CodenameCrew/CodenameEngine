package funkin.backend.utils;

import lime.graphics.Image;
import haxe.Timer;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import funkin.backend.system.gamejolt.GameJoltData;
import funkin.backend.system.gamejolt.GameJoltSecurity;

#if ALLOW_MULTITHREADING
import funkin.backend.utils.ThreadUtil;
#end
#if (target.threaded)
import sys.thread.Thread;
import sys.thread.Mutex;
#end

/**
 * This is how GameJolt API responses are formatted.
 */
typedef GJResponse = {
	// General
	success:Bool,
	?message:String,
	// User Fetching
	?users:Array<User>,
	// Trophies Fetching
	?trophies:Array<Trophy>,
	// Scores Fetching
	?scores:Array<Score>,
	?tables:Array<ScoreTable>,
	?rank:Int,
	// Friends Fetching
	?friends:Array<{friend_id:Int}>,
	// Data Store Fetching
	?keys:Array<{key:String}>,
	?data:String,
	// Time Fetching
	?timestamp:Int,
	?timezone:String,
	?year:Int,
	?month:Int,
	?day:Int,
	?hour:Int,
	?minute:Int,
	?second:Int,
	// Batch Reception
	?responses:Array<GJResponse>
}

/**
 * The way the scores are fetched from your game API.
 * 
 * @param score The display text of the Score.
 * @param sort The Score value.
 * @param extra_data If some extra data is attached to this Score, it'll be shown here.
 * @param user The username of the User who achieved this Score, if it's a registered User.
 * @param user_id The user ID of the User who achieved this Score, if it's a registered User.
 * @param guest The name of the user who achieved this Score, if it's a guest user.
 * @param stored A short description about when the Score was achieved by the User or Guest.
 * @param stored_timestamp A long time stamp (in seconds) of when the Score was achieved by the User or Guest.
 */
typedef Score = {
	score:String,
	sort:Int,
	extra_data:String,
	user:String,
	user_id:Int,
	guest:String,
	stored:String,
	stored_timestamp:Int
}

/**
 * The way the score tables are fetched from your game API.
 * 
 * @param id The ID of the Score Table.
 * @param name The name of the Score Table.
 * @param description The description of the Score Table.
 * @param primary Whether if this is the Primary Score Table in your game (1) or not (0).
 */
typedef ScoreTable = {
	id:Int,
	name:String,
	description:String,
	primary:Bool
}

/**
 * The way the trophies are fetched from your game API.
 * 
 * @param id The ID of the Trophy.
 * @param title The title of the Trophy.
 * @param description The description of the Trophy.
 * @param difficulty The difficulty rank of the Trophy.
 * @param image_url The link of the image that represents the Trophy.
 * @param achieved Whether this Trophy was achieved or not, it can be a string if it was (with info about how much time ago it was achieved) or bool if not (false).
 */
typedef Trophy = {
	id:Int,
	title:String,
	description:String,
	difficulty:String,
	image_url:String,
	achieved:String
}

/**
 * The way the user data is fetched from the GameJolt API.
 * 
 * @param id The ID of the User.
 * @param type The category the User is cataloged like in GameJolt.
 * @param username The username of the User. (Also available for guests).
 * @param avatar_url The link of the avatar of the User.
 * @param signed_up A short description about how long the User have been in GameJolt.
 * @param signed_up_timestamp A long time stamp (in seconds) of when the User signed up.
 * @param last_logged_in A short description about the last time the User was found active in GameJolt.
 * @param last_logged_in_timestamp A long time stamp (in seconds) of the last time the User logged in GameJolt.
 * @param status The actual status of the User.
 * @param developer_name The display name of the User. (Also available for guests).
 * @param developer_website The website of the User.
 * @param developer_description The description of the User.
 */
typedef User = {
	id:Int,
	type:String,
	username:String,
	avatar_url:String,
	signed_up:String,
	signed_up_timestamp:Int,
	last_logged_in:String,
	last_logged_in_timestamp:Int,
	status:String,
	developer_name:String,
	developer_website:String,
	developer_description:String
}

/**
 * An enum class to clasify Data Store update functions.
 */
enum DataUpdateType {
	Add(n:Int);
	Substract(n:Int);
	Multiply(n:Int);
	Divide(n:Int);
	Append(t:String);
	Prepend(t:String);
}

/**
 * An enum of every single command currently available to request to GameJolt API.
 */
enum RequestType {
	BATCH(parallel:Bool, breakOnError:Bool, requests:Array<RequestType>);
	DATA_FETCH(key:String, fromUser:Bool);
	DATA_GETKEYS(fromUser:Bool, ?pattern:String);
	DATA_REMOVE(key:String, fromUser:Bool);
	DATA_SET(key:String, data:String, toUser:Bool);
	DATA_UPDATE(key:String, operation:DataUpdateType, toUser:Bool);
	FRIENDS;
	TIME;
	USER_AUTH;
	USER_FETCH(userOrID:String);
	SESSION_OPEN;
	SESSION_PING(active:Bool);
	SESSION_CHECK;
	SESSION_CLOSE;
	SCORES_ADD(score:String, sort:Int, ?extra_data:String, ?table_id:Int);
	SCORES_GETRANK(sort:Int, ?table_id:Int);
	SCORES_FETCH(fromUser:Bool, ?table_id:Int, ?limit:Int, ?betterThan:Int);
	SCORES_TABLES;
	TROPHIES_FETCH(?achieved:Bool, ?trophy_id:Int);
	TROPHIES_ADD(trophy_id:Int);
	TROPHIES_REMOVE(trophy_id:Int);
}

/**
 * GameJolt utility to help with GameJolt functionality. Use this class to determine if your player is logged into GameJolt,
 * unlock custom trophies, or do anything that is safe to accomplish with softcoding. Will not do anything if there is no
 * provided GameJolt token or game ID.
 * 
 * # IMPORTANT
 * If you wish to setup GameJolt API integrations, please follow these steps:
 * 1. Place your game's game ID (NOT your game's security key) into your `modpack.ini`
 * for the flag `GAMEJOLT_GAME_ID`.
 * 2. Create a file in `data/config` named `gamejolt.xml`.
 * 3. Create nodes for the following:
 * ```xml
 * <owner username="your-username-here" token="your-user-token-here" />
 * <gamekey>your-game-security-key-here</gamekey>
 * ```
 * 4. Create nodes for trophies and leaderboards.
 * 5. Create nodes for data - any specific items in save files you want to be saved in a user's data store.
 * 6. Run the mod in Codename Engine (preferred: run the EXE file from a Command Prompt).
 * If successful, you will see a screen with more information; if unsuccessful, you'll see
 * an error in the console.
 * 7. If successful, press the "Copy" button and place the copied output into your modpack.ini,
 * preferrably right under the `GAMEJOLT_GAME_ID` flag.
 * 8. Discard the overwritten `gamejolt.xml` file or keep it for any updates you want to make to
 * the global data store.
 * 
 * ## DO NOT PLACE YOUR SECURITY KEY RIGHT INTO THE MODPACK.INI!!!! THAT IS A SECURITY ISSUE!!!!
 */
class GJUtil
{
	/**
	 * Boolean to determine if our player logged in.
	 */
	public static var loggedIn:Bool = false;

	/**
	 * The username of the logged in user.
	 */
	public static var userName(default, set):String;

	/**
	 * The avatar of the logged in user.
	 */
	public static var userAvatarUrl(default, null):String;

	/**
	 * The profile markdown description of the logged in user.
	 */
	public static var userDescription(default, null):String;

	/**
	 * Whether or not the GameJolt utility is operational.
	 * This cannot be set other than load operations.
	 */
	public static var active(default, null):Bool = false;

	/**
	 * Helper function in case the session is lost in the middle of the game.
	 */
	public static var onLostSession:Null<Void->Void> = null;

	/**
	 * Helper function that runs when an achievement is unlocked.
	 * Can be useful for notifications.
	 */
	public static var onTrophyUnlock:Null<Trophy->Void> = null;

	/**
	 * Whether or not the utility is executing a call.
	 */
	static var executing:Bool = false;

	/**
	 * The timer for calling the session ping. Runs every 10 seconds.
	 */
	static var daTimer:Null<Timer> = null;

	#if (target.threaded)
	static final mutex = new Mutex();
	#end

	#if GAMEJOLT_API
	/**
	 * Initializes the GJUtil class and attempts to log in.
	 * If needed, also attempts to initialize global data.
	 */
	public static function init()
	{
		if (Flags.MOD_GAMEJOLT_GAME_ID == '')
			return;

		if (Flags.MOD_GAMEJOLT_ENCRYPTED_TOKEN == '') {
			GameJoltData.loadAdminData();
			if (Flags.MOD_GAMEJOLT_ENCRYPTED_TOKEN == '')
				return;
		} else if (FlxG.save.data.gameJoltArray != null) {
			var gjDat:Array<String> = FlxG.save.data.gameJoltArray;
			GJUtil.attemptLogin(gjDat[0], gjDat[1]);
		}
	}

	/**
	 * Helper function to simplify the login process.
	 * @param name Username of user attempting to login.
	 * @param token User token of user attempting to login.
	 * @param callback Function to run when attempt is complete. Return bool
	 * determines if attempt was successful or unsuccessful.
	 * @param checkCreds Whether or not to check and make sure the user actually
	 * exists. Helpful for new login attempts (instead of confirmed attempts, like
	 * those coming from the save file).
	 * @param tempLogin Whether or not the login is temporary (i.e. first-time global
	 * data upload) or permanent.
	 */
	public static function attemptLogin(name:String, token:String, ?callback:Bool->Void, checkCreds:Bool = false, tempLogin:Bool = false)
	{
		if(Flags.MOD_GAMEJOLT_GAME_ID != '' && Flags.MOD_GAMEJOLT_ENCRYPTED_TOKEN != '') {
			active = true;
			
			userName = name;
			GameJoltSecurity.user_token = token;
			var batchCalls:Array<RequestType> = [SESSION_OPEN, USER_FETCH(name)];
			if (checkCreds)
				batchCalls.unshift(USER_AUTH);
			if (!tempLogin) {
				batchCalls.push(TROPHIES_FETCH());
			}

			send(RequestType.BATCH(true, false, batchCalls), !tempLogin, function(err) {
				userName = null;
				if (callback != null) callback(false);
			}, function(resp) {
				GameJoltSecurity.userId = resp.responses[checkCreds ? 2 : 1].users[0].id;
				if (!tempLogin) {
					userAvatarUrl = resp.responses[checkCreds ? 2 : 1].users[0].avatar_url;
					userDescription = resp.responses[checkCreds ? 2 : 1].users[0].developer_description;
					GameJoltData.loadGlobalData((bl) -> {
						if (bl) {
							for (trop in resp.responses[checkCreds ? 3 : 2].trophies) {
								for (key => value in GameJoltData.definedTrophies) {
									if (value.id == trop.id && trop.achieved != "false")
										GameJoltData.earnedTrophies.set(key, value);
								}
								for (key => value in GameJoltData.customTrophies) {
									if (value.id == trop.id && trop.achieved != "false")
										GameJoltData.earnedTrophies.set(key, value);
								}
							}

							Logs.traceColored([
								Logs.getPrefix("GameJolt"),
								Logs.logText("Successfully logged in user "),
								Logs.logText(userName, GREEN),
								Logs.logText('!')
							], SUCCESS);
							openfl.Lib.application.onExit.add(onExitApp);
							daTimer = new Timer(10000);
							daTimer.run = pingSession;
							if (checkCreds) {
								FlxG.save.data.gameJoltArray = [userName, token];
								FlxG.save.flush();
							}
							GameJoltSecurity.unlockDefinedTrophy('open-first');
							if (Date.now().getDay() == 5 && Date.now().getHours() >= 18)
								GameJoltSecurity.unlockDefinedTrophy('friday-night');
							if (callback != null) callback(true);
						} else {
							Logs.trace('Unable to obtain global data. Logging out of GameJolt.', ERROR, LIGHTGRAY, 'GameJolt');
							logout(false, true); // so that it doesn't remove functions that don't exist
							if (callback != null) callback(false);
						}
					});
				} else if (callback != null)
					callback(true);
			});
		}
		else
			if (callback != null) callback(false);
	}

	/**
	 * Logs out a user from GameJolt.
	 * @param wipeSave Whether or not to wipe the user credentials from
	 * the save file.
	 * @param tempLogin Whether or not the login was temporary (i.e. first-time global
	 * data upload) or permanent.
	 */
	public static function logout(wipeSave:Bool = false, tempLogin:Bool = false)
	{
		if (!active)
			return;
		if (!tempLogin)
			shutdownFunctions();
		send(RequestType.SESSION_CLOSE, !tempLogin, null, function(resp) {
			if (!tempLogin)
				Logs.traceColored([
					Logs.getPrefix("GameJolt"),
					Logs.logText("User "),
					Logs.logText(userName, GREEN),
					Logs.logText(' logged out successfully.')
				], VERBOSE);
			userName = null;
			if (wipeSave) {
				FlxG.save.data.gameJoltArray = null;
				FlxG.save.flush();
			}
		});
	}

	/**
	 * Make a GameJolt API call that is safe to make via softcoding.
	 * @param call The RequestType call to make. Currently only supports:
	 * `FRIENDS`, `TIME`, `USER_FETCH`, `SCORES_GETRANK`, and `TROPHIES_FETCH`.
	 * @param async Whether or not the call should be asyncronous.
	 * @param onError Callback function if an error occurs. Gives error string.
	 * @param onComplete Callback function on successful completion of the call. Gives response data.
	 * @param onProgress Callback function for progress on async calls. Gives a progress float array.
	 */
	public static function makeCall(call:RequestType, async:Bool = false, ?onError:String->Void, ?onComplete:GJResponse->Void, ?onProgress:Array<Float>->Void)
	{
		switch(call) {
			case BATCH(parallel, breakOnError, requests):
				return;

			case DATA_GETKEYS(fromUser, pattern):
				return;

			case DATA_REMOVE(key, fromUser):
				return;

			case DATA_SET(key, data, toUser):
				return;

			case DATA_UPDATE(key, operation, toUser):
				return;

			case USER_AUTH:
				return;

			case SESSION_OPEN:
				return;
			
			case SESSION_PING(active):
				return;

			case SESSION_CHECK:
				return;

			case SESSION_CLOSE:
				return;

			case SCORES_ADD(score, sort, extra_data, table_id):
				return;
			
			case TROPHIES_ADD(trophy_id):
				return;

			case TROPHIES_REMOVE(trophy_id):
				return;

			case _:
				send(call, async, onError, onComplete, onProgress);
		}
	}

	/**
	 * Unlocks a trophy from the `customTrophies` map - in other words,
	 * any trophy that isn't specifically defined in hardcode.
	 * @param custom Key/def of trophy in `customTrophies` map.
	 * @param callback Function running on completion of unlock attempt. Returns
	 * trophy data if successful, `null` if unsuccessful.
	 */
	public static function unlockCustomTrophy(custom:String, ?callback:Null<Trophy>->Void)
	{
		if (!GameJoltData.customTrophies.exists(custom))
			if (callback != null) callback(null)
		else {
			var daTrophy:GJTrophyData = GameJoltData.customTrophies.get(custom);

			if (GameJoltData.earnedTrophies.exists(custom))
				if (callback != null) callback(null)
			else {
				var meetsReqs:Bool = true;
				if (daTrophy.require != null) {
					var reqsMet:Array<Int> = [];
					for (earned in GameJoltData.earnedTrophies)
						if (daTrophy.require.contains(earned.id)) reqsMet.push(earned.id);

					if (reqsMet.length != daTrophy.require.length)
						meetsReqs = false;
				}

				if (!meetsReqs)
					if(callback != null) callback(null)
				else {
					send(TROPHIES_ADD(daTrophy.id), true, function(err) {
						Logs.trace('Trophy unlock error: ${err}', ERROR, LIGHTGRAY, 'GameJolt');
						if (callback != null) callback(null);
					}, function(resp) {
						GameJoltData.earnedTrophies.set(custom, daTrophy);
						Logs.trace('Trophy unlock: ${resp.responses[0].trophies[0].title}!');
						if (onTrophyUnlock != null) onTrophyUnlock(resp.responses[0].trophies[0]);
						if (callback != null) callback(resp.trophies[0]);
					});
				}
			}
		}
	}

	/**
	 * Fetches image of user avatar (using same method as fetching GitHub profile images).
	 * @param image Sprite to apply the bitmap to.
	 * @param link Link to get image from. Defaults to logged in user's link if null.
	 * @param addlCallback Callback function to run on successful completion of attempt.
	 */
	public static function getAvatarImage(image:FlxSprite, ?link:String, ?addlCallback:Void->Void)
	{
		#if ALLOW_MULTITHREADING ThreadUtil.execAsync#elseif (target.threaded) Thread.create#end(function() {
			var key:String = 'GAMEJOLT-LINK:${link != null ? link : userName}';
			var bmap:Dynamic = FlxG.bitmap.get(key);

			if(bmap == null) {
				Logs.trace('Downloading avatar: ${link != null ? link : userName}', INFO, LIGHTGRAY, 'GameJolt');
				var unfLink:Bool = StringTools.endsWith(link != null ? link : userAvatarUrl, '.png');

				var bytes = null;
				if(unfLink) {
					try bytes = HttpUtil.requestBytes(link != null ? link : userAvatarUrl)
					catch(e) Logs.error('Failed to download GameJolt pfp for ${link != null ? link : userName}: ${e.message} - (Retrying using the api..)', RED, 'GameJolt');

					if(bytes != null) {
						bmap = BitmapData.fromBytes(bytes);
					}
				}

				var leGraphic:FlxGraphic = null;
				if(bmap != null) try {
					#if (target.threaded)
					mutex.acquire();
					#end
					leGraphic = FlxG.bitmap.add(bmap, false, key);
					leGraphic.persist = true;
					bmap = null;
					image.loadGraphic(leGraphic);
					if (addlCallback != null) addlCallback();
					#if (target.threaded)
					mutex.release();
					#end
				} catch(e) {
					Logs.error('Failed to update the pfp for ${userName}: ${e.message}', RED, 'GameJolt');
				}
			} else {
				image.loadGraphic(bmap);
				if (addlCallback != null) addlCallback();
			}
		});
	}

	/**
	 * Fetches image of a trophy (using same method as fetching GitHub profile images).
	 * If null, it will set the graphic to one of the default graphics stored in the
	 * Assets file.
	 * 
	 * You can also create your own default trophy images by just making "bronze",
	 * "silver", "gold", and "platnum" trophy images, then placing those in 
	 * "images/menus/gamejolt".
	 * @param image Sprite to apply the bitmap to.
	 * @param link Link to get image from. Defaults to logged in user's link if null.
	 * @param addlCallback Callback function to run on successful completion of attempt.
	 */
	public static function getTrophyImage(image:FlxSprite, trophy:Trophy, ?addlCallback:Void->Void)
	{
		#if ALLOW_MULTITHREADING ThreadUtil.execAsync#elseif (target.threaded) Thread.create#end(function() {
			var key:String = 'GAMEJOLT-TROP:${trophy.image_url}';
			var bmap:Dynamic = FlxG.bitmap.get(key);

			if(bmap == null) {
				Logs.trace('Downloading trophy image for trophy: ${trophy.title}', INFO, LIGHTGRAY, 'GameJolt');
				var unfLink:Bool = StringTools.endsWith(trophy.image_url, '.png');

				if(unfLink) {
					Image.loadFromFile(trophy.image_url).onComplete((img:Image) -> {
						try {
							#if (target.threaded)
							mutex.acquire();
							#end
							var leGraphic:FlxGraphic = FlxG.bitmap.add(BitmapData.fromImage(img), false, key);
							leGraphic.persist = true;
							image.loadGraphic(leGraphic);
							if (addlCallback != null) addlCallback();
							#if (target.threaded)
							mutex.release();
							#end
						} catch(e) {
							Logs.error('Failed to update the image for ${trophy.title}: ${e.message}', RED, 'GameJolt');
						}
					}).onError((e) -> {
						Logs.error('Failed to download trophy image for ${trophy.title}: ${e.message} - (Obtaining default image from files instead...)', RED, 'GameJolt');
						try {
							#if (target.threaded)
							mutex.acquire();
							#end
							var secret:Bool = false;
							for (t in GameJoltData.definedTrophies) {
								if (t.id == trophy.id && t.hidden != null && !t.hidden)
									secret = true;
							}

							for (t in GameJoltData.customTrophies) {
								if (t.id == trophy.id && t.hidden != null && !t.hidden)
									secret = true;
							}
							var leGraphic:FlxGraphic = FlxG.bitmap.add(BitmapData.fromFile(Paths.image('menus/gamejolt/' + trophy.difficulty.toLowerCase() + (secret ? "-secret" : ""))), false, key);
							leGraphic.persist = true;
							image.loadGraphic(leGraphic);
							if (addlCallback != null) addlCallback();
							#if (target.threaded)
							mutex.release();
							#end
						} catch(e) {
							Logs.error('Failed to update the image for ${trophy.title}: ${e.message}', RED, 'GameJolt');
						}
					});
				} else {
					Logs.error('Image for ${trophy.title} is not a .png image; obtaining default image from files instead...', RED, 'GameJolt');
					try {
						#if (target.threaded)
						mutex.acquire();
						#end
						var leGraphic:FlxGraphic = FlxG.bitmap.add(BitmapData.fromFile(Paths.image('menus/gamejolt/' + trophy.difficulty.toLowerCase())), false, key);
						leGraphic.persist = true;
						image.loadGraphic(leGraphic);
						if (addlCallback != null) addlCallback();
						#if (target.threaded)
						mutex.release();
						#end
					} catch(e) {
						Logs.error('Failed to update the image for ${trophy.title}: ${e.message}', RED, 'GameJolt');
					}
				}
			} else {
				image.loadGraphic(bmap);
				if (addlCallback != null) addlCallback();
			}
		});
	}

	/**
	 * Function to ping session on regular basis.
	 */
	static function pingSession()
	{
		send(SESSION_PING(true), true, (str) -> {
			if (onLostSession != null) onLostSession();
			shutdownFunctions();
			Logs.trace('Session lost ($str); GJUtil shut down successfully.', WARNING, LIGHTGRAY, 'GameJolt');
			active = false;
		});
	}

	/**
	 * Function to log out of GameJolt on application exit.
	 * @param i idk man.
	 */
	static function onExitApp(i:Int)
	{
		logout();
	}

	/**
	 * Functions to run when safely logging out user from GameJolt.
	 */
	static function shutdownFunctions()
	{
		Logs.traceColored([
			Logs.getPrefix("GameJolt"),
			Logs.logText("Logging out user "),
			Logs.logText(userName, GREEN),
			Logs.logText('...')
		], INFO);
		daTimer.stop();
		daTimer = null;
		openfl.Lib.application.onExit.remove(onExitApp);
		onLostSession = null;
		GameJoltData.reset();
	}

	/**
	 * Main send function for calls and requests using GameJolt API.
	 * @param call Type of request to send.
	 * @param async Whether or not the request is asynchronous.
	 * @param onError Function to run on error. Returns error message as string.
	 * @param onComplete Function to run on success. Returns response data as typedef `Response`.
	 * @param onProgress Function to run on async progress. Returns array of floats.
	 */
	@:noPrivateAccess static function send(call:RequestType, async:Bool = false, ?onError:String->Void, ?onComplete:GJResponse->Void, ?onProgress:Array<Float>->Void)
	{
		if (executing || !active)
			return;
		executing = true;

		@:privateAccess
		GameJoltSecurity.handleRequest(async, call, function(errmsg) {
			executing = false;
			if (onError != null) onError(errmsg);
		}, function(resp) {
			executing = false;
			if (onComplete != null) onComplete(formatImages(resp));
		}, onProgress);
	}

	/**
	 * Formats any images received to proper file types
	 * @param res Response to format.
	 * @return GJResponse Response with formatted images.
	 */
	static function formatImages(res:GJResponse):GJResponse {
		if (res.users != null) {
			for (u in res.users) {
				u.avatar_url = '${u.avatar_url.substring(0, 32)}1000${u.avatar_url.substr(34)}'.replace(".jpg", ".png").replace(".webp", ".png");
			}
		}
		if (res.trophies != null && res.trophies[0] != null) {
			for (t in res.trophies) {
				var newUrl:String = "";
				if (t.image_url.startsWith('https://m.'))
					newUrl = '${t.image_url.substring(0, 37)}1000${t.image_url.substr(40)}'.replace(".jpg", ".png").replace(".webp", ".png");
				else {
					newUrl = 'https://s.gjcdn.net/assets/${t.image_url.substr(24)}';
				}
				t.image_url = newUrl;
			};
		}
		if (res.responses != null) for (res2 in res.responses) res2 = formatImages(res2);
		return res;
	}

	static function set_userName(name:String):String
	{
		loggedIn = (name != null && name != '');
		if (name == null) {
			userAvatarUrl = null;
			userDescription = null;
			GameJoltSecurity.userId = null;
			GameJoltSecurity.user_token = null;

		}
		return userName = name;
	}
	#else
	public static function init()
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
	}

	public static function attemptLogin(name:String, token:String, ?callback:Bool->Void, checkCreds:Bool = false, tempLogin:Bool = false)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		if (callback != null) callback(false);
	}

	public static function logout(wipeSave:Bool = false, tempLogin:Bool = false)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
	}

	public static function makeCall(call:RequestType, async:Bool = false, ?onError:String->Void, ?onComplete:GJResponse->Void, ?onProgress:Array<Float>->Void)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
	}

	public static function unlockCustomTrophy(custom:String, ?callback:Null<Trophy>->Void)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		if (callback != null) callback(null);
	}

	public static function getAvatarImage(image:FlxSprite, ?addlCallback:Void->Void)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
	}

	static function set_userName(name:String):String
	{
		return userName = name;
	}
	#end
}