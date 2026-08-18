package funkin.backend.system.gamejolt;

import flixel.util.FlxSave;
import haxe.xml.Access;
import haxe.io.Bytes;
import haxe.crypto.Aes;
import haxe.crypto.mode.Mode;
import haxe.crypto.padding.Padding;
import haxe.Json;
import sys.io.File;
import flixel.input.keyboard.FlxKey;
import funkin.backend.utils.GJUtil;
import funkin.backend.utils.GJUtil.ScoreTable;
import funkin.backend.system.Controls.Control;
import funkin.backend.system.gamejolt.GameJoltSecurity;
import funkin.backend.assets.AssetSource;
import funkin.savedata.FunkinSave;

//region Typedefs
typedef CNEGameJoltData = {
	ownerU:String,
	ownerI:Int,
	defTrophies:Map<String, GJTrophyData>,
	cusTrophies:Map<String, GJTrophyData>,
	leaderboards:Map<String, Int>,
	addlData:Map<String, Array<String>>,
}

typedef GameJoltUserData = {
	options:Dynamic,
	scores:Dynamic,
	?miscItems:Dynamic,
}

typedef GJTrophyData = {
	id:Int,
	?require:Array<Int>,
	?except:Array<String>,
	?hidden:Bool,
	?weekName:String,
}
//endregion

class GameJoltData
{
	//region Variables
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

	static var helpText:String = 'XML for gamejolt setup.\n
This stores it to the global database of the game, under the
key CNE_DATASTORE.\n
By storing it there, only the owner of the game can modify
that data or delete it if necessary.\n\n

TO SETUP GAMEJOLT FOR YOUR GAME:\n
- Ensure that the flag `GAMEJOLT_GAME_ID` in the General section
is set to your game ID.\n
- Input the following nodes into this xml:\n
    <owner username="game-owner-username-here" token="game-owner-token-here" />\n\n

	<token>game-token-here</token>\n
- Run the mod. It will start a session with the owner\'s username, encrypt
your token, and inject the data into the global data store.';
	//endregion

	#if GAMEJOLT_API
	public static function loadAdminData()
	{			
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
		GJUtil.attemptLogin(access.node.owner.att.username, access.node.owner.att.token, (bl) -> {
			if (!bl) {
				Logs.traceColored([
					Logs.getPrefix("GameJolt"),
					Logs.logText("Unable to log in user "),
					Logs.logText(access.node.owner.att.username, GREEN),
					Logs.logText(' for data upload.')
				], ERROR);
			} else {
				ownerUsername = access.node.owner.att.username;
				if(GameJoltSecurity.userId == null) {
					ownerUsername = null;
					GJUtil.logout(false, true);
					return;
				}

				setGlobalData(true, (bl) -> {
					GJUtil.logout(false, true);
					if (bl)
						if (buildGamejoltXml())
							freshStart = true;
				}, access);
			}
		}, true, true);
	}

	//region CNE Globals
	public static function loadGlobalData(?callback:Bool->Void)
	{
		GameJoltSecurity.sendTrusted(DATA_FETCH('CNE_DATASTORE', false), true, function(err) {
			Logs.trace('Unable to obtain global mod data: $err GameJolt API turning off automatically.', ERROR, LIGHTGRAY, 'GameJolt');
			GJUtil.logout(false, true);
			if (callback != null) callback(false);
		}, function(resp) {
			var daDat:CNEGameJoltData = cast Json.parse(resp.data);
			ownerUsername = daDat.ownerU;
			ownerUserId = daDat.ownerI;
			definedTrophies = daDat.defTrophies;
			customTrophies = daDat.cusTrophies;
			leaderboards = daDat.leaderboards;
			dataToInclude = daDat.addlData;
			if (callback != null) callback(true);
		});
	}

	public static function setGlobalData(cleanSet:Bool = false, ?callback:Bool->Void, ?data:Access)
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

