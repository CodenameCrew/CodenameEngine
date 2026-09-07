package funkin.backend.system.gamejolt;

import flixel.util.FlxSave;
import haxe.xml.Access;
import haxe.io.Bytes;
import haxe.crypto.Aes;
import haxe.crypto.mode.Mode;
import haxe.crypto.padding.Padding;
import haxe.Json;
import sys.io.File;
import funkin.backend.utils.GJUtil;
import funkin.backend.system.gamejolt.GameJoltSecurity;
import funkin.backend.assets.AssetSource;
import funkin.menus.gamejolt.GameJoltCompleteScreen;
import funkin.savedata.FunkinSave;

//region Typedefs
/**
 * Global data store format. Used to provide a unanimous
 * structure to data loading.
 */
typedef CNEGameJoltData = {
	ownerU:String,
	ownerI:Int,
	defTrophies:String,
	cusTrophies:String,
	leaderboards:String,
	addlData:String,
}

/**
 * User data store format. Used to provide a unanimous
 * structure to data loading.
 */
typedef GameJoltUserData = {
	options:Dynamic,
	scores:Dynamic,
	miscItems:Dynamic,
}

/**
 * Trophy data. This is not the data pulled from the GameJolt API - 
 * instead, it allows for things like trophy pre-requisites
 * or anything that should be excluded from requirements.
 */
typedef GJTrophyData = {
	id:Int,
	?require:Array<Int>,
	?except:Array<String>,
	?hidden:Bool,
	?weekName:String,
	?songName:String,
}
//endregion
/**
 * Data class for GameJolt.
 * 
 * Holds, sets, and modifies variables from the global data store (which can
 * only be set by the owner of the GameJolt game) or the user-specific
 * data store.
 */
class GameJoltData
{
	//region Variables
	/**
	 * Whether to go to the page displaying the key and successful data transfer.
	 */
	public static var freshStart(default, null):Bool = false;

	/**
	 * The username of the owner of the GameJolt page.
	 * Set using the global data store.
	 */
	public static var ownerUsername:Null<String> = null;

	/**
	 * The ID of the owner of the GameJolt page.
	 * Cross-checks this alongside the current user to
	 * determine access to global variables.
	 */
	public static var ownerUserId:Null<Int> = null;

	/**
	 * Leaderboards from the global data store.
	 */
	public static var leaderboards(default, null):Map<String, Int> = new Map<String, Int>();

	/**
	 * Any trophies defined specifically for use in hardcoding.
	 * Set using the global data store.
	 * To set trophies in hardcode, use the `definitions` var as the `def`
	 * attribute in the node, then set the parameters and trophy ID.
	 */
	public static var definedTrophies(default, null):Map<String, GJTrophyData> = new Map<String, GJTrophyData>();

	/**
	 * Any valid definitions that can be used in hardcoding.
	 */
	public static var definitions(default, null):Array<String> = ['open-first', 'friday-night', 'week', 'song', 'complete-all', 'fc-first', 'fc-all', 'death-first'];

	/**
	 * Custom trophies that mods may want to implement outside of the usual suspects.
	 * Unfortunately, these could be easy to cheese.
	 */
	public static var customTrophies(default, null):Map<String, GJTrophyData> = new Map<String, GJTrophyData>();

	/**
	 * Any trophies that the user already earned.
	 * Exists to not make an insane amount of calls per game, even if
	 * they are async.
	 */
	public static var earnedTrophies:Map<String, GJTrophyData> = new Map<String, GJTrophyData>();

	/**
	 * Any pieces of the save data that the game should save in user data.
	 * Set using the global data store.
	 */
	public static var dataToInclude:Map<String, Array<String>> = new Map<String, Array<String>>();

	/**
	 * Path of the gamejolt.xml.
	 * Mainly here to prevent ghost variables where possible.
	 */
	static var xmlPath:String = Paths.xml('config/gamejolt');

	/**
	 * Help text to be printed in the XML file.
	 * Mainly here to prevent ghost varialbes where possible.
	 */
	static var helpText:String = 'XML for gamejolt setup.
This stores it to the global database of the game, under the
key CNE_DATASTORE.
By storing it there, only the owner of the game can modify
that data or delete it if necessary.

TO SETUP GAMEJOLT FOR YOUR GAME:
- Ensure that the flag `GAMEJOLT_GAME_ID` in the General section
is set to your game ID.
- Input the following nodes into this xml:
    <owner username="game-owner-username-here" token="game-owner-token-here" />

