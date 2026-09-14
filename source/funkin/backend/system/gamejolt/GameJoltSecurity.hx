package funkin.backend.system.gamejolt;

import hscript.IHScriptCustomAccessBehaviour;
import funkin.backend.utils.GJUtil;
import funkin.backend.utils.GJUtil.RequestType;
import funkin.backend.system.gamejolt.GameJoltData;
import haxe.crypto.*;
import haxe.crypto.mode.Mode;
import haxe.crypto.padding.Padding;
import haxe.io.Bytes;
import funkin.backend.utils.GJUtil.*;
import haxe.Http;
import haxe.Json;
import openfl.events.*;
#if ALLOW_MULTITHREADING
import funkin.backend.utils.ThreadUtil;
#end
#if (target.threaded)
import sys.thread.Thread;
#end



/**
 * # A BIG MOTHERFUCKING WARNING
 * 
 * This class handles the raw game keys for GameJolt keys.
 * If the raw game keys are made public, people can mess with leaderboards, data, achievements,
 * or whatever else is on the game page.
 * 
 * As such, Codename Engine requires players to encrypt keys using the AES protocol, and
 * the key to decrypt such keys is non-disclosable (hence why it's in a .env file).
 * 
 * Also for security purposes, this class is unattainable via HScript.
 * 
 * ~ SplatterDash
 */

@:noCustomClass @:build(funkin.backend.system.macros.SecretMacro.build())
class GameJoltSecurity implements IHScriptCustomAccessBehaviour
{
	/**
	 * Token for the user if they're logged in.
	 */
	public static var user_token:String = '';

	/**
	 * ID number for the current mod.
	 */
	public static var gameId:String = '';

	/**
	 * ID number for the currently logged in user.
	 */
	public static var userId:Null<Int> = null;
	/**
	 * The encrypted game token. Set using GAMEJOLT_ENCRYPTED_TOKEN in ini file.
	 */
	public static var encryptedGameToken(default, set):String;

	/**
	 * The unencrypted game token. It's insanely hard to get this variable.
	 */
	@:noPrivateAccess private static var revealedGameToken:String;

	/**
	 * URL sent to GameJolt per request.
	 */
	@:noPrivateAccess private static var url(get, never):String;

	/**
	 * The previous GJResponse created by the API client. Usually for just storage purposes.
	 */
	private static var lastResponse:GJResponse = {success: false, message: "No response yet."};

	/**
	 * The current call being processed.
	 */
	private static var curCall:Null<RequestType> = null;

	/**
	 * The secret key to decrypt GameJolt keys using AES. This cannot be traced or located in any way.
	 */
	@:envField
	private static final CODENAME_AES_KEY:Null<String>;

	#if target.threaded
	static final mutex = new sys.thread.Mutex();
	#end

	// hscript - thanks LJ :D

	//region IHScriptCustomAccessBehaviour implementation
	public var __allowSetGet:Bool = false;

	public function hget(name:String):Dynamic
		return null;

	public function hset(name:String, val:Dynamic):Dynamic
		return null;

	public function __callGetter(name:String):Dynamic
		return null;

	public function __callSetter(name:String, val:Dynamic):Dynamic
		return null;
	//endregion

	#if GAMEJOLT_API
	/**
	 * This is a copy of GJUtil's "send" request, but kept here since Hscript can't get here.
	 * Any calls here are guaranteed to be from hardcoding.
	 * @param call The RequestType call to make. Can make any type of call.
	 * @param async Whether or not the call should be asyncronous.
	 * @param onError Callback function if an error occurs. Gives error string.
	 * @param onComplete Callback function on successful completion of the call. Gives response data.
	 * @param onProgress Callback function for progress on async calls. Gives a progress float array.
	 */
	public static function sendTrusted(call:RequestType, async:Bool = false, ?onError:String->Void, ?onComplete:GJResponse->Void, ?onProgress:Array<Float>->Void)
	{
		@:privateAccess {
			if (GJUtil.executing || !GJUtil.active)
				return;
			GJUtil.executing = true;
		}

		handleRequest(async, call, function(errstr) {
			@:privateAccess
			GJUtil.executing = false;
			if (onError != null) onError(errstr);
		}, function(resp) {
			@:privateAccess {
				GJUtil.executing = false;
				if (onComplete != null) onComplete(GJUtil.formatImages(resp));
			}
		}, onProgress);
	}

