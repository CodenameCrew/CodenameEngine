package funkin.menus.credits;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.system.github.GitHub;
import funkin.backend.system.github.GitHubContributor.CreditsGitHubContributor;
import funkin.options.PlayerSettings;
import funkin.options.type.GithubIconOption;

using StringTools;

class CreditsCodename extends funkin.options.TreeMenuScreen {
	public var error:Bool = false;
	public var totalContributions:Int = 0;
	public var contribFormats:Array<FlxTextFormatMarkerPair> = [];

	public function new() {
		super("Codename Engine", "credits.allContributors");
		tryUpdating(true);
	}

	// blame the secondary threads if the code has to look this bad  - Nex
	private var _canReset:Bool = true;
	private var _downloadingSteps:Int = 0;
	override function update(elapsed:Float) {
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
		else if (_canReset && PlayerSettings.solo.controls.RESET) tryUpdating();
	}

	public function tryUpdating(forceDisplaying:Bool = false) {
		updateMenuDesc(TU.translate("credits.downloadingList"));
		_canReset = false;
		Main.execAsync(() -> {
			if (checkUpdate() || forceDisplaying) _downloadingSteps = 2;
			else _downloadingSteps = 1;
		});
	}

	public override function updateMenuDesc(?txt:String) {
		if (!_canReset) return;
		super.updateMenuDesc(txt);
		updateMarkup();
	}

	public function updateMarkup() {
		if (parent == null) return;
		var text:String = parent.descLabel.text;
		parent.descLabel.text = "";
		parent.descLabel.applyMarkup(text, contribFormats = [
			new FlxTextFormatMarkerPair(new FlxTextFormat(Flags.MAIN_DEVS_COLOR), '*'),
			new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.interpolate(Flags.MIN_CONTRIBUTIONS_COLOR, Flags.MAIN_DEVS_COLOR, Options.contributors[curSelected].contributions / totalContributions)), '~')
		]);
	}

	override function close() {
		for (frmt in contribFormats) parent.descLabel.removeFormat(frmt.format);
		super.close();
	}

	public function checkUpdate():Bool {
		var curTime:Float = Date.now().getTime();
		if(Options.lastUpdated != null && curTime < Options.lastUpdated + 120000) return false;  // Fuck you Github rate limits  - Nex
		Options.lastUpdated = curTime;

		error = false;
		var idk = GitHub.getContributors(Flags.REPO_OWNER, Flags.REPO_NAME, function(e) {
			error = true;
			var errMsg:String = 'Error while trying to download contributors list:\n${CoolUtil.removeIP(e.message)}';
			Logs.error(errMsg.replace('\n', ' '));
			funkin.backend.utils.NativeAPI.showMessageBox("Codename Engine Warning", errMsg, MSG_WARNING);
		});
		if(error) return false;
		if((idk is Array)) {
			var contributors:Array<CreditsGitHubContributor> = [];
			for(e in idk) contributors.push({
				login: e.login,
				avatar_url: e.avatar_url,
				html_url: e.html_url,
				id: e.id,
				contributions: e.contributions
			});
			Options.contributors = contributors;
		}
		Logs.verbose('[CreditsCodename] Contributors list Updated!');

		var errorOnMain:Bool = false;
		var idk2 = GitHub.getOrganizationMembers(Flags.REPO_OWNER, function(e) {
			errorOnMain = true;
			var errMsg:String = 'Error while trying to download ${Flags.REPO_OWNER} members list:\n${CoolUtil.removeIP(e.message)}';
			Logs.error(errMsg.replace('\n', ' '));
			funkin.backend.utils.NativeAPI.showMessageBox("Codename Engine Warning", errMsg, MSG_WARNING);
		});
		if(!errorOnMain) {
			Options.mainDevs = [for(m in idk2) m.id];
			Logs.verbose('[CreditsCodename] Main Devs list Updated!');
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
			var text = TU.translate("credits.totalContributions", [c.contributions, totalContributions, FlxMath.roundDecimal(c.contributions / totalContributions * 100, 2)]);
			var opt:GithubIconOption = new GithubIconOption(c, text);
			if(Options.mainDevs.contains(c.id)) {
				opt.desc += TU.translate("credits.mainDev");
				@:privateAccess opt.__text.color = Flags.MAIN_DEVS_COLOR;
			}
			add(opt);
		}

		updateMenuDesc();
	}
}