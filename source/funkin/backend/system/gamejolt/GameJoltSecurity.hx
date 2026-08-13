package funkin.backend.system.gamejolt;

import hscript.IHScriptCustomAccessBehaviour;
import funkin.backend.utils.GJUtil;
import funkin.backend.utils.GJUtil.RequestType;
import haxe.crypto.*;
import haxe.crypto.mode.Mode;
import haxe.crypto.padding.Padding;
import haxe.io.Bytes;
import funkin.backend.utils.GJUtil.*;
import haxe.Http;
import haxe.Json;
import openfl.events.*;

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
	 * Map of all trophies defined using specific names.
	 * Specifically stored here so that it's harder to cheese song,
	 * FC or other specific trophies.
	 */
	public static var definedTrophies(default, null):Map<String, Int> = [];

	/**
	 * 
	 */
	public static var definedLeaderboards(default, null):Map<String, Int> = [];
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
	 * The previous response created by the API client. Usually for just storage purposes.
	 */
	private static var lastResponse:Response = {success: false, message: "No response yet."};

	/**
	 * The current call being processed.
	 */
	private static var curCall:Null<RequestType> = null;

	/**
	 * The secret key to decrypt GameJolt keys using AES. This cannot be traced or located in any way.
	 */
	@:envField
	private static final CODENAME_AES_KEY:Null<String>;

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

	static function get_url():String
	{
		return sign('https://api.gamejolt.com/api/game/v1_2${parseType(curCall)}');
	}

	/**
	 * This is a copy of GJUtil's "send" request, but kept here since Hscript can't get here.
	 * Any calls here are guaranteed to be from hardcoding.
	 * @param call 
	 * @param async 
	 * @param onError 
	 * @param onComplete 
	 * @param onProgress 
	 */
	public static function sendTrusted(call:RequestType, async:Bool = false, ?onError:String->Void, ?onComplete:Response->Void, ?onProgress:Array<Float>->Void)
	{
		@:privateAccess {
			if (GJUtil.executing || !GJUtil.active)
				return;
			GJUtil.executing = true;
		}

		var resp:Response = handleRequest(async, call, onProgress);
		@:privateAccess
		GJUtil.executing = false;
		if (resp.message != null && onError != null)
			onError(resp.message);
		else if (resp.message == null && onComplete != null) {
			@:privateAccess
			onComplete(GJUtil.formatImages(resp));
		}
	}

	static function handleRequest(async:Bool = false, data:RequestType, ?onProgress:Array<Float>->Void):Response
	{
		if (encryptedGameToken == null || gameId == null) {
			lastResponse = {success: false, message: 'Missing game token and/or game ID.'};
			curCall = null;
			return lastResponse;
		}

		curCall = data;
		
		if (async) {
			var loader = new openfl.net.URLLoader();
			loader.addEventListener(Event.COMPLETE, function(complete) {
				lastResponse = Json.parse(cast(loader.data, String)).response;
				if (lastResponse.message != null) {
					Logs.traceColored([
						Logs.getPrefix("GameJolt"),
						Logs.logText('Response Error: ${lastResponse.message}')
					], ERROR);
				}
				
			});
			loader.addEventListener(ProgressEvent.PROGRESS, progress -> { if (onProgress != null) onProgress([progress.bytesLoaded, progress.bytesTotal]);});
			loader.addEventListener(IOErrorEvent.IO_ERROR, function(ioError) {
				lastResponse = {success: false, message: 'IO Error: ${ioError.text}'};
			});
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, (securityError) -> {
				lastResponse = {success: false, message: 'Security Error: ${securityError.text}'};
			});
			loader.load(new openfl.net.URLRequest(url));
			return {success: false, message: "No response yet."};
		} else {
			var loader:Http = new Http(url);
			loader.onData = function(data) {
				lastResponse = Json.parse(data).response;
				if (lastResponse.message != null)
					Logs.traceColored([
						Logs.getPrefix("GameJolt"),
						Logs.logText('Response Error: ${lastResponse.message}')
					], ERROR);
			};
			loader.onError = function(error) {
				lastResponse = {success: false, message: 'Request Error: ${error}'};
			};
			loader.request(false);
		}
		curCall = null;
		return lastResponse;
	}

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
	 * Setter function for encrypted game token. Also sets revealed game token.
	 * @param tok 
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

	/**
	 * Signs a piece of URL with Md5.
	 * @param daUrl The old URL piece.
	 * @return The new URL piece.
	 */
	static function sign(daUrl:String):String {
		var urlToEncode:String = daUrl + revealedGameToken;
		return '$daUrl&signature=${Md5.encode(urlToEncode)}';
	}
}