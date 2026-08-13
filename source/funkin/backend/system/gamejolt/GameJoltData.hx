package funkin.backend.system.gamejolt;

import haxe.xml.Access;
import haxe.io.Bytes;
import haxe.crypto.Aes;
import haxe.crypto.mode.Mode;
import haxe.crypto.padding.Padding;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import flixel.input.keyboard.FlxKey;
import funkin.backend.utils.GJUtil;
import funkin.backend.utils.GJUtil.ScoreTable;
import funkin.backend.system.Controls.Control;
import funkin.backend.system.gamejolt.GameJoltSecurity;
import funkin.backend.assets.AssetSource;


typedef CNEGameJoltData = {
	ownerU:String,
	ownerI:Int,
	defTrophies:Map<String, GJTrophyData>,
	cusTrophies:Map<String, GJTrophyData>,
	leaderboards:Map<String, Int>,
	addlData:Map<String, Array<String>>,
}

typedef GameJoltUserData = {
	controls:Map<Control, Array<FlxKey>>,
	options:Map<String, String>,
	scores:Dynamic,
	misc:Map<String, String>
}

typedef GJTrophyData = {
	id:Int,
	?require:Int,
	?except:Array<String>,
	?hidden:Bool,
	?weekName:String,
}

class GameJoltData
{
	public static var freshStart(default, null):Bool = false;

	public static var ownerUsername:Null<String> = null;

	public static var ownerUserId:Null<Int> = null;

	public static var leaderboards:Map<String, Int> = [];

	public static var definedTrophies:Map<String, GJTrophyData> = [];

	public static var definitions:Array<String> = ['open-first', 'friday-night', 'week', 'complete-all', 'fc-first', 'fc-all'];

	/**
	 * Custom trophies that mods may want to implement outside of the usual suspects.
	 * Unfortunately, these could be easy to cheese.
	 */
	public static var customTrophies(default, null):Map<String, GJTrophyData> = [];

	public static var earnedTrophies:Map<String, GJTrophyData> = [];

	public static var dataToInclude:Map<String, Array<String>> = [];

	static var xmlPath:String = Paths.xml('config/gamejolt');

	static var helpText:String = '<!-- XML for gamejolt setup.
This stores it to the global database of the game, under the
key CNE_DATASTORE.
By storing it there, only the owner of the game can modify
that data or delete it if necessary.

TO SETUP GAMEJOLT FOR YOUR GAME:
- Ensure that the flag `GAMEJOLT_GAME_ID` in the General section
is set to your game ID.
- Input the following nodes into this xml:
    <owner username="game-owner-username-here" token="game-owner-token-here" />

	<token>game-token-here</token>
- Run the mod. It will start a session with the owner\'s username, encrypt
your token, and inject the data into the global data store. -->';

	#if GAMEJOLT_API
	public static function loadAdminData()
	{			
		Logs.trace(Paths.assetsTree.getSpecificAsset(xmlPath, "TEXT", AssetSource.MODS));
		// get xml
		var access = getGJX();

		if (access == null)
			return;

		// return if owner and token nodes are absent
		if (!access.hasNode.owner || !access.hasNode.token) {
			Logs.trace('Missing owner or token node from gamejolt.xml!', ERROR, LIGHTGRAY, 'GameJolt');
			return;
		}

		if (!access.node.owner.has.username || !access.node.owner.has.token) {
			Logs.trace('Missing username or user token in gamejolt.xml owner node!', ERROR, LIGHTGRAY, 'GameJolt');
			return;
		}

		// encrypt token
		encryptToken(access.node.token.innerData);

		//
		if (!GJUtil.attemptLogin(access.node.owner.att.username, access.node.owner.att.token, true, true)) {
			Logs.traceColored([
				Logs.getPrefix("GameJolt"),
				Logs.logText("Unable to log in user "),
				Logs.logText(access.node.owner.att.username, GREEN),
				Logs.logText(' for data upload.')
			], ERROR);
			return;
		}			

		ownerUsername = access.node.owner.att.username;
		GameJoltSecurity.sendTrusted(USER_FETCH(ownerUsername), false, function(err) {
			Logs.traceColored([
				Logs.getPrefix("GameJolt"),
				Logs.logText("Unable to obtain mandatory user ID data from user "),
				Logs.logText(ownerUsername, GREEN),
				Logs.logText(' for data upload: ${err}')
			], ERROR);
			ownerUsername = null;
			GJUtil.logout(false, true);
		}, function(resp) {
			ownerUserId = resp.users[0].id;
		});

		if (ownerUserId == null)
			return;

		setGlobalData(true, () -> {
			GJUtil.logout(false, true);
			var overwriteXml:Xml = access.x;
			for (own in access.x.elements()) {
				if (own.nodeName == "owner" || own.nodeName == "token")
					overwriteXml.removeChild(own);
			}

			try {
				// FileSystem.deleteFile(Paths.assetsTree.getSpecificPath(xmlPath, AssetSource.MODS));
				File.saveContent(Paths.assetsTree.getSpecificPath(xmlPath, AssetSource.MODS), helpText + '\n' + overwriteXml.toString());
			} catch(e) {
				Logs.trace('Error creating new XML file: ${e}', ERROR, LIGHTGRAY, "GameJolt");
			}
			freshStart = true;
		}, access);
	}

