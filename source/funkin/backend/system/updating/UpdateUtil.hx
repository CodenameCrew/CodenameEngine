package funkin.backend.system.updating;

import funkin.backend.system.github.GitHub;
import funkin.backend.system.github.GitHubRelease;
#if ALLOW_MULTITHREADING
import funkin.backend.utils.ThreadUtil;
#end

import lime.app.Application;

import sys.FileSystem;

import haxe.io.Path;

#if (target.threaded)
import sys.thread.Thread;
import sys.thread.Mutex;
#end

using funkin.backend.system.github.GitHub;

class UpdateUtil {
	public static var lastUpdateCheck:Null<UpdateCheckCallback>;

	#if (target.threaded)
	private static var __waitCallbacks:Array<UpdateCheckCallback->Void>;
	private static var __mutex:Mutex;
	#end

	public static function init() {
		// deletes old bak file if it exists
		#if sys
		var bakPath = '${Path.withoutExtension(Sys.programPath())}.bak';
		if (FileSystem.exists(bakPath)) FileSystem.deleteFile(bakPath);
		#end

		#if (target.threaded)
		__waitCallbacks = [];
		__mutex = new Mutex();

		#if ALLOW_MULTITHREADING ThreadUtil.execAsync #else Thread.create #end(checkForUpdates.bind(true, false));
		#end
	}

	public static function waitForUpdates(force = false, callback:UpdateCheckCallback->Void, lazy = false) {
		#if (target.threaded)
		if (__mutex.tryAcquire()) {
			__mutex.release();
			if (__shouldCheck(lazy) || force) {
				__waitCallbacks.push(callback);
				#if ALLOW_MULTITHREADING ThreadUtil.execAsync #else Thread.create #end(checkForUpdates.bind(force, false));
			}
			else
				callback(lastUpdateCheck);
		}
		else
			__waitCallbacks.push(callback);
		#else
		callback(checkForUpdates(true, false));
		#end
	}

	public static function checkForUpdates(force = false, lazy = false):UpdateCheckCallback {
		#if (target.threaded)
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
		#else
		if (!__shouldCheck(lazy)) return lastUpdateCheck;
		return lastUpdateCheck = __checkForUpdates();
		#end
	}

	#if (target.threaded)
	static function __callWaitCallbacks() {
		for (callback in __waitCallbacks) callback(lastUpdateCheck);
		__waitCallbacks.resize(0);
	}
	#end

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