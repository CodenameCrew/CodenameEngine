package funkin.backend.system.framerate;

import funkin.backend.system.Logs;
import funkin.backend.utils.MemoryUtil;
import funkin.backend.utils.native.HiddenProcess;
#if cpp
import cpp.Float64;
import cpp.UInt64;
#end

using StringTools;

class SystemInfo extends FramerateCategory {
	public static var osInfo:String = "Unknown";
	public static var gpuName:String = "Unknown";
	public static var vRAM:String = "Unknown";
	public static var cpuName:String = "Unknown";
	public static var totalMem:String = "Unknown";
	public static var memType:String = "Unknown";
	public static var gpuMaxSize:String = "Unknown";

	static var __formattedSysText:String = "";

	public static function init() {
		#if linux
		var process = new HiddenProcess("cat", ["/etc/os-release"]);
		if (process.exitCode() != 0) Logs.error('Unable to grab OS Label');
		else {
			var osName = "";
			var osVersion = "";
			for (line in process.stdout.readAll().toString().split("\n")) {
				if (line.startsWith("PRETTY_NAME=")) {
					var index = line.indexOf('"');
					if (index != -1)
						osName = line.substring(index + 1, line.lastIndexOf('"'));
					else {
						var arr = line.split("=");
						arr.shift();
						osName = arr.join("=");
					}
				}
				if (line.startsWith("VERSION=")) {
					var index = line.indexOf('"');
					if (index != -1)
						osVersion = line.substring(index + 1, line.lastIndexOf('"'));
					else {
						var arr = line.split("=");
						arr.shift();
						osVersion = arr.join("=");
					}
				}
			}
			if (osName != "")
				osInfo = '${osName} ${osVersion}'.trim();
		}
		#elseif windows
		var windowsCurrentVersionPath = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion";
		var buildNumber = Std.parseInt(RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, "CurrentBuildNumber"));
		var edition = RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, "ProductName");

		var lcuKey = "WinREVersion"; // Last Cumulative Update Key On Older Windows Versions
		if (buildNumber >= 22000) { // Windows 11 Initial Release Build Number
			edition = edition.replace("Windows 10", "Windows 11");
			lcuKey = "LCUVer"; // Last Cumulative Update Key On Windows 11
		}

		var lcuVersion = RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, lcuKey);

		osInfo = edition;

		if (lcuVersion != null && lcuVersion != "")
			osInfo += ' ${lcuVersion}';
		else if (lime.system.System.platformVersion != null && lime.system.System.platformVersion != "")
			osInfo += ' ${lime.system.System.platformVersion}';
		#else
		if (lime.system.System.platformLabel != null && lime.system.System.platformLabel != "" && lime.system.System.platformVersion != null && lime.system.System.platformVersion != "")
			osInfo = '${lime.system.System.platformLabel.replace(lime.system.System.platformVersion, "").trim()} ${lime.system.System.platformVersion}';
		else
			Logs.error('Unable to grab OS Label');
		#end

		try {
			#if windows
			cpuName = RegistryUtil.get(HKEY_LOCAL_MACHINE, "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", "ProcessorNameString");
			#elseif mac
			var process = new HiddenProcess("sysctl -a | grep brand_string"); // Somehow this isn't able to use the args but it still works
			if (process.exitCode() != 0) throw 'Could not fetch CPU information';

			cpuName = process.stdout.readAll().toString().trim().split(":")[1].trim();
			#elseif linux
			var process = new HiddenProcess("cat", ["/proc/cpuinfo"]);
			if (process.exitCode() != 0) throw 'Could not fetch CPU information';

			for (line in process.stdout.readAll().toString().split("\n")) {
				if (line.indexOf("model name") == 0) {
					cpuName = line.substring(line.indexOf(":") + 2);
					break;
				}
			}
			#end
		} catch (e) {
			Logs.error('Unable to grab CPU Name: $e');
		}

		@:privateAccess if(FlxG.renderTile) { // Blit doesn't enable the gpu. Idk if we should fix this
			if (flixel.FlxG.stage.context3D != null && flixel.FlxG.stage.context3D.gl != null) {
				gpuName = Std.string(flixel.FlxG.stage.context3D.gl.getParameter(flixel.FlxG.stage.context3D.gl.RENDERER)).split("/")[0].trim();
				#if !flash
				var size = FlxG.bitmap.maxTextureSize;
				gpuMaxSize = size+"x"+size;
				#end

				if(openfl.display3D.Context3D.__glMemoryTotalAvailable != -1) {
					var vRAMBytes:Int = cast flixel.FlxG.stage.context3D.gl.getParameter(openfl.display3D.Context3D.__glMemoryTotalAvailable);
					if (vRAMBytes == 1000 || vRAMBytes == 1 || vRAMBytes <= 0)
						Logs.trace('Unable to grab GPU VRAM', ERROR, RED);
					else {
						vRAM = getSizeString(vRAMBytes / 1024);
					}
				}
			} else
				Logs.error('Unable to grab GPU Info');
		}

		#if cpp
		totalMem = Std.string(MemoryUtil.getTotalMem() / 1024) + " GB";
		#else
		Logs.error('Unable to grab RAM Amount');
		#end

		try {
			memType = MemoryUtil.getMemType();
		} catch (e) {
			Logs.error('Unable to grab RAM Type: $e');
		}
		formatSysInfo();
	}

	static function formatSysInfo() {
		__formattedSysText = "";
		if (osInfo != "Unknown") __formattedSysText += 'System: $osInfo';
		if (cpuName != "Unknown") __formattedSysText += '\nCPU: $cpuName ${openfl.system.Capabilities.cpuArchitecture} ${(openfl.system.Capabilities.supports64BitProcesses ? '64-Bit' : '32-Bit')}';
		if (gpuName != cpuName || vRAM != "Unknown") {
			var gpuNameKnown = gpuName != "Unknown" && gpuName != cpuName;
			var vramKnown = vRAM != "Unknown";

			if(gpuNameKnown || vramKnown) __formattedSysText += "\n";

			if(gpuNameKnown) __formattedSysText += 'GPU: $gpuName';
			if(gpuNameKnown && vramKnown) __formattedSysText += " | ";
			if(vramKnown) __formattedSysText += 'VRAM: $vRAM'; // 1000 bytes of vram (apus)
		}
		//if (gpuMaxSize != "Unknown") __formattedSysText += '\nMax Bitmap Size: $gpuMaxSize';
		if (totalMem != "Unknown" && memType != "Unknown") __formattedSysText += '\nTotal MEM: $totalMem $memType';
	}

	static var sizeLabels:Array<String> = [" MB", " GB", " TB"];
	static function getSizeString(size:Float):String
	{
		var rSize:Float = size;
		var label:Int = 0;
		var len = sizeLabels.length;
		while (rSize >= 1024 && label < len - 1)
		{
			label++;
			rSize /= 1024;
		}
		return Std.int(rSize) + ((label <= 1) ? "" : "." + CoolUtil.addZeros(Std.string(Std.int((rSize % 1) * 100)), 2)) + sizeLabels[label];
	}

	public function new() {
		super("System Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		_text = __formattedSysText;
		_text += '${__formattedSysText == "" ? "" : "\n"}Garbage Collector: ${MemoryUtil.disableCount > 0 ? "OFF" : "ON"} (${MemoryUtil.disableCount})';

		this.text.text = _text;
		super.__enterFrame(t);
	}
}