	public static function loadGlobalData():Bool
	{
		var ret:Bool = false;
		GameJoltSecurity.sendTrusted(DATA_FETCH('CNE_DATASTORE', false), true, function(err) {
			Logs.trace('Unable to obtain global mod data. GameJolt API turning off automatically.', ERROR, LIGHTGRAY, 'GameJolt');
			GJUtil.logout(false, true);
		}, function(resp) {
			var daDat:CNEGameJoltData = cast Json.parse(resp.data);
			ownerUsername = daDat.ownerU;
			ownerUserId = daDat.ownerI;
			definedTrophies = daDat.defTrophies;
			customTrophies = daDat.cusTrophies;
			leaderboards = daDat.leaderboards;
			dataToInclude = daDat.addlData;
			ret = true;
		});
		return ret;
	}

	//region Set CNE Glob'ls
	public static function setGlobalData(cleanSet:Bool = false, ?callback:Void->Void, ?data:Access)
	{
		if (data == null) {
			data = getGJX();
			if (data == null) {
				Logs.traceColored([
					Logs.getPrefix("GameJolt"),
					Logs.logText("Unable to locate "),
					Logs.logText("gamejolt.xml", GREEN),
					Logs.logText(' in '),
					Logs.logText("data/config", GREEN),
					Logs.logText(' folder!'),
				], ERROR);
				return;
			}
		}

		// With all of these nodes, it's important to make sure that
		// what we're importing a) exists, and b) isn't just a blank string.

		for (trophyDef in data.node.trophies.nodes.defined) {
				if (!trophyDef.has.def || !trophyDef.has.id || trophyDef.att.def == '' || trophyDef.att.id == '')
					continue;

				if (!definitions.contains(trophyDef.att.def))
					customTrophies.set(trophyDef.att.def, {
						id: Std.parseInt(trophyDef.att.id),
						require: (trophyDef.has.require && trophyDef.att.require != '') ? Std.parseInt(trophyDef.att.require) : null,
						except: (trophyDef.has.except && trophyDef.att.except != '') ? trophyDef.att.except.split('//') : null,
						hidden: (trophyDef.has.hidden && trophyDef.att.hidden != '') ? (trophyDef.att.hidden == 'true') : null,
						weekName: null,
					});

				if (trophyDef.att.def == 'week' && (!trophyDef.has.weekName || trophyDef.att.weekName == ''))
					continue;

				definedTrophies.set(trophyDef.att.def + (trophyDef.att.def == 'week' ? '-${trophyDef.att.weekName}': ''), {
					id: Std.parseInt(trophyDef.att.id),
					require: (trophyDef.has.require && trophyDef.att.require != '') ? Std.parseInt(trophyDef.att.require) : null,
					except: (trophyDef.has.except && trophyDef.att.except != '') ? trophyDef.att.except.split('//') : null,
					hidden: (trophyDef.has.hidden && trophyDef.att.hidden != '') ? (trophyDef.att.hidden == 'true') : null,
					weekName: (trophyDef.att.def == 'week' && trophyDef.has.weekName && trophyDef.att.weekName != '') ? trophyDef.att.weekName : null,
				});
			}

			for (trophyDef in data.node.trophies.nodes.custom) {
				if (!trophyDef.has.def || !trophyDef.has.id)
					continue;

				customTrophies.set(trophyDef.att.def, {
					id: Std.parseInt(trophyDef.att.def),
					require: (trophyDef.has.require && trophyDef.att.require != '') ? Std.parseInt(trophyDef.att.require) : null,
					except: (trophyDef.has.except && trophyDef.att.except != '') ? trophyDef.att.except.split('//') : null,
					hidden: (trophyDef.has.hidden && trophyDef.att.hidden != '') ? (trophyDef.att.hidden == 'true') : null,
					weekName: null,
				});
			}

			for (leaderboard in data.node.leaderboards.nodes.song) {
				if (!leaderboard.has.id || !leaderboard.has.name || leaderboard.att.name == '' || leaderboard.att.id == '')
					continue;

				leaderboards.set(leaderboard.att.name + (leaderboard.has.diff ? '-${leaderboard.att.diff}' : '') + ' (${leaderboard.has.vari ? leaderboard.att.vari : 'Default'})', Std.parseInt(leaderboard.att.id));
			}

			for (dat in data.node.data.nodes.value) {
				if (!dat.has.name || dat.att.name == '')
					continue;

				var location:String = (dat.has.inSave && dat.att.inSave != '') ? dat.att.inSave : "FlxG";
				var curVars:Array<String> = dataToInclude.exists(location) ? dataToInclude.get(location) : [];
				curVars.push(dat.att.name);
				dataToInclude.set(location, curVars);
			}

			var sendOut:CNEGameJoltData = {
				ownerU: ownerUsername,
				ownerI: ownerUserId,
				defTrophies: definedTrophies,
				cusTrophies: customTrophies,
				leaderboards: leaderboards,
				addlData: dataToInclude,
			};

			Logs.trace('Sending global data...', INFO, LIGHTGRAY, "GameJolt");

			var success:Bool = true;
			GameJoltSecurity.sendTrusted(DATA_SET('CNE_DATASTORE', Json.stringify(sendOut), false), false, function(err) {
				Logs.trace('Unable to upload global GameJolt data: ${err}', ERROR, LIGHTGRAY, 'GameJolt');
				success = false;
				if (cleanSet) {
					reset();
					GJUtil.logout(false, true);
				}
			});
			
			if (!success)
				return;

			Logs.trace('Global data set successfully!', SUCCESS, LIGHTGRAY, "GameJolt");

			if (callback != null) callback();
	}
	//endregion