	/**
	 * Unlocks a trophy from the `definedTrophies` map - in other words,
	 * any trophy that is specifically defined in hardcode.
	 * @param def Key/def of trophy in `definedTrophies` map.
	 * @param callback Function running on completion of unlock attempt. Returns
	 * trophy data if successful, `null` if unsuccessful.
	 */
	public static function unlockDefinedTrophy(def:String, ?callback:Null<Trophy>->Void)
	{
		if (GameJoltData.definedTrophies == null || !GameJoltData.definedTrophies.exists(def)) {
			Logs.error('No defined trophy exists with the key "$def".', RED, 'GameJolt');
			if (callback != null) callback(null);
		} else {
			var daTrophy:GJTrophyData = GameJoltData.definedTrophies.get(def);

			if (GameJoltData.earnedTrophies.exists(def)) {
				Logs.error('User already earned trophy with key "$def"!', RED, 'GameJolt');
				if (callback != null) callback(null);
			} else {
				var meetsReqs:Bool = true;
				if (daTrophy.require != null) {
					var reqsMet:Array<Int> = [];
					for (earned in GameJoltData.earnedTrophies) {
						if (daTrophy.require.contains(earned.id)) reqsMet.push(earned.id);
					}

					if (reqsMet.length != daTrophy.require.length)
						meetsReqs = false;
				}

				if (!meetsReqs) {
					Logs.error('User does not meet requirements for trophy with the key "$def".', RED, 'GameJolt');
					if(callback != null) callback(null);
				} else {
					sendTrusted(BATCH(false, true, [TROPHIES_FETCH(false, daTrophy.id), TROPHIES_ADD(daTrophy.id)]), true, function(err) {
						Logs.trace('Trophy unlock error: ${err}', ERROR, LIGHTGRAY, 'GameJolt');
						if (callback != null) callback(null);
					}, function(resp) {
						GameJoltData.earnedTrophies.set(def, daTrophy);
						if(resp.responses[0].trophies[0] == null) {
							Logs.trace('Trophy with key $def already unlocked!', WARNING, LIGHTGRAY, 'GameJolt');
							if (callback != null) callback(null);
						} else {
							Logs.trace('Trophy unlock: ${resp.responses[0].trophies[0].title}!', SUCCESS, LIGHTGRAY, 'GameJolt');
							if (GJUtil.onTrophyUnlock != null) GJUtil.onTrophyUnlock(resp.responses[0].trophies[0]);
							if (callback != null) callback(resp.responses[0].trophies[0]);
						}
					});
				}
			}
		}
	}

