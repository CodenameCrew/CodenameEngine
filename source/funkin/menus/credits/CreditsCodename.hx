package funkin.menus.credits;

import funkin.options.PlayerSettings;
import flixel.util.FlxColor;
import funkin.backend.system.github.GitHub;
import funkin.options.type.GithubIconOption;
import flixel.text.FlxText;

using StringTools;

class CreditsCodename extends funkin.options.OptionsScreen {
	public var error:Bool = false;
	public var author:String = "CodenameCrew";
	public var totalContributions:Int = 0;

	public var mainDevCol:FlxColor = 0xFF9C35D5;
	public var minContrCol:FlxColor = 0xFFB4A7DA;
	public var contribFormats:Array<FlxTextFormatMarkerPair> = [];

	public override function new()
	{
		super("Codename Engine", "All the contributors of the engine! - Press RESET to update the list (One reset per 2 minutes).");
		tryUpdating(true);
	}

	// blame the secondary threads if the code has to look this bad  - Nex
	private var _canReset:Bool = true;
	private var _downloadingSteps:Int = 0;
	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (_downloadingSteps == 2) {
			_downloadingSteps = 0;
			_canReset = true;
			displayList();
		} else if (_downloadingSteps == 1) {
			_downloadingSteps = 0;
			_canReset = true;
			updateMenuDesc();
		}
		else if(_canReset && PlayerSettings.solo.controls.RESET) tryUpdating();
	}

	public function tryUpdating(forceDisplaying:Bool = false) {
		updateMenuDesc("Downloading List...");
		_canReset = false;
		Main.execAsync(function() {
			if(checkUpdate() || forceDisplaying) _downloadingSteps = 2;
			else _downloadingSteps = 1;
		});
	}

	public override function updateMenuDesc(?txt:String) {
		if(!_canReset) return;
		super.updateMenuDesc(txt);
		updateMarkup();
	}

	public function updateMarkup() {
		if(parent == null || parent.treeParent == null) return;
		var text:String = parent.treeParent.pathDesc.text;
		parent.treeParent.pathDesc.text = "";
		parent.treeParent.pathDesc.applyMarkup(text, contribFormats = [
			new FlxTextFormatMarkerPair(new FlxTextFormat(mainDevCol), '*'),
			new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.interpolate(minContrCol, mainDevCol, Options.contributors[curSelected].contributions / totalContributions)), '~')
		]);
	}

	override function close() {
		super.close();
		for (frmt in contribFormats) parent.treeParent.pathDesc.removeFormat(frmt.format);
	}

	public function checkUpdate():Bool {
		var curTime:Float = Date.now().getTime();
		if(Options.lastUpdated != null && curTime < Options.lastUpdated + 120000) return false;  // Fuck you Github rate limits  - Nex
		Options.lastUpdated = curTime;

		error = false;
		var idk = GitHub.getContributors(author, "CodenameEngine", function(e) {
			error = true;
			var errMsg:String = 'Error while trying to download contributors list:\n${CoolUtil.removeIP(e.message)}';
			Logs.traceColored([Logs.logText(errMsg.replace('\n', ' '), RED)], ERROR);
			funkin.backend.utils.NativeAPI.showMessageBox("Codename Engine Warning", errMsg, MSG_WARNING);
		});
		if(error) return false;
		Options.contributors = idk;
		trace('Contributors list Updated!');

		var errorOnMain:Bool = false;
		var idk2 = GitHub.getOrganizationMembers(author, function(e) {
			errorOnMain = true;
			var errMsg:String = 'Error while trying to download $author members list:\n${CoolUtil.removeIP(e.message)}';
			Logs.traceColored([Logs.logText(errMsg.replace('\n', ' '), RED)], ERROR);
			funkin.backend.utils.NativeAPI.showMessageBox("Codename Engine Warning", errMsg, MSG_WARNING);
		});
		if(!errorOnMain) {
			Options.mainDevs = [for(m in idk2) m.id];
			trace('Main Devs list Updated!');
		}

		return true;
	}

	public function displayList() {
		//if (curSelected > Options.contributors.length - 1) changeSelection(-(curSelected - (Options.contributors.length - 1)));
		if (curSelected > Options.contributors.length - 1) curSelected = Options.contributors.length - 1;
		changeSelection(0, true);

		while (members.length > 0) {
			members[0].destroy();
			remove(members[0], true);
		}

		totalContributions = 0;
		for(c in Options.contributors) totalContributions += c.contributions;
		for(c in Options.contributors) {
			var opt:GithubIconOption = new GithubIconOption(c, 'Total Contributions: ~${c.contributions}~ / *${totalContributions}* (~${FlxMath.roundDecimal(c.contributions / totalContributions * 100, 2)}%~) - Select to open GitHub account');
			if(Options.mainDevs.contains(c.id)) {
				opt.desc += " *- Public member of the main Devs!*";
				@:privateAccess opt.__text.color = mainDevCol;
			}
			add(opt);
		}

		updateMenuDesc();
	}
}