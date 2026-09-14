package funkin.backend.utils;

import funkin.backend.utils.native.HiddenProcess;
#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end
import openfl.system.System;

using StringTools;

/**
 * Tools that are related to memory.
 * Including garbage collection, and memory usage, and hardware info.
 *
 * DISCLAIMER: Hardware info is only available on Native platforms.
**/
final class MemoryUtil {
	public static var disableCount:Int = 0;

	public static function askDisable() {
		disableCount++;
		if (disableCount > 0)
			disable();
		else
			enable();
	}
	public static function askEnable() {
		disableCount--;
		if (disableCount > 0)
			disable();
		else
			enable();
	}

	public static function init() {}

	/**
	 * Does a minor garbage collection.
	 */
	public static function clearMinor() {
		#if (cpp || java || neko)
		Gc.run(false);
		#end
	}

	/**
	 * Does a full garbage collection.
	 */
	public static function clearMajor() {
		#if cpp
		Gc.run(true);
		Gc.compact();
		#elseif hl
		Gc.major();
		#elseif (java || neko)
		Gc.run(true);
		#end
	}

	/**
	 * Enables garbage collection.
	 */
	public static function enable() {
		#if (cpp || hl)
		Gc.enable(true);
		#end
	}

	/**
	 * Disables garbage collection.
	 * Fyi: doesn't fully disable garbage collection, but prevents it from running as much.
	 */
	public static function disable() {
		#if (cpp || hl)
		Gc.enable(false);
		#end
	}

	/**
	 * Gets the total memory of the system.
	 * Output depends on the hardware.
	 */
	public static function getTotalMem():Float
	{
		#if cpp
			#if windows
			return funkin.backend.utils.native.Windows.getTotalRam();
			#elseif mac
			return funkin.backend.utils.native.Mac.getTotalRam();
			#elseif linux
			return funkin.backend.utils.native.Linux.getTotalRam();
			#else
			return 0;
			#end
		#else
			return 0;
		#end
	}

	/**
	 * Gets the current memory usage of the app.
	 * DISCLAIMER: This gets the memory usage that is taken up by Haxe, not the actual memory usage of the app.
	 */
	public static inline function currentMemUsage() {
		#if cpp
		return Gc.memInfo64(Gc.MEM_INFO_USAGE);
		#elseif hl
		return Gc.stats().currentMemory;
		#elseif sys
		return cast(cast(System.totalMemory, UInt), Float);
		#else
		return 0;
		#end
	}


	/**
	 * Gets the memory type of the system.
	 * Output depends on the platform, and hardware.
	 */
	public static function getMemType():String {
		#if windows
		var memoryMap:Map<Int, String> = [
			0 => null,
			1 => "Other",
			2 => "DRAM",
			3 => "Synchronous DRAM",
			4 => "Cache DRAM",
			5 => "EDO",
			6 => "EDRAM",
			7 => "VRAM",
			8 => "SRAM",
			9 => "RAM",
			10 => "ROM",
			11 => "Flash",
			12 => "EEPROM",
			13 => "FEPROM",
			14 => "EPROM",
			15 => "CDRAM",
			16 => "3DRAM",
			17 => "SDRAM",
			18 => "SGRAM",
			19 => "RDRAM",
			20 => "DDR",
			21 => "DDR2",
			22 => "DDR2 FB-DIMM",
			24 => "DDR3",
			25 => "FBD2",
			26 => "DDR4",
			27 => "LPDDR",
			28 => "LPDDR2",
			29 => "LPDDR3",
			30 => "LPDDR4",
			31 => "Logical Non-volatile device",
			32 => "HBM",
			33 => "HBM2",
			34 => "DDR5",
			35 => "LPDDR5",
			36 => "HBM3",
		];
		var memoryOutput:Int = -1;

		var process = new HiddenProcess("powershell", ["-Command", "Get-CimInstance Win32_PhysicalMemory | Select-Object -ExpandProperty SMBIOSMemoryType" ]);
		if (process.exitCode() == 0) memoryOutput = Std.int(Std.parseFloat(process.stdout.readAll().toString().trim().split("\n")[1]));
		if (memoryOutput != -1) return memoryMap[memoryOutput] == null ? 'Unknown ($memoryOutput)' : memoryMap[memoryOutput];
		#elseif mac
		var process = new HiddenProcess("system_profiler", ["SPMemoryDataType"]);
		var reg = ~/Type: (.+)/;
		reg.match(process.stdout.readAll().toString());
		if (process.exitCode() == 0) return reg.matched(1);
		#elseif linux
		/*var process = new HiddenProcess("sudo", ["dmidecode", "--type", "17"]);
		if (process.exitCode() != 0) return "Unknown";
		var lines = process.stdout.readAll().toString().split("\n");
		for (line in lines) {
			if (line.startsWith("Type:")) {
				return line.substring("Type:".length).trim();
			}
		}*/
		// TODO: sort of unsafe? also requires users to use `sudo`
		// when launching the engine through the CLI, REIMPLEMENT LATER. 
		#end
		return "Unknown";
	}
}