	/**
	 * Handled the main request without giving out any compromisable data.
	 * @param async Whether or not the call should be asyncronous.
	 * @param data The RequestType call to make. Can make any type of call.
	 * @param onError Callback function if an error occurs. Gives error string.
	 * @param onComplete Callback function on successful completion of the call. Gives response data.
	 * @param onProgress Callback function for progress on async calls. Gives a progress float array.
	 */
	static function handleRequest(async:Bool = false, data:RequestType, ?onError:String->Void, ?onComplete:GJResponse->Void, ?onProgress:Array<Float>->Void)
	{
		if (encryptedGameToken == null || gameId == null) {
			lastResponse = {success: false, message: 'Missing game token and/or game ID.'};
			curCall = null;
			if (onError != null) onError(lastResponse.message);
		}

		curCall = data;
		
		if (async) {
			#if ALLOW_MULTITHREADING ThreadUtil.execAsync#elseif (target.threaded) Thread.create#end (() -> {
				var loader = new openfl.net.URLLoader();
				loader.addEventListener(Event.COMPLETE, function(complete) {
					lastResponse = Json.parse(cast(loader.data, String)).response;
					if (lastResponse.message != null) {
						Logs.traceColored([
							Logs.getPrefix("GameJolt"),
							Logs.logText('Response Error: ${lastResponse.message}')
						], ERROR);
						curCall = null;
						if (onError != null) onError(lastResponse.message);
					} else {
						curCall = null;
						if (onComplete != null) onComplete(lastResponse);
					}
				});
				loader.addEventListener(ProgressEvent.PROGRESS, progress -> { if (onProgress != null) onProgress([progress.bytesLoaded, progress.bytesTotal]);});
				loader.addEventListener(IOErrorEvent.IO_ERROR, function(ioError) {
					lastResponse = {success: false, message: 'IO Error: ${ioError.text}'};
					curCall = null;
					if (onError != null) onError(lastResponse.message);
				});
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, (securityError) -> {
					lastResponse = {success: false, message: 'Security Error: ${securityError.text}'};
					curCall = null;
					if (onError != null) onError(lastResponse.message);
				});
				loader.load(new openfl.net.URLRequest(url));
			});
		} else {
			var loader:Http = new Http(url);
			loader.onData = function(data) {
				lastResponse = cast Json.parse(data).response;
				if (lastResponse.message != null) {
					Logs.traceColored([
						Logs.getPrefix("GameJolt"),
						Logs.logText('Response Error: ${lastResponse.message}')
					], ERROR);
					curCall = null;
					if (onError != null) onError(lastResponse.message);
				} else {
					curCall = null;
					if (onComplete != null) onComplete(lastResponse);
				}
			};
			loader.onError = function(error) {
				lastResponse = {success: false, message: 'Request Error: ${error}'};
				curCall = null;
				if (onError != null) onError(lastResponse.message);
			};
			loader.request(false);
		}
	}

	/**
	 * Parses data from a request to be sent via OpenFL or HTTP request.
	 * @param request RequestType to be formatted.
	 * @param signed Whether or not the request should be "signed" using the game token.
	 * @return String Request link.
	 */
	static function parseType(request:RequestType, signed:Bool = false):String {
		var command:String = "";
		var action:String = "";
		var params:Array<{name:String, value:String}> = [];

		switch (request) {
			case BATCH(parallel, breakOnError, requests):
				command = "batch";
				params.push({name: "parallel", value: '$parallel'});
				params.push({name: "break_on_error", value: '$breakOnError'});
				for (req in requests) params.push({name: "requests[]", value: parseType(req, true)});
			case DATA_FETCH(key, fromUser):
				command = "data-store";
				params.push({name: "key", value: key.urlEncode()});
				if (fromUser) {
					params.push({name: "username", value: GJUtil.userName});
					params.push({name: "user_token", value: user_token});
				}
			case DATA_GETKEYS(fromUser, pattern):
				command = "data-store";
				action = "get-keys";
				if (pattern != null && pattern != "")
					params.push({name: "pattern", value: pattern.urlEncode()});
				if (fromUser) {
					params.push({name: "username", value: GJUtil.userName});
					params.push({name: "user_token", value: user_token});
				}
			case DATA_REMOVE(key, fromUser):
				command = "data-store";
				action = "remove";
				params.push({name: "key", value: key.urlEncode()});
				if (fromUser) {
					params.push({name: "username", value: GJUtil.userName});
					params.push({name: "user_token", value: user_token});
				}
			case DATA_SET(key, data, toUser):
				command = "data-store";
				action = "set";
				params.push({name: "key", value: key.urlEncode()});
				params.push({name: "data", value: data.urlEncode()});
				if (toUser) {
					params.push({name: "username", value: GJUtil.userName});
					params.push({name: "user_token", value: user_token});
				}
			case DATA_UPDATE(key, operation, toUser):
				command = "data-store";
				action = "update";
				params.push({name: "key", value: key.urlEncode()});
				if (toUser) {
					params.push({name: "username", value: GJUtil.userName});
					params.push({name: "user_token", value: user_token});
				}
				switch (operation) {
					case Add(n):
						params.push({name: 'operation', value: 'add'});
						params.push({name: 'value', value: '$n'});
					case Substract(n):
						params.push({name: 'operation', value: 'substract'});
						params.push({name: 'value', value: '$n'});
					case Multiply(n):
						params.push({name: 'operation', value: 'multiply'});
						params.push({name: 'value', value: '$n'});
					case Divide(n):
						params.push({name: 'operation', value: 'divide'});
						params.push({name: 'value', value: '$n'});
					case Append(t):
						params.push({name: 'operation', value: 'append'});
						params.push({name: 'value', value: t.urlEncode()});
					case Prepend(t):
						params.push({name: 'operation', value: 'prepend'});
						params.push({name: 'value', value: t.urlEncode()});
				}
			case FRIENDS:
				command = "friends";
				params.push({name: "username", value: GJUtil.userName});
				params.push({name: "user_token", value: user_token});
			case TIME:
				command = "time";
			case USER_AUTH:
				command = "users";
				action = "auth";
				params.push({name: "username", value: GJUtil.userName});
				params.push({name: "user_token", value: user_token});
			case USER_FETCH(userOrID):
				command = "users";
				var letters:Array<String> = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ_-".split("");
				if (letters.filter(l -> userOrID.contains(l.toUpperCase()) || userOrID.contains(l.toLowerCase())).length > 0)
					params.push({name: "username", value: userOrID});
				else
					params.push({name: "user_id", value: userOrID.replace(",", "%2C")});
			case SESSION_OPEN:
				command = "sessions";
				action = "open";
				params.push({name: "username", value: GJUtil.userName});
				params.push({name: "user_token", value: user_token});
			case SESSION_PING(active):
				command = "sessions";
				action = "ping";
				params.push({name: "status", value: active ? "active" : "idle"});
				params.push({name: "username", value: GJUtil.userName});
				params.push({name: "user_token", value: user_token});
			case SESSION_CHECK:
				command = "sessions";
				action = "check";
				params.push({name: "username", value: GJUtil.userName});
				params.push({name: "user_token", value: user_token});
			case SESSION_CLOSE:
				command = "sessions";
				action = "close";
				params.push({name: "username", value: GJUtil.userName});
				params.push({name: "user_token", value: user_token});
			case SCORES_ADD(score, sort, extra_data, table_id):
				command = "scores";
				action = "add";
				params.push({name: "score", value: score});
				params.push({name: "sort", value: '$sort'});
				if (extra_data != null && extra_data != "")
					params.push({name: "extra_data", value: extra_data.urlEncode()});
				if (table_id != null)
					params.push({name: "table_id", value: '$table_id'});
				if (user_token != "") {
					params.push({name: "username", value: GJUtil.userName});
					params.push({name: "user_token", value: user_token});
				} else
					params.push({name: "guest", value: GJUtil.userName});
			case SCORES_GETRANK(sort, table_id):
				command = "scores";
				action = "get-rank";
				params.push({name: "sort", value: '$sort'});
				if (table_id != null)
					params.push({name: "table_id", value: '$table_id'});
			case SCORES_FETCH(fromUser, table_id, limit, betterThan):
				command = "scores";
				if (table_id != null)
					params.push({name: "table_id", value: '$table_id'});
				if (limit != null)
					params.push({name: "limit", value: '$limit'});
				if (betterThan != null)
					params.push({name: betterThan < 0 ? "worse_than" : "better_than", value: '${Math.abs(betterThan)}'});
				if (fromUser) {
					if (user_token != "") {
						params.push({name: "username", value: GJUtil.userName});
						params.push({name: "user_token", value: user_token});
					} else
						params.push({name: "guest", value: GJUtil.userName});
				}
			case SCORES_TABLES:
				command = "scores";
				action = "tables";
			case TROPHIES_FETCH(achieved, trophy_id):
				command = "trophies";
				if (achieved != null)
					params.push({name: "achieved", value: '$achieved'});
				if (trophy_id != null)
					params.push({name: "trophy_id", value: '$trophy_id'});
				params.push({name: "username", value: GJUtil.userName});
				params.push({name: "user_token", value: user_token});
			case TROPHIES_ADD(trophy_id):
				command = "trophies";
				action = "add-achieved";
				params.push({name: "trophy_id", value: '$trophy_id'});
				params.push({name: "username", value: GJUtil.userName});
				params.push({name: "user_token", value: user_token});
			case TROPHIES_REMOVE(trophy_id):
				command = "trophies";
				action = "remove-achieved";
				params.push({name: "trophy_id", value: '$trophy_id'});
				params.push({name: "username", value: GJUtil.userName});
				params.push({name: "user_token", value: user_token});
		}

		var urlSection:String = '/$command${action != "" ? '/$action' : ""}?game_id=${gameId}${[for (p in params) '&${p.name}=${p.value}'].join("")}';
		if (signed)
			urlSection = sign(urlSection).urlEncode();
		return urlSection;
	}

	/**
	 * Signs a piece of URL with Md5.
	 * @param daUrl The old URL piece.
	 * @return The new URL piece.
	 */
	static function sign(daUrl:String):String {
		var urlToEncode:String = daUrl + revealedGameToken;
		return '$daUrl&signature=${Md5.encode(urlToEncode)}';
	}

	/**
	 * Setter function for encrypted game token. Also sets revealed game token.
	 * @param tok New string to set for `encryptedGameToken`.
	 */
	static function set_encryptedGameToken(tok:String)
	{
		if (tok != null && CODENAME_AES_KEY != null) {
			var iv:String = tok.substr(0, 32);
			var theK:String = tok.substr(32);

			var aes:Aes = new Aes(Bytes.ofHex(CODENAME_AES_KEY), Bytes.ofHex(iv.toUpperCase()));

			var dat:String = aes.decrypt(Mode.OFB, Bytes.ofHex(theK), Padding.NoPadding).toString();

			revealedGameToken = dat;
		} else {
			revealedGameToken = null;
		}
		return encryptedGameToken = tok;
	}

	static function get_url():String
	{
		return sign('https://api.gamejolt.com/api/game/v1_2${parseType(curCall)}');
	}
	#else
	//region No API Integrations
	public static function sendTrusted(call:RequestType, async:Bool = false, ?onError:String->Void, ?onComplete:GJResponse->Void, ?onProgress:Array<Float>->Void)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		if (onError != null) onError('GameJolt API not set in Project.xml!');
	}

	public static function unlockDefinedTrophy(def:String, ?callback:Null<Trophy>->Void)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		if (callback != null) callback(null);
	}

	static function set_encryptedGameToken(tok:String)
	{
		return encryptedGameToken = tok;
	}

	static function get_url():String
	{
		return null;
	}
	//endregion
	#end
}