		if (data.hasNode.trophies) {
			if (data.node.trophies.hasNode.defined) for (trophyDef in data.node.trophies.nodes.defined) {
				if (!trophyDef.has.def || !trophyDef.has.id || trophyDef.att.def == '' || trophyDef.att.id == '')
					continue;

				if (!definitions.contains(trophyDef.att.def))
					customTrophies.set(trophyDef.att.def, {
						id: Std.parseInt(trophyDef.att.id),
						require: (trophyDef.has.require && trophyDef.att.require != '') ? [for (trop in trophyDef.att.require.split(',')) Std.parseInt(trop.trim())] : null,
						except: (trophyDef.has.except && trophyDef.att.except != '') ? [for (trop in trophyDef.att.except.split('//')) trop.trim()] : null,
						hidden: (trophyDef.has.hidden && trophyDef.att.hidden != '') ? (trophyDef.att.hidden == 'true') : null,
						weekName: null,
					});

				if (trophyDef.att.def == 'week' && (!trophyDef.has.weekName || trophyDef.att.weekName == ''))
					continue;

				definedTrophies.set(trophyDef.att.def + (trophyDef.att.def == 'week' ? '-${trophyDef.att.weekName}': ''), {
					id: Std.parseInt(trophyDef.att.id),
					require: (trophyDef.has.require && trophyDef.att.require != '') ? [for (trop in trophyDef.att.require.split(',')) Std.parseInt(trop.trim())] : null,
					except: (trophyDef.has.except && trophyDef.att.except != '') ? [for (trop in trophyDef.att.except.split('//')) trop.trim()] : null,
					hidden: (trophyDef.has.hidden && trophyDef.att.hidden != '') ? (trophyDef.att.hidden == 'true') : null,
					weekName: (trophyDef.att.def == 'week' && trophyDef.has.weekName && trophyDef.att.weekName != '') ? trophyDef.att.weekName : null,
				});
			}

			if (data.node.trophies.hasNode.custom) for (trophyDef in data.node.trophies.nodes.custom) {
				if (!trophyDef.has.def || !trophyDef.has.id)
					continue;

				customTrophies.set(trophyDef.att.def, {
					id: Std.parseInt(trophyDef.att.def),
					require: (trophyDef.has.require && trophyDef.att.require != '') ? [for (trop in trophyDef.att.require.split(',')) Std.parseInt(trop.trim())] : null,
					except: (trophyDef.has.except && trophyDef.att.except != '') ? [for (trop in trophyDef.att.except.split('//')) trop.trim()] : null,
					hidden: (trophyDef.has.hidden && trophyDef.att.hidden != '') ? (trophyDef.att.hidden == 'true') : null,
					weekName: null,
				});
			}
		}

		if (data.hasNode.leaderboards) for (leaderboard in data.node.leaderboards.nodes.song) {
			if (!leaderboard.has.id || !leaderboard.has.name || leaderboard.att.name == '' || leaderboard.att.id == '')
				continue;

			leaderboards.set(leaderboard.att.name + (leaderboard.has.diff ? '--D:${leaderboard.att.diff}' : '') + ' (V:${leaderboard.has.vari ? leaderboard.att.vari : 'Default'})', Std.parseInt(leaderboard.att.id));
		}

		if (data.hasNode.data) for (dat in data.node.data.nodes.value) {
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

		GameJoltSecurity.sendTrusted(DATA_SET('CNE_DATASTORE', Json.stringify(sendOut), false), true, function(err) {
			Logs.trace('Unable to upload global GameJolt data: ${err}', ERROR, LIGHTGRAY, 'GameJolt');
			if (cleanSet) {
				reset();
				GJUtil.logout(false, true);
			} else if (callback != null)
				callback(false);
		}, function(resp) {
			Logs.trace('Global data set successfully!', SUCCESS, LIGHTGRAY, "GameJolt");
			if (callback != null) callback(true);
		});
	}

	public static function wipeGlobalData(?callback:Bool->Void)
	{
		GameJoltSecurity.sendTrusted(DATA_REMOVE('CNE_DATASTORE', false), true, function(err) {
			Logs.trace('Unable to wipe global mod data: $err', ERROR, LIGHTGRAY, 'GameJolt');
			if (callback != null) callback(false);
		}, function(resp) {
			if (callback != null) callback(true);
		});
	}
	//endregion