	public static function setUserData()
	{

	}

	public static function loadUserData()
	{

	}

	static function getGJX():Null<Access>
	{
		if (!Paths.assetsTree.existsSpecific(xmlPath, "TEXT", AssetSource.MODS))
			return null;

		var access:Access = null;
		try {
			access = new Access(Xml.parse(Paths.assetsTree.getSpecificAsset(xmlPath, "TEXT", AssetSource.MODS)).firstElement());
		} catch(e) {
			Logs.trace('Error while parsing gamejolt.xml: ${Std.string(e)}', ERROR, LIGHTGRAY, 'GameJolt');
		}
		return access;
	}

	static function encryptToken(token:String)
	{
		var validHex:String = "0123456789abcdef";

		var dateString:String = Date.now().toString();

		var hexString:String = '';

		for (i in 0...dateString.length - 1) {
			if (dateString.charAt(i) == ' ') continue;
			if (hexString.length == 32) break;
			var charCode:Int = StringTools.fastCodeAt(dateString, i);
			var charString:String = StringTools.hex(charCode);
			hexString += charString.substr(0, Std.int(Math.min(charString.length, 32 - hexString.length)));
		}

		for (i in 0...(32 - hexString.length)) {
			if (FlxG.random.bool()) {
				hexString += validHex.charAt(FlxG.random.int(0, validHex.length - 1));
			} else {
				hexString = validHex.charAt(FlxG.random.int(0, validHex.length - 1)) + hexString;
			}
		}
		var iv:Bytes = Bytes.ofHex(hexString);

		@:privateAccess
		var aes:Aes = new Aes(Bytes.ofHex(GameJoltSecurity.CODENAME_AES_KEY), iv);
		var encryp:Bytes = aes.encrypt(Mode.OFB, Bytes.ofString(token), Padding.NoPadding);

		GameJoltSecurity.encryptedGameToken = Flags.MOD_GAMEJOLT_ENCRYPTED_TOKEN = hexString.toLowerCase() + encryp.toHex();
	}

	public static function reset(fullWipe:Bool = false)
	{
		earnedTrophies = [];
		if (fullWipe) {
			ownerUsername = null;
			ownerUserId = null;
			leaderboards = [];
			definedTrophies = [];
			customTrophies = [];
			dataToInclude = [];
			freshStart = false;
		}
	}
	#else
	public static function loadAdminData()
	{			
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		return;
	}

	public static function loadGlobalData()
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		return;
	}

	public static function setGlobalData(cleanSet:Bool = false, ?callback:Void->Void, ?data:Access)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		return;
	}

	public static function setUserData()
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		return;
	}

	public static function loadUserData()
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		return;
	}

	public static function reset(fullWipe:Bool = false)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		return;
	}
	#end
}