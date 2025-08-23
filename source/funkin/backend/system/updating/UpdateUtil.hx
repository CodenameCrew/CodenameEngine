package funkin.backend.system.updating;

import funkin.backend.system.github.GitHub;
import funkin.backend.system.github.GitHubRelease;

import lime.app.Application;

import sys.thread.Mutex;
import sys.thread.Thread;
import sys.FileSystem;

import haxe.io.Path;

using funkin.backend.system.github.GitHub;

class UpdateUtil {
	public static var lastUpdateCheck:Null<UpdateCheckCallback>;

	private static var __waitCallbacks:Array<UpdateCheckCallback->Void>;
	private static var __mutex:Mutex;

	public static function init() {
		// deletes old bak file if it exists
		#if sys
		var bakPath = '${Path.withoutExtension(Sys.programPath())}.bak';
		if (FileSystem.exists(bakPath)) FileSystem.deleteFile(bakPath);
		#end

		__waitCallbacks = [];
		__mutex = new Mutex();
		Thread.create(checkForUpdates.bind(true, false));
	}
	
	public static function getExecName():String
	{
		// Since previously, both linux and mac don't have the .exe extension. We might as well just compress this to a '#else' clause.
		return #if windows "CodenameEngine.exe" #else "CodenameEngine" #end; // weird syntax??? :skull: haxe is just full of surprises
	}

	public static function getGitExecName():String
	{
		// Only add the suffix of the platform we need to get.
		var target:String = #if windows "windows.exe" #end
		#if mac "mac" #end
		#if linux "linux" #end;
		return 'update-${target}';
	}

	public static function waitForUpdates(force = false, callback:UpdateCheckCallback->Void, lazy = false) {
		if (__mutex.tryAcquire()) {
			__mutex.release();
			if (__shouldCheck(lazy) || force) {
				__waitCallbacks.push(callback);
				Thread.create(checkForUpdates.bind(force, false));
			}
			else
				callback(lastUpdateCheck);
		}
		else
			__waitCallbacks.push(callback);
	}

	public static function checkForUpdates(force = false, lazy = false):UpdateCheckCallback {
		var wasAcquired = !__mutex.tryAcquire();
		if (wasAcquired) __mutex.acquire();

		if ((!force || wasAcquired) && !__shouldCheck(lazy)) {
			__mutex.release();
			return lastUpdateCheck;
		}

		lastUpdateCheck = __checkForUpdates();
		__mutex.release();

		FlxG.signals.preUpdate.addOnce(__callWaitCallbacks);

		return lastUpdateCheck;
	}

	static function __checkForUpdates():UpdateCheckCallback {
		var curTag = 'v' + (Flags.VERSION == null ? Application.current.meta.get('version') : Flags.VERSION), error = false;
		var newUpdates = __doReleaseFiltering(GitHub.getReleases(Flags.REPO_OWNER, Flags.REPO_NAME, (e) -> {
			error = true;
		}), curTag);

		var updateCheck:UpdateCheckCallback = {
			success: !error,
			newUpdate: !error && newUpdates.length > 0,
			currentVersionTag: curTag,
			date: Date.now()
		}

		if (updateCheck.newUpdate) updateCheck.newVersionTag = (updateCheck.updates = newUpdates).last().tag_name;
		return updateCheck;
	}

	static function __shouldCheck(lazy:Bool):Bool
		return lastUpdateCheck == null || !lazy && (!lastUpdateCheck.newUpdate || Date.now().getTime() - lastUpdateCheck.date.getTime() > 1800000);

	static function __callWaitCallbacks() {
		for (callback in __waitCallbacks) callback(lastUpdateCheck);
		__waitCallbacks.resize(0);
	}

	static function __doReleaseFiltering(releases:Array<GitHubRelease>, currentVersionTag:String) {
		releases = releases.filterReleases(Options.betaUpdates, false);
		if (releases.length <= 0)
			return releases;

		var newArray:Array<GitHubRelease> = [], __curVersionPos = -2;

		var skipNextBinaryChecks:Bool = false;
		for(index in 0...releases.length) {
			var i = index;

			var release = releases[i];
			var containsBinary = skipNextBinaryChecks;
			if (!containsBinary) {
				for(asset in release.assets) {
					if (asset.name.toLowerCase() == AsyncUpdater.executableGitHubName.toLowerCase()) {
						containsBinary = true;
						break;
					}
				}
			}
			if (containsBinary) {
				skipNextBinaryChecks = true; // no need to check for older versions
				if (release.tag_name == currentVersionTag) __curVersionPos = -1;
				newArray.insert(0, release);
				if (__curVersionPos > -2) __curVersionPos++;
			}
		}
		if (__curVersionPos < -1)
			__curVersionPos = -1;

		return newArray.length <= 0 ? newArray : newArray.splice(__curVersionPos+1, newArray.length-(__curVersionPos+1));
	}
}

typedef UpdateCheckCallback = {
	var success:Bool;

	var newUpdate:Bool;

	@:optional var currentVersionTag:String;

	@:optional var newVersionTag:String;

	@:optional var updates:Array<GitHubRelease>;

	@:optional var date:Date;
}