	//region User Data
	public static function setUserData(?callback:Bool->Void)
	{
		FunkinSave.flush();

		var addlStuff:Dynamic = {};

		if (dataToInclude != null) for (elem in dataToInclude.keys()) {
			var daSave:FlxSave = Reflect.field(elem, "save");
			if (daSave == null)
				continue;
			var addlSaveItems:Dynamic = {};
			for (itm in dataToInclude.get(elem)) {
				var itmVal = Reflect.field(daSave.data, itm);
				if (itmVal == null)
					continue;
				Reflect.setField(addlSaveItems, itm, itmVal);
			}
			Reflect.setField(addlStuff, elem, addlSaveItems);
		}

		var dataToSend:GameJoltUserData = {
			options: Options.__save.data,
			scores: FunkinSave.save.data.highscores,
			miscItems: addlStuff != [] ? addlStuff : null,
		};


		var daId:Null<Int> = GameJoltSecurity.userId;
		if (daId == null) {
			if (callback != null) callback(false);
		} else {
			Logs.trace('Sending user data...', INFO, LIGHTGRAY, "GameJolt");

			GameJoltSecurity.sendTrusted(DATA_SET('USER_$daId', Json.stringify(dataToSend), true), true, function(err) {
				Logs.traceColored([
					Logs.getPrefix("GameJolt"),
					Logs.logText("Unable to set data for user "),
					Logs.logText(GJUtil.userName, GREEN),
					Logs.logText(': ${err}')
				], ERROR);
				if (callback != null)
					callback(false);
			}, function(resp) {
				Logs.trace('User data sent successfully!', SUCCESS, LIGHTGRAY, 'GameJolt');
				if (callback != null) callback(true);
			});
		}
	}

	public static function loadUserData(?callback:Bool->Void)
	{
		var daId:Null<Int> = GameJoltSecurity.userId;
		if (daId == null) {
			if (callback != null) callback(false);
		} else {
			Logs.trace('Fetching user data...', INFO, LIGHTGRAY, "GameJolt");

			GameJoltSecurity.sendTrusted(DATA_FETCH('USER_$daId', true), true, function(err) {
				Logs.traceColored([
					Logs.getPrefix("GameJolt"),
					Logs.logText("Unable to set data for user "),
					Logs.logText(GJUtil.userName, GREEN),
					Logs.logText(': ${err}')
				], ERROR);
				if (callback != null) callback(false);
			}, function(resp) {
				Logs.trace('User data collected successfully; now setting save data to obtained user data...', INFO, LIGHTGRAY, "GameJolt");
				var daData:GameJoltUserData = cast Json.parse(resp.data);
				Options.__save.mergeData(daData.options, true);
				FunkinSave.save.data.highscores = daData.scores;
				if (daData.miscItems != null) {
					for (location in Reflect.fields(daData.miscItems)) {
						if (location == null)
							continue;
						var daSve:FlxSave = Reflect.field(location, "save");
						if (daSve == null)
							continue;
						for (daItm in Reflect.fields(location)) {
							Reflect.setField(daSve.data, daItm, Reflect.field(location, daItm));
						}

						daSve.flush();
					}
				}
				if (callback != null) callback(true);
			});
		}
	}

	public static function wipeUserData(?callback:Bool->Void)
	{
		var daId:Null<Int> = GameJoltSecurity.userId;
		if (daId == null) {
			if (callback != null) callback(false);
		} else {
			GameJoltSecurity.sendTrusted(DATA_REMOVE('USER_$daId', true), true, function(err) {
				Logs.trace('Unable to wipe user mod data: $err', ERROR, LIGHTGRAY, 'GameJolt');
				if (callback != null) callback(false);
			}, function(resp) {
				if (callback != null) callback(true);
			});
		}
	}
	//endregion

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

