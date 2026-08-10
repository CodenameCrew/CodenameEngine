package funkin.backend.utils;

/**
 * This is how GameJolt API responses are formatted like.
 */
typedef Response = {
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
	?responses:Array<Response>
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
 * @param type The cathegory the User is cataloged like in GameJolt.
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
 * GameJolt utility to help with GameJolt functionality. Use this class to determine if your player is logged into GameJolt.
 * Will not do anything if there is no provided GameJolt token.
 * 
 * # IMPORTANT
 * If you wish to use this utility, please run your GameJolt game's security code through the Codename Engine
 * encryption tool on Codename's website.
 * Place the output of that into your modpack.ini under the flag `MOD_GAMEJOLT_TOKEN`.
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
	 * Whether or not the GameJolt utility is operational.
	 * This cannot be set other than load operations.
	 */
	public static var active(default, null):Bool = false;

	/**
	 * Whether or not the utility is executing a call.
	 */
	static var executing:Bool = false;

	/**
	 * Helper function in case the session is lost in the middle of the game.
	 */
	public static var onLostSession:Null<Void->Void> = null;

	/**
	 * Helper function to simplify the login process.
	 * @param name Username of user attempting to login.
	 * @param token User token of user attempting to login.
	 * @return Bool Whether the attempt was successfull or not.
	 */
	public static function attemptLogin(name:String, token:String):Bool
	{
		if(Flags.MOD_GAMEJOLT_GAME_ID != '' && Flags.MOD_GAMEJOLT_TOKEN != '')
			active = true
		else
			return false;

		var ret:Bool = false;
		userName = name;
		GameJoltSecurity.user_token = token;
		send(RequestType.SESSION_OPEN, false, function(err) {
			userName = null;
			GameJoltSecurity.user_token = null;
		}, function(resp) {
			trace('GameJolt logged in as ${userName}');
			ret = true;
			openfl.Lib.application.onExit.add(onExitApp);
			FlxG.signals.postUpdate.add(pingTimer);
		});
		return ret;
	}

	static function onExitApp(i:Int)
	{
		logout();
	}

	static var pingTime:Int = 0;
	public static function pingTimer()
	{
		pingTime += 1;
		if (pingTime < 10000) return;
		pingTime -= 10000;
		pingSession();
	}

	public static function pingSession()
	{
		send(RequestType.SESSION_PING(true), true, (str) -> {
			trace('GameJolt session lost.');
			if (onLostSession != null) onLostSession();
			shutdownFunctions();
			active = false;
		});
	}

	public static function logout()
	{
		if (!active)
			return;
		
		shutdownFunctions();
		send(RequestType.SESSION_CLOSE, false, null, function(resp) {
			trace('GameJolt account ${userName} logged out successfully.');
			userName = null;
			GameJoltSecurity.user_token = null;
		});
	}

	static function shutdownFunctions()
	{
		FlxG.signals.postUpdate.remove(pingTimer);
		openfl.Lib.application.onExit.remove(onExitApp);
		onLostSession = null;
	}

	public static function send(call:RequestType, async:Bool = false, ?onError:String->Void, ?onComplete:Response->Void, ?onProgress:Array<Float>->Void)
	{
		if (executing || !active)
			return;
		executing = true;

		@:privateAccess
		var resp:Response = GameJoltSecurity.handleRequest(async, call, onProgress);
		executing = false;
		if (resp.message != null && onError != null)
			onError(resp.message);
		else if (resp.message == null && onComplete != null)
			onComplete(formatImages(resp));
	}

	static function formatImages(res:Response):Response {
		if (res.users != null)
			for (u in res.users) u.avatar_url = '${u.avatar_url.substring(0, 32)}1000${u.avatar_url.substr(34)}'.replace(".jpg", ".png")
				.replace(".webp", ".png");
		if (res.trophies != null) for (t in res.trophies) {
				var newUrl:String = "";
				if (t.image_url.startsWith('https://m.'))
					newUrl = '${t.image_url.substring(0, 37)}1000${t.image_url.substr(40)}'.replace(".jpg", ".png").replace(".webp", ".png");
				else {
					newUrl = "https://s.gjcdn.net/assets/";
					newUrl += switch (t.image_url.substring(24).replace(".jpg", "").replace(".webp", "")) {
						case "trophy-bronze-1": "9c2c91d0";
						case "trophy-silver-1": "b46e352e";
						case "trophy-gold-1": "363ce2dc";
						case "trophy-platinum-1": "92e5330d";
						default: "";
					};
					newUrl += ".png";
				}
				t.image_url = newUrl;
			};
		if (res.responses != null) for (res2 in res.responses) res2 = formatImages(res2);
		return res;
	}

	static function set_userName(name:String):String
	{
		loggedIn = (name != null && name != '');
		return userName = name;
	}
}