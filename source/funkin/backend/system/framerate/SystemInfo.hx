package funkin.backend.system.framerate;

import funkin.backend.utils.native.HiddenProcess;
import funkin.backend.utils.MemoryUtil;
import funkin.backend.system.Logs;

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

	public static inline function init() {
		#if linux
		var process = new HiddenProcess("cat", ["/etc/os-release"]);
		if (process.exitCode() != 0) Logs.trace('Unable to grab OS Label', ERROR, RED);
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
		var lcuVersion = RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, "LCUVer"); // Last Cumulative Update Version Aka Build Number But Fancy

		if (buildNumber >= 22000) // Windows 11 Initial Release Build Number
			edition = edition.replace("Windows 10", "Windows 11");

		osInfo = edition;

		if (lcuVersion != null && lcuVersion != "")
			osInfo += ' ${lcuVersion}';
		else if (lime.system.System.platformVersion != null && lime.system.System.platformVersion != "")
			osInfo += ' ${lime.system.System.platformVersion}';
		#else
		if (lime.system.System.platformLabel != null && lime.system.System.platformLabel != "" && lime.system.System.platformVersion != null && lime.system.System.platformVersion != "")
			osInfo = '${lime.system.System.platformLabel.replace(lime.system.System.platformVersion, "").trim()} ${lime.system.System.platformVersion}';
		else
			Logs.trace('Unable to grab OS Label', ERROR, RED);
		#end

		try {
			#if windows
			cpuName = RegistryUtil.get(HKEY_LOCAL_MACHINE, "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", "ProcessorNameString");
			#elseif mac
			var process = new HiddenProcess("sysctl -a | grep brand_string"); // Somehow this isnt able to use the args but it still works
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
			Logs.trace('Unable to grab CPU Name: $e', ERROR, RED);
		}

		@:privateAccess {
			if (flixel.FlxG.stage.context3D != null && flixel.FlxG.stage.context3D.gl != null) {
				gpuName = Std.string(flixel.FlxG.stage.context3D.gl.getParameter(flixel.FlxG.stage.context3D.gl.RENDERER)).split("/")[0].trim();
				#if !flash
				var size = FlxG.bitmap.maxTextureSize;
				gpuMaxSize = size+"x"+size;
				#end

				if(openfl.display3D.Context3D.__glMemoryTotalAvailable != -1) {
					var vRAMBytes:UInt = cast(flixel.FlxG.stage.context3D.gl.getParameter(openfl.display3D.Context3D.__glMemoryTotalAvailable), UInt);
					if (vRAMBytes == 1000 || vRAMBytes == 1 || vRAMBytes <= 0)
						Logs.trace('Unable to grab GPU VRAM', ERROR, RED);
					else
						vRAM = CoolUtil.getSizeString(vRAMBytes * 1000);
				}
			} else
				Logs.trace('Unable to grab GPU Info', ERROR, RED);
		}

		#if cpp
		totalMem = Std.string(MemoryUtil.getTotalMem() / 1024) + " GB";
		#else
		Logs.trace('Unable to grab RAM Amount', ERROR, RED);
		#end

		try {
			memType = MemoryUtil.getMemType();
		} catch (e) {
			Logs.trace('Unable to grab RAM Type: $e', ERROR, RED);
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