	static function buildGamejoltXml(?fromXml:Xml):Bool
	{
		final bodyNode:Xml = Xml.createElement('gamejolt');
		final trophyNodes:Xml = Xml.createElement('trophies');
		final leaderNodes:Xml = Xml.createElement('leaderboards');
		final dataNodes:Xml = Xml.createElement('data');
		final ret:Xml = Xml.createDocument();

		for (key => trop in definedTrophies) {
			var nodeToTrophy:Xml = Xml.createElement('default');
			nodeToTrophy.set('def', key);
			if (trop.require != null)
				nodeToTrophy.set('require', trop.require.join(','));
			if (trop.except != null)
				nodeToTrophy.set('except', trop.except.join(','));
			if (trop.hidden != null)
				nodeToTrophy.set('hidden', '${trop.hidden}');
			if (trop.weekName != null)
				nodeToTrophy.set('week', trop.weekName);
			nodeToTrophy.set('id', '${trop.id}');
			trophyNodes.addChild(nodeToTrophy);
		}

		for (key => trop in customTrophies) {
			var nodeToTrophy:Xml = Xml.createElement('custom');
			nodeToTrophy.set('def', key);
			if (trop.require != null)
				nodeToTrophy.set('require', trop.require.join(','));
			if (trop.except != null)
				nodeToTrophy.set('except', trop.except.join(','));
			if (trop.hidden != null)
				nodeToTrophy.set('hidden', '${trop.hidden}');
			nodeToTrophy.set('id', '${trop.id}');
			trophyNodes.addChild(nodeToTrophy);
		}

		for (key => board in leaderboards) {
			var nodeToLeader:Xml = Xml.createElement('song');
			var diffInd:Int = key.indexOf('--D:');
			var variInd:Int = key.indexOf('(V:');
			var nameSplice = key.substring(0, diffInd != -1 ? diffInd : variInd).trim();
			nodeToLeader.set('name', nameSplice);
			if (diffInd != -1) {
				var diffSplice:String = key.substring(diffInd + 4, variInd).trim();
				nodeToLeader.set('diff', diffSplice);
			}
			var variSplice:String = key.substring(variInd + 3, key.lastIndexOf(')')).trim();
			nodeToLeader.set('vari', variSplice);
			nodeToLeader.set('id', '$board');
			leaderNodes.addChild(nodeToLeader);
		}

		for (key => loc in dataToInclude) {
			for (itm in loc) {
				var nodeToData:Xml = Xml.createElement('value');
				nodeToData.set('name', itm);
				nodeToData.set('inSave', key);
				dataNodes.addChild(nodeToData);
			}
		}

		bodyNode.addChild(trophyNodes);
		bodyNode.addChild(leaderNodes);
		bodyNode.addChild(dataNodes);
		ret.addChild(bodyNode);
		
		var finalBool:Bool = true;
		try {
			File.saveContent(Paths.assetsTree.getSpecificPath(xmlPath, AssetSource.MODS), '<!--$helpText-->\n' + XMLUtil.fixXMLText(ret.toString()));
		} catch(e) {
			finalBool = false;
			Logs.trace('Error creating new XML file: ${e}', ERROR, LIGHTGRAY, "GameJolt");
		}

		return finalBool;
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
	#else
	//region GJ API Inaccessible
	public static function loadAdminData()
	{			
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		return;
	}

	public static function loadGlobalData(?callback:Bool->Void)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		if (callback != null) callback(false);
	}

	public static function setGlobalData(cleanSet:Bool = false, ?callback:Bool->Void, ?data:Access)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		if (callback != null) callback(false);
	}

	public static function wipeGlobalData(?callback:Bool->Void)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		if (callback != null) callback(false);
	}

	public static function setUserData(?callback:Bool->Void)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		if (callback != null) callback(false);
	}

	public static function loadUserData(?callback:Bool->Void)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		if (callback != null) callback(false);
	}

	public static function wipeUserData(?callback:Bool->Void)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		if (callback != null) callback(false);
	}

	public static function reset(fullWipe:Bool = false)
	{
		Logs.trace('GameJolt API not set in Project.xml!', ERROR, LIGHTGRAY, 'GameJolt');
		return;
	}
	//endregion
	#end
}