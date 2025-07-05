package funkin.backend.system.updating;

import openfl.Lib;
import sys.io.Process;
import haxe.zip.Reader;
import funkin.backend.utils.ZipUtil;
import haxe.io.Path;
import openfl.utils.ByteArray;
import sys.io.File;
import sys.io.FileOutput;
import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.net.URLRequest;
import openfl.net.URLLoader;
import sys.FileSystem;
import funkin.backend.system.github.GitHubRelease;

class AsyncUpdater {
	// NON ASYNC STUFF
	#if REGION
	public function new(releases:Array<GitHubRelease>) {
		this.releases = releases;
	}

	public function execute() {
		Main.execAsync(installUpdates);
	}
	#end


	#if windows
	public static var executableGitHubName:String = "update-windows.exe";
	public static var executableName:String = "CodenameEngine.exe";
	#end
	#if linux
	public static var executableGitHubName:String = "update-linux";
	public static var executableName:String = "CodenameEngine";
	#end
	#if mac
	public static var executableGitHubName:String = "update-mac";
	public static var executableName:String = "CodenameEngine";
	#end

	public var releases:Array<GitHubRelease>;
	public var progress:UpdaterProgress = new UpdaterProgress();
	public var path:String;
	public var downloadStream:URLLoader;
	public var executableReplaced:Bool = false;

	public var lastTime:Float = 0;
	public var oldBytesLoaded:Float = 0;

	public function installUpdates() {
		prepareInstallationEnvironment();
		downloadFiles();
	}

	public function installFiles(files:Array<String>) {
		progress.step = INSTALLING;
		progress.files = files.length+1;
		for(k=>e in files) {
			var path = '$path$e';
			progress.curFile = k+1;
			progress.curFileName = e;
			trace('extracting file ${path}');
			var reader = ZipUtil.openZip(path);

			progress.curZipProgress = new ZipProgress();
			ZipUtil.uncompressZip(reader, './', null, progress.curZipProgress);
			// FileSystem.deleteFile(path);
		}
		if (executableReplaced = FileSystem.exists('$path$executableName')) {
			progress.curFile = files.length;
			progress.curFileName = executableName;

			var progPath = Sys.programPath();
			var bakFile = '${Path.withoutExtension(progPath)}.bak';
			if (FileSystem.exists(bakFile))
				FileSystem.deleteFile(bakFile);
			FileSystem.rename(progPath, bakFile);
			FileSystem.rename('$path$executableName', progPath);
		}
	}

	public function downloadFiles() {
		var files:Array<String> = [];
		var fileNames:Array<String> = [];
		var exePath:String = "";
		for(r in releases) {
			for(e in r.assets) {
				if (e.name.toLowerCase() == "update-assets.zip") {
					files.push(e.browser_download_url);
					fileNames.push('${Path.withoutExtension(e.name)}-${r.tag_name}.${Path.extension(e.name)}');
				} else if (e.name.toLowerCase() == executableGitHubName) {
					exePath = e.browser_download_url;
				}
			}
		}
		progress.curFile = -1;
		progress.curFileName = null;
		progress.files = files.length;
		progress.step = DOWNLOADING_ASSETS;
		trace('starting assets download');
		doFile(files.copy(), fileNames.copy(), function() {
			progress.curFile = -1;
			progress.curFileName = null;
			progress.files = 1;
			progress.step = DOWNLOADING_EXECUTABLE;
			trace('starting exe download');
			doFile([exePath], [executableName], function() {
				trace('done, starting installation');
				installFiles(fileNames);
				progress.done = true;
			});
		});
	}

	public function doFile(files:Array<String>, fileNames:Array<String>, onFinish:Void->Void) {
		var f = files.shift();
		if (f == null) {
			onFinish();
			return;
		}
		var fn = fileNames.shift();
		trace('downloading $f ($fn)');
		progress.curFile++;
		progress.curFileName = fn;
		progress.bytesLoaded = 0;
		progress.bytesTotal = 1;
		downloadStream = new URLLoader();
		downloadStream.dataFormat = BINARY;

		downloadStream.addEventListener(ProgressEvent.PROGRESS, function(e) {
			progress.bytesLoaded = e.bytesLoaded;
			progress.bytesTotal = e.bytesTotal;

			var curTime = Lib.getTimer();

			progress.downloadSpeed = (e.bytesLoaded - oldBytesLoaded) / ((curTime - lastTime) / 1000);

			lastTime = curTime;
			oldBytesLoaded = e.bytesLoaded;
		});
		downloadStream.addEventListener(Event.COMPLETE, function(e) {
			var fileOutput:FileOutput = File.write('$path$fn', true);

			var data:ByteArray = new ByteArray();
			downloadStream.data.readBytes(data, 0, downloadStream.data.length - downloadStream.data.position);
			fileOutput.writeBytes(data, 0, data.length);
			fileOutput.flush();

			fileOutput.close();
			doFile(files, fileNames, onFinish);
		});

		oldBytesLoaded = 0;
		lastTime = Lib.getTimer();
		downloadStream.load(new URLRequest(f));
	}

	public function prepareInstallationEnvironment() {
		progress.step = PREPARING;

		#if windows
		path = '${Sys.getEnv("TEMP")}\\Codename Engine\\Updater\\';
		#else
		path = '.temp/';
		#end

		FileSystem.createDirectory(path);
	}
}

class UpdaterProgress {
	public var step:UpdaterStep = PREPARING;
	public var curFile:Int = 0;
	public var files:Int = 0;
	public var bytesLoaded:Float = 0;
	public var bytesTotal:Float = 0;
	public var downloadSpeed:Float = 0;
	public var curFileName:String = "";
	public var done:Bool = false;
	public var curZipProgress:ZipProgress = new ZipProgress();

	public function new() {}
}

enum abstract UpdaterStep(Int) {
	var PREPARING = 0;
	var DOWNLOADING_ASSETS = 1;
	var DOWNLOADING_EXECUTABLE = 2;
	var INSTALLING = 3;
}