	<gamekey>game-private-key-here</gamekey>
- Run the mod. It will start a session with the owner\'s username, encrypt
your game key, and inject the data into the global data store.';
	//endregion

	#if GAMEJOLT_API
	/**
	 * Used for initialization of the global data store and
	 * GameJolt integrations.
	 * Only called if the system doesn't recognize a game
	 * security key.
	 */
	public static function loadAdminData()
	{			
		// get xml
		var access = getGJX();

		if (access == null) {
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

		// return if owner and gamekey nodes are absent
		if (!access.hasNode.owner || !access.hasNode.gamekey) {
			Logs.trace('Missing owner or gamekey node from gamejolt.xml!', ERROR, LIGHTGRAY, 'GameJolt');
			return;
		}

		if (!access.node.owner.has.username || !access.node.owner.has.token) {
			Logs.trace('Missing username or user token in gamejolt.xml owner node!', ERROR, LIGHTGRAY, 'GameJolt');
			return;
		}

		// encrypt gamekey
		encryptToken(access.node.gamekey.innerData);

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
				ownerUserId = GameJoltSecurity.userId;

				setGlobalData(true, (bl) -> {
					GJUtil.logout(false, true);
					if (bl) {
						if (buildGamejoltXml()) {
							freshStart = true;
							FlxG.switchState(new GameJoltCompleteScreen());
						}
					}
				}, access);
			}
		}, true, true);
	}

	//region CNE Globals
	/**
	 * Loads the variables from the global data store.
	 * @param callback Function to run on failure (false) or success
	 * (true) to load global data.
	 */
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
			if (daDat.defTrophies != 'null') {
				var itms:Array<String> = daDat.defTrophies.split('---');
				for (indiv in itms) {
					var details:Array<String> = indiv.split('-V:');
					definedTrophies.set(details[0], cast Json.parse(details[1]));
				}
			}
			if (daDat.cusTrophies != 'null') {
				var itms:Array<String> = daDat.cusTrophies.split('---');
				for (indiv in itms) {
					var details:Array<String> = indiv.split('-V:');
					customTrophies.set(details[0], cast Json.parse(details[1]));
				}
			}
			if (daDat.leaderboards != 'null') {
				var itms:Array<String> = daDat.leaderboards.split('---');
				for (indiv in itms) {
					var details:Array<String> = indiv.split('-V:');
					leaderboards.set(details[0], Std.parseInt(details[1]));
				}
			}
			if (daDat.addlData != 'null') {
				var itms:Array<String> = daDat.addlData.split('---');
				for (indiv in itms) {
					var details:Array<String> = indiv.split('-V:');
					dataToInclude.set(details[0], details[1].split('-vVv-'));
				}
			}

			if (callback != null) callback(true);
		});
	}

	/**
	 * Sets the variables located in the global data store.
	 * @param cleanSet Whether or not this is the first time we're setting
	 * these variables in the global data store. If we're replacing a data
	 * store that already exists, this should be `false`.
	 * @param callback Function to run on failure (false) or success
	 * (true) to set global data.
	 * @param data Access data to set global data store to. Loads gamejolt.xml
	 * by default.
	 */
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

		var trophyDefArray:Array<String> = [];
		var trophyCusArray:Array<String> = [];
		var leaderArray:Array<String> = [];
		var dataArray:Array<String> = [];

		// With all of these nodes, it's important to make sure that
		// what we're importing a) exists, and b) isn't just a blank string.

		if (data.hasNode.trophies) {
			if (data.node.trophies.hasNode.defined) for (trophyDef in data.node.trophies.nodes.defined) {
				if (!trophyDef.has.def || !trophyDef.has.id || trophyDef.att.def == '' || trophyDef.att.id == '')
					continue;

				if (!definitions.contains(trophyDef.att.def))
					customTrophies.set(trophyDef.att.def, {
						id: Std.parseInt(trophyDef.att.id),
						require: (trophyDef.has.require && trophyDef.att.require != '') ? [for (trop in trophyDef.att.require.split('//')) Std.parseInt(trop.trim())] : null,
						except: (trophyDef.has.except && trophyDef.att.except != '') ? [for (trop in trophyDef.att.except.split('//')) trop.trim()] : null,
						hidden: (trophyDef.has.hidden && trophyDef.att.hidden != '') ? (trophyDef.att.hidden == 'true') : null,
						weekName: null,
					});

				if (trophyDef.att.def == 'week' && (!trophyDef.has.weekName || trophyDef.att.weekName == ''))
					continue;

				if (trophyDef.att.def == 'song' && (!trophyDef.has.songName || trophyDef.att.songName == ''))
					continue;

				definedTrophies.set(trophyDef.att.def + (trophyDef.att.def == 'week' ? '-${trophyDef.att.weekName}' : (trophyDef.att.def == 'song' ? '-${trophyDef.att.songName}': '')), {
					id: Std.parseInt(trophyDef.att.id),
					require: (trophyDef.has.require && trophyDef.att.require != '') ? [for (trop in trophyDef.att.require.split(',')) Std.parseInt(trop.trim())] : null,
					except: (trophyDef.has.except && trophyDef.att.except != '') ? [for (trop in trophyDef.att.except.split('//')) trop.trim()] : null,
					hidden: (trophyDef.has.hidden && trophyDef.att.hidden != '') ? (trophyDef.att.hidden == 'true') : null,
					weekName: (trophyDef.att.def == 'week' && trophyDef.has.weekName && trophyDef.att.weekName != '') ? trophyDef.att.weekName : null,
					songName: (trophyDef.att.def == 'song' && trophyDef.has.songName && trophyDef.att.songName != '') ? trophyDef.att.songName : null,
				});
			}

			if (data.node.trophies.hasNode.custom) for (trophyDef in data.node.trophies.nodes.custom) {
				if (!trophyDef.has.def || !trophyDef.has.id)
					continue;

				customTrophies.set(trophyDef.att.def, {
					id: Std.parseInt(trophyDef.att.id),
					require: (trophyDef.has.require && trophyDef.att.require != '') ? [for (trop in trophyDef.att.require.split(',')) Std.parseInt(trop.trim())] : null,
					except: (trophyDef.has.except && trophyDef.att.except != '') ? [for (trop in trophyDef.att.except.split('//')) trop.trim()] : null,
					hidden: (trophyDef.has.hidden && trophyDef.att.hidden != '') ? (trophyDef.att.hidden == 'true') : null,
					weekName: null,
				});
			}
		}

		if (data.hasNode.leaderboards) {
			if (data.node.leaderboards.hasNode.song) for (leaderboard in data.node.leaderboards.nodes.song) {
				if (!leaderboard.has.id || !leaderboard.has.name || leaderboard.att.name == '' || leaderboard.att.id == '')
					continue;

				leaderboards.set('song-' + leaderboard.att.name + (leaderboard.has.diff ? '--D:${leaderboard.att.diff}' : '') + ' (V:${leaderboard.has.vari ? leaderboard.att.vari : 'Default'})', Std.parseInt(leaderboard.att.id));
			}

			if (data.node.leaderboards.hasNode.week) for (leaderboard in data.node.leaderboards.nodes.week) {
				if (!leaderboard.has.id || !leaderboard.has.name || leaderboard.att.name == '' || leaderboard.att.id == '')
					continue;

				leaderboards.set('week-' + leaderboard.att.name + (leaderboard.has.diff ? '--D:${leaderboard.att.diff}' : ''), Std.parseInt(leaderboard.att.id));
			}
		}

		if (data.hasNode.data) for (dat in data.node.data.nodes.value) {
			if (!dat.has.name || dat.att.name == '')
				continue;

			var location:String = (dat.has.inSave && dat.att.inSave != '') ? dat.att.inSave : "FlxG";
			var curVars:Array<String> = dataToInclude.exists(location) ? dataToInclude.get(location) : [];
			curVars.push(dat.att.name);
			dataToInclude.set(location, curVars);
		}

		for (key => value in definedTrophies)
			trophyDefArray.push('$key-V:${Json.stringify(value)}');

		for (key => value in customTrophies)
			trophyCusArray.push('$key-V:${Json.stringify(value)}');

		for (key => value in leaderboards)
			leaderArray.push('$key-V:$value');

		for (key => value in dataToInclude)
			dataArray.push('$key-V:${value.join('-vVv-')}');

		var sendOut:CNEGameJoltData = {
			ownerU: ownerUsername,
			ownerI: ownerUserId,
			defTrophies: (trophyDefArray.length > 0 ? trophyDefArray.join('---') : "null"),
			cusTrophies: (trophyCusArray.length > 0 ? trophyCusArray.join('---') : "null"),
			leaderboards: (leaderArray.length > 0 ? leaderArray.join('---') : "null"),
			addlData: (dataArray.length > 0 ? dataArray.join('---') : "null"),
		};

		Logs.trace('Sending global data...', INFO, LIGHTGRAY, "GameJolt");

		GameJoltSecurity.sendTrusted(DATA_SET('CNE_DATASTORE', Json.stringify(sendOut), false), !cleanSet, function(err) {
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

	/**
	 * Wipes global data store from the GameJolt cloud data.
	 * @param callback Function to run on failure (false) or success
	 * (true) to wipe global data.
	 */
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
	/**
	 * Saves user-specific data in the game's user-specific data store.
	 * @param callback Function to run on failure (false) or success
	 * (true) to save user data.
	 */
	public static function setUserData(?callback:Bool->Void)
	{
		FunkinSave.flush();

		var addlStuff = {};

		if (dataToInclude != null) for (elem in dataToInclude.keys()) {
			var daSave:FlxSave = Reflect.field(elem, "save");
			if (daSave == null)
				continue;
			var addlSaveItems = {};
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
			miscItems: addlStuff,
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

	/**
	 * Loads user-specific data in game's user-specific data store.
	 * @param callback Function to run on failure (false) or success
	 * (true) to load user data.
	 */
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
				if (daData.miscItems != {}) {
					// I hate how much reflecting is in this code.
					var locs:Array<String> = Reflect.fields(daData.miscItems);
					for (location in locs) {
						if (location == null || location == '')
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

	/**
	 * Wipes user-specific data in game's user-specific data store.
	 * @param callback Function to run on failure (false) or success
	 * (true) to wipe user data.
	 */
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

	/**
	 * Resets the data in this class.
	 * @param fullWipe Whether or not to wipe earnedTrophies only
	 * (`false`) or all data in this class (`true`).
	 */
	public static function reset(fullWipe:Bool = false)
	{
		earnedTrophies.clear();
		if (fullWipe) {
			ownerUsername = null;
			ownerUserId = null;
			leaderboards.clear();
			definedTrophies.clear();
			customTrophies.clear();
			dataToInclude.clear();
			freshStart = false;
		}
	}

	/**
	 * Creates an XML file from the data provided in this class.
	 * @return Bool Whether or not the creation was successful.
	 */
	static function buildGamejoltXml():Bool
	{
		final bodyNode:Xml = Xml.createElement('gamejolt');
		final trophyNodes:Xml = Xml.createElement('trophies');
		final leaderNodes:Xml = Xml.createElement('leaderboards');
		final dataNodes:Xml = Xml.createElement('data');
		final ret:Xml = Xml.createDocument();

		for (key => trop in definedTrophies) {
			var nodeToTrophy:Xml = Xml.createElement('defined');
			nodeToTrophy.set('def', key.substring(0, trop.weekName != null ? 4 : null));
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

	/**
	 * Gets the gamejolt.xml file from the specified static location.
	 * @return Null<Access> If the data load was successful, returns an
	 * Access of the XML data; if unsuccessful, returns `null`.
	 */
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

	/**
	 * Encrypts a GameJolt game security key using AES encryption. It then
	 * sets the `GAMEJOLT_ENCRYPTED_TOKEN` flag to this newly-encrypted token.
	 * 
	 * ## A note about the key and IV for AES
	 * The AES key should be kept hidden, and is done so using classes
	 * inaccessible to Hscript and a .env file that is hidden to open source.
	 * This .env file generates a random key for a build if the AES key is
	 * missing - meaning if it gets lost, mods have to re-encrypt their
	 * game security keys.
	 * It is common real-world practice however to include the IV alongside the
	 * encrypted text, as done here. Both the key and IV are required to unlock an
	 * AES-encrypted text. The key though should be kept as secret as possible,
	 * as it does most of the heavy lifting in encryption; the IV mainly
	 * obscures the key and first block of encrypted text. Think of the IV as
	 * icing on the cake.
	 *
	 * And yes - I did academic research for an FNF engine, why do you ask.
	 * @param token Token to encrypt.
	 */
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